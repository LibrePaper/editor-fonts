# editor-fonts

Subsets of the monospace fonts that the LibrePaper editor offers. The build
scripts are MIT licensed. Each font is under its own SIL Open Font License 1.1,
and the licence texts ship in the release.

Fonts: JetBrains Mono, Fira Code, Source Code Pro, IBM Plex Mono, Cascadia
Code and OpenDyslexic Mono. Upstream archives are pinned by sha256 in
`sources.lock`.

## Build

Run the build in a Nix shell that provides the tools:

```sh
# Downloads, checks and subsets every font into dist/.
nix-shell -p python3Packages.fonttools python3Packages.brotli python3Packages.fontmake unzip curl --run make
```

## Release

Tag the release and upload the eleven WOFF2 files, `SHA256SUMS` and the licences:

```sh
# Needs the gh CLI, logged in with write access to LibrePaper/editor-fonts.
make release TAG=vX.Y.Z
```

Then pin the new release in LibrePaper's `assets.lock`:

```sh
# Run from the librepaper repository.
node tools/assets/pins.mjs update release --repo editor-fonts --tag vX.Y.Z
```
