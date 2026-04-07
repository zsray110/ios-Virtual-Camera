# 强制指定架构和系统版本
export TARGET = iphone:clang:latest:14.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VirtualCamera

# 核心修正：确保只包含 Tweak.xm，不要去引用不存在的 Classes 目录
VirtualCamera_FILES = Tweak.xm
VirtualCamera_FRAMEWORKS = UIKit AVFoundation CoreGraphics MediaPlayer
VirtualCamera_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
