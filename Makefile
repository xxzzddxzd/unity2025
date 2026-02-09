export THEOS_PACKAGE_SCHEME = rootless
export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = unity2025

unity2025_FILES = tweak/Tweak.xm \
                  tweak/HookManager.mm \
                  tweak/ToolsManager.mm \
                  tweak/PreferencesManager.mm \
                  tweak/OverlayView.mm \
                  tweak/FloatingButton.mm

unity2025_CFLAGS = -fobjc-arc -Itweak -Wno-deprecated-declarations
unity2025_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation MediaPlayer
unity2025_LDFLAGS = -lsubstrate

SUBPROJECTS = u2025s

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
