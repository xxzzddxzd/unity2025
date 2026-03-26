export THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = u2025s

u2025s_FILES = $(wildcard *.m)
u2025s_FRAMEWORKS = UIKit
u2025s_PRIVATE_FRAMEWORKS = Preferences
u2025s_INSTALL_PATH = /Library/PreferenceBundles
u2025s_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
u2025s_LDFLAGS = -F$(THEOS)/vendor/lib/ -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks/

include $(THEOS_MAKE_PATH)/bundle.mk
