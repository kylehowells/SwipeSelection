ARCHS=armv7 arm64
TARGET = iphone:9.3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeSelectionPro
SwipeSelectionPro_FILES = Tweak.xm SSPanGestureRecognizer.m SSKHSettingsController.m
SwipeSelectionPro_FRAMEWORKS = UIKit Foundation CoreGraphics
SwipeSelectionPro_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += swipeselectionpro
include $(THEOS_MAKE_PATH)/aggregate.mk
