#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface SwipeSelectionProListController: PSListController
@end

@implementation SwipeSelectionProListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SwipeSelectionPro" target:self] retain];
	}
	return _specifiers;
}



// iOS 8 fix (official cfprefs API's don't work in sandboxed apps)

#define SETTINGS_FILE       @"/User/Library/Preferences/com.iky1e.swipeselection.plist"
// http://iphonedevwiki.net/index.php/PreferenceBundles#Into_sandboxed.2Funsandboxed_processes_in_iOS_8

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE];
	if (!exampleTweakSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return exampleTweakSettings[specifier.properties[@"key"]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:SETTINGS_FILE atomically:YES];
	
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if (toPost) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
	}
}

@end

// vim:ft=objc
