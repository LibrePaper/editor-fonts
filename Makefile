# Builds the editor font set: upstream's own WOFF2 files, renamed and checked.
#
#   nix-shell -p curl unzip --run make
#
# Every upstream file is pinned by sha256 in sources.lock. The fonts are copied
# without modification, so each keeps its upstream licence. `make clean` removes
# build/ and dist/.

CURL ?= curl -fL

LOCK := sources.lock
DOWNLOADS := build/downloads
DIST := dist
LICENSES := $(DIST)/licenses

FONTS := jetbrains-mono jetbrains-mono-italic jetbrains-mono-semibold \
	fira-code \
	source-code-pro source-code-pro-italic \
	ibm-plex-mono ibm-plex-mono-italic ibm-plex-mono-semibold \
	cascadia-code cascadia-code-italic \
	opendyslexic opendyslexic-italic opendyslexic-bold
WOFF2 := $(addsuffix .woff2,$(FONTS))

FAMILIES := jetbrains-mono fira-code source-code-pro ibm-plex-mono cascadia-code opendyslexic
LICENCES := $(addsuffix -OFL.txt,$(FAMILIES))

# lock_field NAME COLUMN prints one column of the sources.lock row called NAME.
lock_field = $(shell awk -v n='$(1)' '$$1 == n { print $$$(2) }' $(LOCK))

.PHONY: all release clean

# Downloads and extractions are kept, so a rebuild does not fetch them again.
.SECONDARY:

all: $(addprefix $(DIST)/,$(WOFF2)) $(DIST)/SHA256SUMS $(addprefix $(LICENSES)/,$(LICENCES))

# Download a source, refuse it unless its sha256 matches sources.lock.
$(DOWNLOADS)/%:
	mkdir -p $(@D)
	$(CURL) -o $@.part '$(call lock_field,$*,2)'
	got=$$(sha256sum $@.part | cut -d' ' -f1); \
	want='$(call lock_field,$*,3)'; \
	if [ "$$got" != "$$want" ]; then rm -f $@.part; echo "$*: sha256 $$got does not match sources.lock" >&2; exit 1; fi
	mv $@.part $@

# Extract the MEMBERS of a zip source flat into build/.
build/%.extracted: $(DOWNLOADS)/%
	mkdir -p build
	unzip -j -o $< $(MEMBERS) -d build
	touch $@

build/jetbrains-mono.extracted: MEMBERS := fonts/webfonts/JetBrainsMono-Regular.woff2 fonts/webfonts/JetBrainsMono-Italic.woff2 fonts/webfonts/JetBrainsMono-SemiBold.woff2 OFL.txt
build/fira-code.extracted: MEMBERS := woff2/FiraCode-VF.woff2
build/source-code-pro.extracted: MEMBERS := WOFF2/VF/SourceCodeVF-Upright.ttf.woff2 WOFF2/VF/SourceCodeVF-Italic.ttf.woff2
build/ibm-plex-mono.extracted: MEMBERS := ibm-plex-mono/fonts/complete/woff2/IBMPlexMono-Regular.woff2 ibm-plex-mono/fonts/complete/woff2/IBMPlexMono-Italic.woff2 ibm-plex-mono/fonts/complete/woff2/IBMPlexMono-SemiBold.woff2 ibm-plex-mono/LICENSE.txt
build/cascadia-code.extracted: MEMBERS := woff2/CascadiaCode.woff2 woff2/CascadiaCodeItalic.woff2

# Each font is copied from the file that upstream ships it in.
$(DIST)/jetbrains-mono.woff2: SRC := build/JetBrainsMono-Regular.woff2
$(DIST)/jetbrains-mono.woff2: build/jetbrains-mono.extracted
$(DIST)/jetbrains-mono-italic.woff2: SRC := build/JetBrainsMono-Italic.woff2
$(DIST)/jetbrains-mono-italic.woff2: build/jetbrains-mono.extracted
$(DIST)/jetbrains-mono-semibold.woff2: SRC := build/JetBrainsMono-SemiBold.woff2
$(DIST)/jetbrains-mono-semibold.woff2: build/jetbrains-mono.extracted
$(DIST)/fira-code.woff2: SRC := build/FiraCode-VF.woff2
$(DIST)/fira-code.woff2: build/fira-code.extracted
$(DIST)/source-code-pro.woff2: SRC := build/SourceCodeVF-Upright.ttf.woff2
$(DIST)/source-code-pro.woff2: build/source-code-pro.extracted
$(DIST)/source-code-pro-italic.woff2: SRC := build/SourceCodeVF-Italic.ttf.woff2
$(DIST)/source-code-pro-italic.woff2: build/source-code-pro.extracted
$(DIST)/ibm-plex-mono.woff2: SRC := build/IBMPlexMono-Regular.woff2
$(DIST)/ibm-plex-mono.woff2: build/ibm-plex-mono.extracted
$(DIST)/ibm-plex-mono-italic.woff2: SRC := build/IBMPlexMono-Italic.woff2
$(DIST)/ibm-plex-mono-italic.woff2: build/ibm-plex-mono.extracted
$(DIST)/ibm-plex-mono-semibold.woff2: SRC := build/IBMPlexMono-SemiBold.woff2
$(DIST)/ibm-plex-mono-semibold.woff2: build/ibm-plex-mono.extracted
$(DIST)/cascadia-code.woff2: SRC := build/CascadiaCode.woff2
$(DIST)/cascadia-code.woff2: build/cascadia-code.extracted
$(DIST)/cascadia-code-italic.woff2: SRC := build/CascadiaCodeItalic.woff2
$(DIST)/cascadia-code-italic.woff2: build/cascadia-code.extracted
$(DIST)/opendyslexic.woff2: SRC := $(DOWNLOADS)/opendyslexic-woff2
$(DIST)/opendyslexic.woff2: $(DOWNLOADS)/opendyslexic-woff2
$(DIST)/opendyslexic-italic.woff2: SRC := $(DOWNLOADS)/opendyslexic-italic-woff2
$(DIST)/opendyslexic-italic.woff2: $(DOWNLOADS)/opendyslexic-italic-woff2
$(DIST)/opendyslexic-bold.woff2: SRC := $(DOWNLOADS)/opendyslexic-bold-woff2
$(DIST)/opendyslexic-bold.woff2: $(DOWNLOADS)/opendyslexic-bold-woff2

$(DIST)/%.woff2:
	mkdir -p $(@D)
	cp '$(SRC)' $@

# Each family's licence, copied from the source that ships it.
$(LICENSES)/jetbrains-mono-OFL.txt: LICENCE_SRC := build/OFL.txt
$(LICENSES)/jetbrains-mono-OFL.txt: build/jetbrains-mono.extracted
$(LICENSES)/fira-code-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/fira-code-ofl
$(LICENSES)/fira-code-OFL.txt: $(DOWNLOADS)/fira-code-ofl
$(LICENSES)/source-code-pro-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/source-code-pro-ofl
$(LICENSES)/source-code-pro-OFL.txt: $(DOWNLOADS)/source-code-pro-ofl
$(LICENSES)/ibm-plex-mono-OFL.txt: LICENCE_SRC := build/LICENSE.txt
$(LICENSES)/ibm-plex-mono-OFL.txt: build/ibm-plex-mono.extracted
$(LICENSES)/cascadia-code-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/cascadia-code-ofl
$(LICENSES)/cascadia-code-OFL.txt: $(DOWNLOADS)/cascadia-code-ofl
$(LICENSES)/opendyslexic-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/opendyslexic-ofl
$(LICENSES)/opendyslexic-OFL.txt: $(DOWNLOADS)/opendyslexic-ofl

$(LICENSES)/%-OFL.txt:
	mkdir -p $(@D)
	cp '$(LICENCE_SRC)' $@

$(DIST)/SHA256SUMS: $(addprefix $(DIST)/,$(WOFF2))
	cd $(DIST) && sha256sum $(WOFF2) | LC_ALL=C sort -k2 > SHA256SUMS

# Usage: make release TAG=vX.Y.Z
release: all
	@test -n "$(TAG)" || { echo "usage: make release TAG=vX.Y.Z" >&2; exit 1; }
	gh release create $(TAG) --repo LibrePaper/editor-fonts --title $(TAG) \
		--notes "Upstream's unmodified WOFF2 files, each under its font's SIL Open Font License 1.1. See sources.lock for the upstream releases." \
		$(DIST)/*.woff2 $(DIST)/SHA256SUMS $(DIST)/licenses/*

clean:
	rm -rf build $(DIST)
