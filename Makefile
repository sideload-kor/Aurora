NAME := Feather
SCHEME := Feather
WORKSPACE := Feather.xcworkspace
PLATFORMS := iphoneos maccatalyst

TMP := $(TMPDIR)/$(NAME)
CERT_JSON_URL := https://backloop.dev/pack.json

.PHONY: all clean deps $(PLATFORMS)

all: $(PLATFORMS)

clean:
	rm -rf $(TMP)
	rm -rf packages
	rm -rf Payload
	rm -rf _build

deps:
	rm -rf deps
	mkdir -p deps

	curl -fsSL "$(CERT_JSON_URL)" -o cert.json
	jq -r '.cert' cert.json > deps/server.crt
	jq -r '.key1, .key2' cert.json > deps/server.pem
	jq -r '.info.domains.commonName' cert.json > deps/commonName.txt

$(PLATFORMS): deps
	rm -rf _build

	@if [ "$@" = "iphoneos" ]; then \
		DEST="generic/platform=iOS"; \
	else \
		DEST="generic/platform=macOS,variant=Mac Catalyst"; \
	fi; \
	echo "========================================"; \
	echo "Building $(NAME)"; \
	echo "Workspace: $(WORKSPACE)"; \
	echo "Scheme: $(SCHEME)"; \
	echo "Destination: $$DEST"; \
	echo "========================================"; \
	xcodebuild \
		-workspace "$(WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-destination "$$DEST" \
		-derivedDataPath "$(TMP)/$@" \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	mkdir -p _build/Payload

	cp -R "$(TMP)/$@/Build/Products/Release-iphoneos/Feather.app" \
		_build/Payload/Feather.app 2>/dev/null || \
	cp -R "$(TMP)/$@/Build/Products/Release-maccatalyst/Feather.app" \
		_build/Payload/Feather.app

	chmod -R 0755 _build/Payload/Feather.app

	codesign \
		--force \
		--sign - \
		--timestamp=none \
		_build/Payload/Feather.app

	cp deps/* _build/Payload/Feather.app/ || true

	mkdir -p packages

	@if [ "$@" = "iphoneos" ]; then \
		ditto \
			-c \
			-k \
			--sequesterRsrc \
			--keepParent \
			_build/Payload \
			"packages/Feather.ipa"; \
	else \
		ditto \
			-c \
			-k \
			--sequesterRsrc \
			--keepParent \
			_build/Payload/Feather.app \
			"packages/Feather_Catalyst.zip"; \
	fi
