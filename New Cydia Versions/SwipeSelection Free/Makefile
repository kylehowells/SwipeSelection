ARCHS=armv7 arm64
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeSelection
SwipeSelection_FILES = Tweak.xm SSPanGestureRecognizer.m SSKHSettingsController.m
SwipeSelection_FRAMEWORKS = UIKit Foundation CoreGraphics
SwipeSelection_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
