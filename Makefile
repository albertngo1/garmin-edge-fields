# Points at the SDK Manager's "current" symlink, so it tracks whatever SDK
# version you have active (no need to edit on upgrades).
SDK_HOME := $(HOME)/Library/Application Support/Garmin/ConnectIQ/Sdks/current
MONKEYC  := $(SDK_HOME)/bin/monkeyc
JAVA_HOME := /opt/homebrew/opt/openjdk@17
KEY := developer_key.der
DEVICE := edge1050

.PHONY: build sim tests release key palette-check install-hooks

# Generate a developer key (run once). Keep developer_key.der safe & gitignored.
key:
	openssl genrsa -out developer_key.pem 4096
	openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out $(KEY) -nocrypt
	@echo "✅ developer_key.der created"

# Sideloadable build -> dev/TimeInZone.prg  (copy to GARMIN/Apps on the Edge over USB)
build:
	@mkdir -p dev
	JAVA_HOME="$(JAVA_HOME)" "$(MONKEYC)" -f monkey.jungle -o dev/TimeInZone.prg -y "$(KEY)" -d $(DEVICE)
	@echo "✅ Built dev/TimeInZone.prg  — copy to <Edge>/GARMIN/Apps/"

# Build + launch in the simulator (start 'connectiq' sim first, or this starts it)
sim:
	@mkdir -p bin
	JAVA_HOME="$(JAVA_HOME)" "$(MONKEYC)" -f monkey.jungle -o bin/TimeInZone.prg -y "$(KEY)" -d $(DEVICE)
	JAVA_HOME="$(JAVA_HOME)" "$(SDK_HOME)/bin/connectiq" & sleep 5; \
	JAVA_HOME="$(JAVA_HOME)" "$(SDK_HOME)/bin/monkeydo" bin/TimeInZone.prg $(DEVICE)

# Run unit tests in the simulator
tests:
	@mkdir -p bin
	JAVA_HOME="$(JAVA_HOME)" "$(MONKEYC)" -f monkey.jungle -o bin/TimeInZoneTest.prg -y "$(KEY)" -d $(DEVICE) -t
	JAVA_HOME="$(JAVA_HOME)" "$(SDK_HOME)/bin/connectiq" & sleep 5; \
	JAVA_HOME="$(JAVA_HOME)" "$(SDK_HOME)/bin/monkeydo" bin/TimeInZoneTest.prg $(DEVICE) -t

# Verify every device's hardcoded Palette still matches its profile palette.
# Reads the live SDK-Manager-installed device profiles.
palette-check:
	python3 tools/check_native_palette.py

# Route git at the version-controlled hooks (enables the pre-commit palette guard).
install-hooks:
	git config core.hooksPath hooks
	chmod +x hooks/pre-commit
	@echo "✅ git hooks installed (pre-commit palette guard active)"

# Store-publishable package -> release/TimeInZone.iq
release:
	@mkdir -p release
	JAVA_HOME="$(JAVA_HOME)" "$(MONKEYC)" -f monkey.jungle -o release/TimeInZone.iq -e -y "$(KEY)" -r
	@echo "✅ Built release/TimeInZone.iq"
