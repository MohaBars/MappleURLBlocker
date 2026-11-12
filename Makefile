# Build with Apple's iPhoneOS SDK, no Theos required.
SDK := $(shell xcrun --sdk iphoneos --show-sdk-path)
CLANG := xcrun --sdk iphoneos clang

TARGET := MappleURLBlocker.dylib
SOURCE := Sources/MappleURLBlocker.m

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CLANG) \
		-isysroot "$(SDK)" \
		-arch arm64 \
		-miphoneos-version-min=15.1 \
		-fobjc-arc \
		-fmodules \
		-dynamiclib \
		-install_name @rpath/$(TARGET) \
		-Wall -Wextra \
		-framework Foundation \
		-framework UIKit \
		-o $@ \
		$(SOURCE)

clean:
	rm -f $(TARGET)
