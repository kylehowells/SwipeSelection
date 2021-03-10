//
//  SSKHSettingsController.m
//  
//
//  Created by Kyle Howells on 09/01/2014.
//
//

#import "SSKHSettingsController.h"
#import <notify.h>


@interface NSUserDefaults (Private)
-(instancetype)_initWithSuiteName:(id)arg1 container:(id)arg2;
-(id)objectForKey:(NSString *)defaultName inDomain:(id)domainName;
- (void)setObject:(id)arg1 forKey:(id)arg2 inDomain:(id)arg3;
@end

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif




#define SETTINGS_FILE       @"/User/Library/Preferences/com.iky1e.swipeselection.plist"

static NSDictionary *settings = nil;



@implementation SSKHSettingsController

+(void)load{
	[self loadSettings];
}
+(void)loadSettings{
	[settings release];
	settings = nil;
	settings = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_FILE];
}

+(id)objectForKey:(NSString*)key{
	return [settings objectForKey:key];
}


+(void)setEnabled:(BOOL)enabled{
	if (!settings) {
		[self loadSettings];
	}
	
	NSMutableDictionary *newSettings = [settings mutableCopy];
	[newSettings setObject:[NSNumber numberWithBool:enabled] forKey:@"SSEnabled"];
	[newSettings writeToFile:SETTINGS_FILE  atomically:YES];
	[newSettings release];
	
	[self loadSettings];
	
	notify_post("com.iky1e.swipeselection/internal_settingschanged");
}
+(BOOL)enabled{
    id temp = [self objectForKey:@"SSEnabled"];
    return (temp ? [temp boolValue] : YES);
}


+(BOOL)tripleTapToggles{
    id temp = [self objectForKey:@"SSTripleTap"];
    return (temp ? [temp boolValue] : NO);
}

+(BOOL)threeFingerSwipe{
    id temp = [self objectForKey:@"SSTripleSwipe"];
    return (temp ? [temp boolValue] : NO);
}


+(SSSwipeableArea)swipeableArea{
    id temp = [self objectForKey:@"SSSwipeArea"];
    return (temp ? [temp intValue] : SSSwipeWholeKeyboard);
}

+(SSSwipeSpeed)swipeSpeed{
    id temp = [self objectForKey:@"SSSwipeSpeed"];
    return (temp ? [temp intValue] : SSSwipeSpeedNormal);
}

+(SSSwipeSensitivity)swipeSensitivity{
    id temp = [self objectForKey:@"SSSwipeSensitivity"];
    return (temp ? [temp intValue] : SSSwipeSensitivityNormal);
}

@end

