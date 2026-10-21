# Subsets the editor fonts into WOFF2 files, with licences and checksums.
#
#   nix-shell -p python3Packages.fonttools python3Packages.brotli python3Packages.fontmake unzip curl --run make
#
# Every upstream file is pinned by sha256 in sources.lock. `make clean` removes
# build/ and dist/.

PYFTSUBSET ?= pyftsubset
FONTMAKE ?= fontmake
CURL ?= curl -fL

LOCK := sources.lock
DOWNLOADS := build/downloads
EXTRACT := build/extract
OPENDYSLEXIC := build/opendyslexic
DIST := dist
LICENSES := $(DIST)/licenses

FONTS := jetbrains-mono jetbrains-mono-italic fira-code \
	source-code-pro source-code-pro-italic \
	ibm-plex-mono ibm-plex-mono-italic ibm-plex-mono-semibold \
	cascadia-code cascadia-code-italic opendyslexic-mono
WOFF2 := $(addsuffix .woff2,$(FONTS))

FAMILIES := jetbrains-mono fira-code source-code-pro ibm-plex-mono cascadia-code opendyslexic-mono
LICENCES := $(addsuffix -OFL.txt,$(FAMILIES))

# Basic Latin, Latin-1, Latin Extended-A and -B, general punctuation,
# currency symbols, arrows and box drawing.
UNICODES := U+0020-007E,U+00A0-00FF,U+0100-017F,U+0180-024F,U+2000-206F,U+20A0-20CF,U+2190-21FF,U+2500-257F

# lock_field NAME COLUMN prints one column of the sources.lock row called NAME.
lock_field = $(shell awk -v n='$(1)' '$$1 == n { print $$$(2) }' $(LOCK))

.PHONY: all release clean

all: $(addprefix $(DIST)/,$(WOFF2)) $(DIST)/SHA256SUMS $(addprefix $(LICENSES)/,$(LICENCES))

# Download a source, refuse it unless its sha256 matches sources.lock.
$(DOWNLOADS)/%:
	mkdir -p $(@D)
	$(CURL) -o $@.part '$(call lock_field,$*,2)'
	got=$$(sha256sum $@.part | cut -d' ' -f1); \
	want='$(call lock_field,$*,3)'; \
	if [ "$$got" != "$$want" ]; then rm -f $@.part; echo "$*: sha256 $$got does not match sources.lock" >&2; exit 1; fi
	mv $@.part $@

# Extract a zip source into its own directory.
$(EXTRACT)/%.done: $(DOWNLOADS)/%
	rm -rf $(EXTRACT)/$*
	mkdir -p $(EXTRACT)/$*
	unzip -q $< -d $(EXTRACT)/$*
	touch $@

# OpenDyslexic Mono has no compiled release upstream, so it is built from the Glyphs source.
$(OPENDYSLEXIC)/OpenDyslexicMono-Regular.otf: $(DOWNLOADS)/opendyslexic-mono-glyphs
	mkdir -p $(@D)
	$(FONTMAKE) -g $< -o otf --output-path $@

$(DIST)/jetbrains-mono.woff2: SRC := $(EXTRACT)/jetbrains-mono/fonts/variable/JetBrainsMono[wght].ttf
$(DIST)/jetbrains-mono.woff2: $(EXTRACT)/jetbrains-mono.done
$(DIST)/jetbrains-mono-italic.woff2: SRC := $(EXTRACT)/jetbrains-mono/fonts/variable/JetBrainsMono-Italic[wght].ttf
$(DIST)/jetbrains-mono-italic.woff2: $(EXTRACT)/jetbrains-mono.done
$(DIST)/fira-code.woff2: SRC := $(EXTRACT)/fira-code/variable_ttf/FiraCode-VF.ttf
$(DIST)/fira-code.woff2: $(EXTRACT)/fira-code.done
$(DIST)/source-code-pro.woff2: SRC := $(EXTRACT)/source-code-pro/VF/SourceCodeVF-Upright.ttf
$(DIST)/source-code-pro.woff2: $(EXTRACT)/source-code-pro.done
$(DIST)/source-code-pro-italic.woff2: SRC := $(EXTRACT)/source-code-pro/VF/SourceCodeVF-Italic.ttf
$(DIST)/source-code-pro-italic.woff2: $(EXTRACT)/source-code-pro.done
$(DIST)/ibm-plex-mono.woff2: SRC := $(EXTRACT)/ibm-plex-mono/ibm-plex-mono/fonts/complete/ttf/IBMPlexMono-Regular.ttf
$(DIST)/ibm-plex-mono.woff2: $(EXTRACT)/ibm-plex-mono.done
$(DIST)/ibm-plex-mono-italic.woff2: SRC := $(EXTRACT)/ibm-plex-mono/ibm-plex-mono/fonts/complete/ttf/IBMPlexMono-Italic.ttf
$(DIST)/ibm-plex-mono-italic.woff2: $(EXTRACT)/ibm-plex-mono.done
$(DIST)/ibm-plex-mono-semibold.woff2: SRC := $(EXTRACT)/ibm-plex-mono/ibm-plex-mono/fonts/complete/ttf/IBMPlexMono-SemiBold.ttf
$(DIST)/ibm-plex-mono-semibold.woff2: $(EXTRACT)/ibm-plex-mono.done
$(DIST)/cascadia-code.woff2: SRC := $(EXTRACT)/cascadia-code/ttf/CascadiaCode.ttf
$(DIST)/cascadia-code.woff2: $(EXTRACT)/cascadia-code.done
$(DIST)/cascadia-code-italic.woff2: SRC := $(EXTRACT)/cascadia-code/ttf/CascadiaCodeItalic.ttf
$(DIST)/cascadia-code-italic.woff2: $(EXTRACT)/cascadia-code.done
$(DIST)/opendyslexic-mono.woff2: SRC := $(OPENDYSLEXIC)/OpenDyslexicMono-Regular.otf
$(DIST)/opendyslexic-mono.woff2: $(OPENDYSLEXIC)/OpenDyslexicMono-Regular.otf

$(DIST)/%.woff2:
	mkdir -p $(@D)
	$(PYFTSUBSET) '$(SRC)' --flavor=woff2 --layout-features='*' --unicodes=$(UNICODES) --output-file=$@

# Each family's licence, copied from the source that ships it.
$(LICENSES)/jetbrains-mono-OFL.txt: LICENCE_SRC := $(EXTRACT)/jetbrains-mono/OFL.txt
$(LICENSES)/jetbrains-mono-OFL.txt: $(EXTRACT)/jetbrains-mono.done
$(LICENSES)/fira-code-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/fira-code-ofl
$(LICENSES)/fira-code-OFL.txt: $(DOWNLOADS)/fira-code-ofl
$(LICENSES)/source-code-pro-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/source-code-pro-ofl
$(LICENSES)/source-code-pro-OFL.txt: $(DOWNLOADS)/source-code-pro-ofl
$(LICENSES)/ibm-plex-mono-OFL.txt: LICENCE_SRC := $(EXTRACT)/ibm-plex-mono/ibm-plex-mono/LICENSE.txt
$(LICENSES)/ibm-plex-mono-OFL.txt: $(EXTRACT)/ibm-plex-mono.done
$(LICENSES)/cascadia-code-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/cascadia-code-ofl
$(LICENSES)/cascadia-code-OFL.txt: $(DOWNLOADS)/cascadia-code-ofl
$(LICENSES)/opendyslexic-mono-OFL.txt: LICENCE_SRC := $(DOWNLOADS)/opendyslexic-ofl
$(LICENSES)/opendyslexic-mono-OFL.txt: $(DOWNLOADS)/opendyslexic-ofl

$(LICENSES)/%-OFL.txt:
	mkdir -p $(@D)
	cp '$(LICENCE_SRC)' $@

$(DIST)/SHA256SUMS: $(addprefix $(DIST)/,$(WOFF2))
	cd $(DIST) && sha256sum $(WOFF2) | LC_ALL=C sort -k2 > SHA256SUMS

# Usage: make release TAG=vX.Y.Z
release: all
	@test -n "$(TAG)" || { echo "usage: make release TAG=vX.Y.Z" >&2; exit 1; }
	gh release create $(TAG) --repo LibrePaper/editor-fonts $(DIST)/*.woff2 $(DIST)/SHA256SUMS $(DIST)/licenses/*

clean:
	rm -rf build $(DIST)
