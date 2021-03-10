//
//  SSKHSettingsController.h
//  
//
//  Created by Kyle Howells on 09/01/2014.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    SSSwipeWholeKeyboard	= 1,  // Everything
    SSSwipeAvoidSpacebar	= 2,  // Exclude space bar
    SSSwipeOnlySpaceBar		= 3   // Only space bar
} SSSwipeableArea;

typedef enum {
    SSSwipeSpeedSlowest		= -2,
    SSSwipeSpeedSlower		= -1,
    SSSwipeSpeedNormal		= 0,
    SSSwipeSpeedFaster		= 1,
    SSSwipeSpeedFastest		= 2
} SSSwipeSpeed;


typedef enum {
    SSSwipeSensitivityNormal		= 1,
	SSSwipeSensitivityReduced		= 2,
	SSSwipeSensitivityInsensitive	= 3
} SSSwipeSensitivity;



@interface SSKHSettingsController : NSObject
+(void)loadSettings;

+(void)setEnabled:(BOOL)enabled;

+(BOOL)enabled;
+(BOOL)tripleTapToggles;
+(BOOL)threeFingerSwipe;

+(SSSwipeableArea)swipeableArea;
+(SSSwipeSpeed)swipeSpeed;
+(SSSwipeSensitivity)swipeSensitivity;
@end
