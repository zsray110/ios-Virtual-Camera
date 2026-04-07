TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VirtualCamera
VirtualCamera_FILES = Tweak.xm
VirtualCamera_FRAMEWORKS = UIKit AVFoundation CoreGraphics
VirtualCamera_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
