# website

The source of [ourarewhy.dev](https://ourarewhy.dev): a personal site made
of plain HTML and CSS, with no JavaScript and no build step.

## What's where

- `public/`: the site itself. Everything in it is published as it is.
- `private/`: the full-size originals that the site's images and video are
  made from. Not published.
- `scripts/`: helpers for previewing the site and remaking its media. Each
  one explains itself at the top.
- `.environment/`: the development container.

## Preview locally

On the host, build and start the development container (it needs the shared
base image; see `../.apple-container/README.md`):

    ./.environment/scripts/buildContainer.sh
    ./.environment/scripts/startContainer.sh

Open code-server at http://localhost:8081 and, in its terminal, run:

    ~/project/scripts/startServer.sh

The site is then at http://localhost:3000. Edit files in `public/` and
reload.

## Publish

Cloudflare Pages publishes `public/` whenever the `production` branch is
pushed to GitHub:

    git push github production

## Two things to remember

**The stylesheet is named after its contents** (`css/style.<hash>.css`), so
browsers can cache it for a long time and still pick up changes. After
editing it, rename it to match its new contents:

    cd public
    mv css/style.*.css "css/style.$(sha256sum css/style.*.css | cut -c1-8).css"

then point the `<link rel="stylesheet">` in every page at the new name.

**`public/_headers` decides what pages may load.** Only the site's own
files are allowed, and no scripts at all. Anything new that needs a script
or something from another site has to be allowed there first.
