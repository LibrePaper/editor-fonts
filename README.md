# editor-fonts

The fonts that the LibrePaper editor offers, as upstream's own WOFF2 files.
Each file is unmodified, only renamed, and stays under its font's SIL Open
Font License 1.1. The licence texts ship in the release, and the build
scripts are MIT licensed.

Fonts: JetBrains Mono, Fira Code, Source Code Pro, IBM Plex Mono, Cascadia
Code and OpenDyslexic. Upstream archives and files are pinned by sha256 in
`sources.lock`.

## Build

Run the build in a Nix shell that provides curl and unzip:

```sh
# Downloads, checks and copies the fourteen fonts into dist/.
nix-shell -p curl unzip --run make
```

## Release

Tag the release and upload the fourteen WOFF2 files, `SHA256SUMS` and the licences:

```sh
# Needs the gh CLI, logged in with write access to LibrePaper/editor-fonts.
make release TAG=vX.Y.Z
```

Then pin the new release in LibrePaper's `assets.lock`:

```sh
# Run from the librepaper repository.
node tools/assets/pins.mjs update release --repo editor-fonts --tag vX.Y.Z
```
