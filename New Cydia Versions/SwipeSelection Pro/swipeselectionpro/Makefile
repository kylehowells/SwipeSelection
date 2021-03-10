ARCHS=armv7 arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SwipeSelectionPro
SwipeSelectionPro_FILES = SwipeSelectionPro.mm
SwipeSelectionPro_INSTALL_PATH = /Library/PreferenceBundles
SwipeSelectionPro_FRAMEWORKS = UIKit
SwipeSelectionPro_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipeSelectionPro.plist$(ECHO_END)
