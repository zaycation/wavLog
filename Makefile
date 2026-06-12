SCHEME = WavLog
PLATFORM_IOS = iOS Simulator,name=iPhone 16 Pro
XCODEGEN = xcodegen

# Generate the Xcode project from project.yml
.PHONY: generate
generate:
	$(XCODEGEN) generate

# Open the project in Xcode (generate first if needed)
.PHONY: open
open: generate
	open WavLog.xcodeproj

# Build for iOS simulator
.PHONY: build
build:
	xcodebuild build \
		-scheme $(SCHEME) \
		-destination "platform=$(PLATFORM_IOS)" \
		| xcpretty || xcodebuild build \
		-scheme $(SCHEME) \
		-destination "platform=$(PLATFORM_IOS)"

# Run tests
.PHONY: test
test:
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination "platform=$(PLATFORM_IOS)" \
		| xcpretty || xcodebuild test \
		-scheme $(SCHEME) \
		-destination "platform=$(PLATFORM_IOS)"

# Lint with SwiftLint
.PHONY: lint
lint:
	swiftlint lint --strict

# Auto-fix lint issues
.PHONY: lint-fix
lint-fix:
	swiftlint --fix && swiftlint lint --strict

# Clean derived data
.PHONY: clean
clean:
	xcodebuild clean -scheme $(SCHEME)
	rm -rf ~/Library/Developer/Xcode/DerivedData/WavLog-*
