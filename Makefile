.PHONY: help setup analyze test format format-check clean build-windows build-linux build-macos run ci

help:
	@echo "Available targets:"
	@echo "  setup          - Install Dart/Flutter dependencies"
	@echo "  analyze        - Run static analysis"
	@echo "  test           - Run unit/widget tests"
	@echo "  format         - Format code in-place"
	@echo "  format-check   - Check formatting without changing files"
	@echo "  clean          - Clean build artifacts"
	@echo "  build-windows  - Build Windows desktop app"
	@echo "  build-linux    - Build Linux desktop app"
	@echo "  build-macos    - Build macOS desktop app"
	@echo "  run            - Run default device/app (desktop if available)"
	@echo "  ci             - Analyze + test (what CI runs)"

setup:
	flutter pub get

analyze:
	flutter analyze

test:
	flutter test --reporter expanded

format:
	dart format .

format-check:
	dart format --output none --set-exit-if-changed .

clean:
	flutter clean

build-windows:
	flutter build windows

build-linux:
	flutter build linux

build-macos:
	flutter build macos

run:
	flutter run

ci: analyze test
