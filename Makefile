ARCHS=armv7 arm64

include /opt/theos/makefiles/common.mk

TWEAK_NAME = SwipeSelection
SwipeSelection_FILES = Tweak.xm
SwipeSelection_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk


after-install::
	install.exec "killall -9 SpringBoard"
