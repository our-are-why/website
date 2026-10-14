#!/bin/sh

# Usage: makeImages.sh
#   Makes the site's icons and link-preview image:
#     public/favicon.ico                  the sloth's head at 16, 32 and 48 px,
#                                         on a transparent background
#     public/apple-touch-icon.png         the same at 180 px on white, for iOS
#                                         home screens and bookmarks
#     public/assets/ourarewhy.social.png  the whole picture at 1200x630,
#                                         shown when a link to the site is
#                                         shared

set -eu

# Run from the project root, wherever this script is called from
cd "$(dirname "$0")/.."

# The sloth's head, cut out of the original along the outline of its fur and
# cut off from the body at the neck: 252 px square, the art's own resolution.
# Touch it up in any image editor.
head=private/ourarewhy.head.png

# Shrinking blends each icon pixel from several head pixels. Premultiplying
# the alpha first means transparent pixels add nothing, whatever colour an
# editor left under them, so the edge gets no halo. Area averaging turns the
# dither grey as it shrinks, which reads better at icon sizes than hard black
# and white pixels.
ffmpeg -v error -y -i "$head" -filter_complex "
  [0:v]format=gbrap,premultiply=inplace=1,split=3[a][b][c];
  [a]scale=16:16:flags=area,unpremultiply=inplace=1,format=rgba[s16];
  [b]scale=32:32:flags=area,unpremultiply=inplace=1,format=rgba[s32];
  [c]scale=48:48:flags=area,unpremultiply=inplace=1,format=rgba[s48]" \
  -map "[s16]" -map "[s32]" -map "[s48]" -c:v png public/favicon.ico

# iOS fills transparent icon pixels with black, so put the head on white
ffmpeg -v error -y -i "$head" -filter_complex "
  color=white:s=252x252[bg];[bg][0:v]overlay=format=auto,
  scale=180:180:flags=area,format=rgb24" -frames:v 1 public/apple-touch-icon.png

# Link previews are 1.91:1. The art spans x 218-2580, y 177-1533 of the
# original and runs off its bottom edge, so pad with white, then crop a 1.91:1
# frame centred on the art with even margins, then shrink. PNG, because JPEG
# smears the dither.
ffmpeg -v error -y -i private/ourarewhy.original.jpg -vf "pad=iw+400:ih+400:200:200:white,crop=2938:1542:130:284,scale=1200:630:flags=area,format=gray" \
  public/assets/ourarewhy.social.png

ls -l public/favicon.ico public/apple-touch-icon.png \
  public/assets/ourarewhy.social.png
