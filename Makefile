export TARGET = iphone:clang:latest:14.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VirtualCamera
# 确保包含所有必要的源代码
VirtualCamera_FILES = Tweak.xm $(wildcard Classes/*.m)
VirtualCamera_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo CoreGraphics
VirtualCamera_CFLAGS = -fobjc-arc -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
