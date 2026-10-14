#!/bin/sh

# Usage: encodeVideo.sh
#   Turns private/ourarewhy.original.mp4 into the silent, seamlessly
#   looping videos the landing page serves from public/assets/:
#     ourarewhy.av1.mp4         AV1, picked by browsers that can decode it
#     ourarewhy.h264.mp4        H.264, the fallback every browser can play
#     ourarewhy.still.h264.mp4  the loop's first frame, held still, for
#                               visitors who ask for reduced motion
#
# Needs ffmpeg built with libsvtav1 and libx264; the dev container image
# installs Debian's package, which has both.

set -eu

# Run from the project root, wherever this script is called from
cd "$(dirname "$0")/.."

src=private/ourarewhy.original.mp4
out=public/assets/ourarewhy

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The source is 24 fps footage on a 60 fps timeline, so renumber its frames at
# 24 fps. Frame 0 is a still that doesn't match the frames after it, so drop
# it. The art is black and white and the color planes are only noise, so set
# them to neutral (luma is left untouched). Audio and metadata go too.
ffmpeg -v error -y -i "$src" -an -sn -dn -map_metadata -1 \
  -vf "setpts=N/24/TB,trim=start_frame=1:end_frame=97,setpts=PTS-STARTPTS,lutyuv=u=128:v=128" \
  -fps_mode passthrough -enc_time_base 1/24 -c:v ffv1 "$tmp/clean.mkv"

# The last frame doesn't match the first, so a plain loop visibly jumps.
# Dissolve the last half second into the first half second instead: 96 frames
# become an 84-frame (3.5 s) loop. xfade needs fps=24 to know the frame rate.
ffmpeg -v error -y -i "$tmp/clean.mkv" -filter_complex "
  [0:v]split[a][b];
  [a]trim=start_frame=12,setpts=PTS-STARTPTS,fps=24[tail];
  [b]trim=end_frame=12,setpts=PTS-STARTPTS,fps=24[head];
  [tail][head]xfade=transition=fade:duration=0.5:offset=3.0,format=yuv420p" \
  -c:v ffv1 "$tmp/loop.mkv"

# Both encodes: one keyframe for the whole loop, tagged BT.709 limited range
# so browsers render the background as exactly #fff, and the index up front
# (faststart) so playback can start before the file finishes downloading.
tags="setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv"

ffmpeg -v error -y -i "$tmp/loop.mkv" -vf "$tags" -c:v libsvtav1 -preset 2 \
  -crf 44 -svtav1-params tune=0 -g 84 -pix_fmt yuv420p -movflags +faststart \
  "$out.av1.mp4"

# Level 4.0 keeps the reference frame count low enough for older decoders
ffmpeg -v error -y -i "$tmp/loop.mkv" -vf "$tags" -c:v libx264 \
  -preset veryslow -crf 22 -profile:v high -level:v 4.0 -g 84 \
  -pix_fmt yuv420p -movflags +faststart "$out.h264.mp4"

# The still: the loop's first frame, shown for a whole minute, so a browser
# looping it isn't seeking back to the start 24 times a second. Only visitors
# who ask for reduced motion download it, so H.264 alone is enough.
ffmpeg -v error -y -i "$tmp/loop.mkv" -frames:v 1 -vf "$tags" -r 1/60 \
  -c:v libx264 -preset veryslow -crf 22 -profile:v high -level:v 4.0 \
  -pix_fmt yuv420p -movflags +faststart "$out.still.h264.mp4"

ls -l "$out.av1.mp4" "$out.h264.mp4" "$out.still.h264.mp4"
