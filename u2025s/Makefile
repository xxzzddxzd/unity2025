TARGET := iphone:clang:latest:14.0
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = u2025s

u2025s_FILES = $(wildcard *.m)
u2025s_FRAMEWORKS = UIKit
u2025s_PRIVATE_FRAMEWORKS = Preferences AltList
u2025s_INSTALL_PATH = /Library/PreferenceBundles
u2025s_CFLAGS = -fobjc-arc -Wno-deprecated-declarations


include $(THEOS_MAKE_PATH)/bundle.mk
