APP_NAME = Sasayaku
BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/release
INSTALL_DIR = /Applications

.PHONY: build install uninstall clean run

build:
	swift build -c release
	@echo "Creating $(BUNDLE)..."
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Sources/$(APP_NAME)/Info.plist $(BUNDLE)/Contents/Info.plist
	@echo "✓ Built $(BUNDLE)"

install: build
	@echo "Installing to $(INSTALL_DIR)/$(BUNDLE)..."
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@cp -R $(BUNDLE) $(INSTALL_DIR)/$(BUNDLE)
	@echo "✓ Installed! Launch from Applications or Spotlight."

uninstall:
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@echo "✓ Uninstalled $(APP_NAME)"

run: build
	@open $(BUNDLE)

clean:
	swift package clean
	@rm -rf $(BUNDLE)
	@echo "✓ Cleaned"
