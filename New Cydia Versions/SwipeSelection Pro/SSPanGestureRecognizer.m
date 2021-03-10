//
//  SSPanGestureRecognizer.m
//  
//
//  Created by Kyle Howells on 09/01/2014.
//
//

#import "SSPanGestureRecognizer.h"
#import <objc/runtime.h>


Class AKFlickGestureRecognizer(){
	static Class AKFlickGestureRecognizer_Class = nil;
	static BOOL checked = NO;
	
	if (!checked) {
		AKFlickGestureRecognizer_Class = objc_getClass("AKFlickGestureRecognizer");
	}
	
	return AKFlickGestureRecognizer_Class;
}


@implementation SSPanGestureRecognizer
-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
	
	
    if ([preventingGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
		([preventingGestureRecognizer isKindOfClass:AKFlickGestureRecognizer()] == NO))
	{
        return YES;
    }
	
    return NO;
}

-(BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer{
    return NO;
}
@end
