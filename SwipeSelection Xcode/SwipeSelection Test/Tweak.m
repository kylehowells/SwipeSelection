//
//  Tweak.m
//  SwipeSelection Test
//
//  Created by Kyle Howells on 24/02/2017.
//  Copyright © 2017 Kyle Howells. All rights reserved.
//









//
// TODO: Add SwipeSelection Features
//
// [x]  Proof of concept
//
// [ ]  Start selecting text when starting dragging from the shift or delete keys.
// [ ]  Don't trigger delete on touch down, only touch up or long press.
// [ ]  Don't trigger if the starting key is the 123 key, or world key.
//
// [ ]  When selecting text pick the first cursor if the user begins the swipe going left, or up.
// [ ]  When selecting pick the second cursor if the users swipe starts by going right, or down.
//
// [ ]  Look into how to make the keyboard change into the trackpad mode (-setDimmed: is not it)
//










#import <Foundation/Foundation.h>
@import UIKit;


#pragma mark - Imports

#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/runtime.h>
#import "swizzling.h"



@interface _UIKeyboardTextSelectionController : NSObject
-(void)setCursorPosition:(UITextPosition *)arg1 ;
-(void)beginFloatingCursorAtPoint:(CGPoint)arg1 ;
-(void)beginSelection;
-(void)updateFloatingCursorAtPoint:(CGPoint)arg1 ;
-(void)updateSelectionWithExtentPoint:(CGPoint)arg1 executionContext:(id)arg2 ;
-(void)selectPositionAtPoint:(CGPoint)arg1 executionContext:(id)arg2 ;

-(void)endSelection;
-(void)endFloatingCursor;

-(void)switchToRangedSelection;

-(CGRect)caretRectForCursorPosition;

-(void)setSelectionGranularity:(NSInteger)arg1 ;
-(void)setCaretRectForCursorPosition:(CGRect)arg1 ;

-(UITextPosition *)cursorPosition;
@end



@interface _UIKeyboardTextSelectionGestureController : NSObject
+(id)sharedInstance;
-(_UIKeyboardTextSelectionController *)selectionController;

-(void)setLastPanTranslation:(CGPoint)arg1 ;
-(CGPoint)cursorLocationForTranslation:(CGPoint)arg1;
-(void)indirectCursorPanGestureWithState:(NSInteger)arg1 withTranslation:(CGPoint)arg2 withFlickDirection:(NSUInteger)arg3 ;
-(CGPoint)acceleratedTranslation:(CGPoint)arg1 velocity:(CGPoint)arg2 final:(BOOL)arg3 ;

-(void)configureOneFingerForcePressRecognizer:(id)arg1 ;
-(void)configureTwoFingerPanGestureRecognizer:(id)arg1 ;
-(void)configureTwoFingerTapGestureRecognizer:(id)arg1 ;
@end



@interface UIKBKey : NSObject
@property(copy) NSString *representedString;
@end

@interface UIKeyboardLayout : UIView
- (UIKBKey *)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
- (UIKBKey *)keyHitTest:(CGPoint)arg1;
- (void)setKeyboardDim:(BOOL)arg1 ;
@end




@protocol UITextInputPrivate <UITextInput, UITextInputTokenizer>
@end

@interface UIKeyboardImpl : UIView
+(UIKeyboardImpl*)sharedInstance;
+(UIKeyboardImpl*)activeInstance;
@property (readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;
-(void)handleDelete;
-(void)handleDeleteAsRepeat:(BOOL)repeat;
-(void)handleDeleteWithNonZeroInputCount;

-(UIKeyboardLayout*)_layout;

-(void)clearSelection;
-(void)collapseSelection;
@end




#pragma mark - Constants

#define notificationDimTag @"setKeyboardToDim"

static BOOL isInternationalKey = NO;
static BOOL isTwoFingerOn = NO;
static BOOL isSwiping = NO;
static BOOL isForceTouchDown = NO;






#pragma mark - Hooks


#pragma mark Stop Force Touch

@implementation UIView (_UIKeyboardTextSelectionGestureController_Extras)

static void (*configureOneFingerForcePressRecognizer)(id, SEL, id) = NULL;

static void swizzle_configureOneFingerForcePressRecognizer(_UIKeyboardTextSelectionGestureController *self, SEL _cmd, id arg1)
{
	// Do nothing
}


+ (void)load
{
	Class _UIKeyboardTextSelectionGestureController = objc_getClass("_UIKeyboardTextSelectionGestureController");
	SwizzleSelector(_UIKeyboardTextSelectionGestureController, @selector(configureOneFingerForcePressRecognizer:), swizzle_configureOneFingerForcePressRecognizer, &configureOneFingerForcePressRecognizer);
}

@end

// Turns into ^^^ that
//%hook _UIKeyboardTextSelectionGestureController
//// Stop forcetouch
//-(void)configureOneFingerForcePressRecognizer:(id)arg1 {}
//%end







#pragma mark UIKeyboardImpl

// We can't use %new, or add it as a category because we can't link against UIKeyboardImpl.
// So stick it on UIKeyboardImpl's superclass which we can link to, and it will inherit the method.
@interface UIView (SwipeSelection_extras)
-(void)ss_gs_extra_KeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
@end

@implementation UIView (SwipeSelection_extras)

-(void)ss_gs_extra_KeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture{
	
	int touchesCount = [gesture numberOfTouches];
	
	_UIKeyboardTextSelectionGestureController* _textSelectionGestureController = [objc_getClass("_UIKeyboardTextSelectionGestureController") sharedInstance];
	
	// _UIKeyboardTextSelectionController* _textSelectionController = MSHookIvar<_UIKeyboardTextSelectionController*>(self, "_textSelectionController");
	_UIKeyboardTextSelectionController* _textSelectionController = [_textSelectionGestureController selectionController];
	
	static CGPoint initialPosition;
	static CGPoint previousPosition;
	static CGPoint initialCursorPosition;
	static CGRect initialCursor;
	// Control Flags
	static BOOL hasStarted = NO;
	
	UIKeyboardImpl *keyboardImpl = (UIKeyboardImpl*)self;
	
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
		[_textSelectionController endSelection];
		[_textSelectionController endFloatingCursor];
		hasStarted = NO;
		initialCursor = [_textSelectionController caretRectForCursorPosition];
		initialCursorPosition = CGPointMake(initialCursor.origin.x,initialCursor.origin.y);
		
		isTwoFingerOn = NO;
	}
	else if (gesture.state == UIGestureRecognizerStateBegan) {
		initialCursor = [_textSelectionController caretRectForCursorPosition];
		initialCursorPosition = CGPointMake(initialCursor.origin.x, initialCursor.origin.y);
		
		previousPosition = [gesture locationInView:self];
		initialPosition = previousPosition;
		
		// 還原設置，以防其他觸摸按鍵失效
		gesture.cancelsTouchesInView = NO;
		
		if (touchesCount > 1) {
			isTwoFingerOn = YES;
		}
		
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		
		// Basic position record
		CGPoint position = [gesture locationInView:self];
		CGPoint delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y);
		CGPoint offsetToInitial = CGPointMake(position.x - initialPosition.x, position.y - initialPosition.y);
//		CGPoint transPosition = [_textSelectionGestureController cursorLocationForTranslation:position];
		
		// CGPoint tPosition = [gesture translationInView:self];
		CGPoint tVelocity = [gesture velocityInView:self];
		// Some variables
		CGFloat thresholdX = 10;
		CGFloat thresholdY = 0;
		
		// 如果按住換語言按鈕
		// 要放在threshold前，不然手勢會取消語言view
		if (isInternationalKey == YES) {
			// gesture.cancelsTouchesInView = NO;
			return ;
		}
		
		if (isForceTouchDown == YES){
			return ;
		}
		
		if ((hasStarted == NO && delta.x < thresholdX && delta.x > (-thresholdX))
			&& (hasStarted == NO && delta.y < thresholdY && delta.y > (-thresholdY))
			){
			return;
		}
		
		id <UITextInputPrivate> privateInputDelegate = nil;
		if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
			privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
		}
		if (!privateInputDelegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
			privateInputDelegate = (id)keyboardImpl.inputDelegate;
		}
		
		if (hasStarted == NO){
			initialCursor = [_textSelectionController caretRectForCursorPosition];
			initialCursorPosition = CGPointMake(initialCursor.origin.x,initialCursor.origin.y);
			[_textSelectionController beginFloatingCursorAtPoint:initialCursorPosition];
			[_textSelectionController beginSelection];
			
			if (privateInputDelegate != nil && [NSStringFromClass([privateInputDelegate class]) isEqualToString:@"UnifiedField"]) {
				[keyboardImpl collapseSelection];
			}
		}
		
		/*
#########################
		START
#########################
		*/
		
		gesture.cancelsTouchesInView = YES;
		hasStarted = YES;
		// Set keyboard dim giving feedback
//		[[NSNotificationCenter defaultCenter] postNotificationName:notificationDimTag　object:nil];
		
//		UIKeyboardLayoutStar *layout = [keyboardImpl _layout];
//		if ([layout respondsToSelector:@selector(setKeyboardDim:)]) {
//			[layout setKeyboardDim:YES];
//		}
		
		
		double velocityY = floor(tVelocity.y / 30);
		double velocityX = floor(tVelocity.x / 50);
		CGPoint realPositionToView = CGPointMake(initialCursorPosition.x+offsetToInitial.x+velocityX, initialCursorPosition.y+offsetToInitial.y+velocityY); //+transPosition.y
		
		if (isTwoFingerOn == YES){
			[_textSelectionController switchToRangedSelection];
			[_textSelectionController updateFloatingCursorAtPoint:realPositionToView];//一般字黃色游標 arg1 = point是transPosition
			[_textSelectionController updateSelectionWithExtentPoint:realPositionToView executionContext:nil]; // 選字, point = transPosition
		} else {
			BOOL isUITextView = [privateInputDelegate isKindOfClass:[UITextView class] ];
			BOOL isUITextField = [privateInputDelegate isKindOfClass:[UITextField class] ];
			
			// UnifiedField
			if (isUITextView) {
				UITextView* inputView = (UITextView*)privateInputDelegate;
				if(inputView.frame.size.height <= 35){
					// One line textview
					realPositionToView = CGPointMake(initialCursorPosition.x+offsetToInitial.x+velocityX, initialCursorPosition.y + 10); //+transPosition.y
				}
			}
			
			if (isUITextField) {
				realPositionToView = CGPointMake(initialCursorPosition.x+offsetToInitial.x+velocityX, initialCursorPosition.y + 10); //+transPosition.y
			}
			
			[_textSelectionGestureController indirectCursorPanGestureWithState:UIGestureRecognizerStateChanged withTranslation:realPositionToView withFlickDirection:0];
			// [_textSelectionController selectPositionAtPoint:pointInView executionContext:nil]; //一般字 arg1 = point是transPosition
		}
		
		previousPosition = position;
	}
}

@end


// Now to hook the initWithFrame method

@implementation UIView (UIKeyboardImpl_Extras)

static id (*keyboard_initWithFrame)(id, SEL, CGRect) = NULL;

static id swizzle_keyboard_initWithFrame(id self, SEL _cmd, CGRect frame)
{
	if ((self = keyboard_initWithFrame(self, _cmd, frame))) {
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(ss_gs_extra_KeyboardGestureDidPan:)];
		pan.cancelsTouchesInView = NO;
		[self addGestureRecognizer:pan];
	}
	return self;
}

// Should use +load, but it should also be _UIKeyboardTextSelectionGestureController's +load method
+ (void)load
{
	Class _UIKeyboardImpl_ = objc_getClass("UIKeyboardImpl");
	SwizzleSelector(_UIKeyboardImpl_, @selector(initWithFrame:), swizzle_keyboard_initWithFrame, &keyboard_initWithFrame);
}

@end

/* Becomes the above ^^^^
%hook UIKeyboardImpl

// So I add GestureRecognizer here
-(id)initWithFrame:(CGRect)rect{
	id orig = %orig;
	
	if (orig){
		_UIKeyboardTextSelectionGestureController* _textSelectionGestureController = [objc_getClass("_UIKeyboardTextSelectionGestureController") sharedInstance];
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(GS_KeyboardGestureDidPan:)];
		pan.cancelsTouchesInView = NO;
		[self addGestureRecognizer:pan];
	}
	
	return orig;
}

*/












#pragma mark Keyboard View Itself
/*
%hook UIKeyboardLayoutStar

// Add Notification here
-(id)initWithFrame:(CGRect)arg1 {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setKeyboardToDim:) name:notificationDimTag object:nil];
	return %orig();
}
%new
-(void) setKeyboardToDim:(NSNotification*) notification {
	// [notification object];
	[self setKeyboardDim:YES];
	// NSLog(@"[GGGGGG] setKeyboardToDim %@",notification);
}

 

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	// International key
	if ([key isEqualToString:@"international"] || [key isEqualToString:@"emojiinternational"]) {
		isInternationalKey = YES;
	} else {
		isInternationalKey = NO;
	}
	
	%orig;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	// International key
	if ([key isEqualToString:@"international"] || [key isEqualToString:@"emojiinternational"]) {
		isInternationalKey = YES;
	} else {
		isInternationalKey = NO;
	}
	
	%orig;
}

-(void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
	%orig(arg1, arg2);
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	isInternationalKey = NO;
	%orig;
}

%end // UIKeyboardLayoutStar end
*/


static id (*original_keyboard_touchBeganMethod)(id self, SEL _cmd, NSSet *touches, UIEvent *event) = NULL;
static id (*original_keyboard_touchMovedMethod)(id self, SEL _cmd, NSSet *touches, UIEvent *event) = NULL;
static id (*original_keyboard_touchesEndedMethod)(id self, SEL _cmd, NSSet *touches, UIEvent *event) = NULL;

static void keyboard_touchBeganMethod(id self, SEL _cmd, NSSet *touches, UIEvent *event)
{
	UITouch *touch = [touches anyObject];
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	// International key
	if ([key isEqualToString:@"international"] || [key isEqualToString:@"emojiinternational"]) {
		isInternationalKey = YES;
	} else {
		isInternationalKey = NO;
	}
	
	original_keyboard_touchBeganMethod(self, _cmd, touches, event);
}
static void keyboard_touchMovedMethod(id self, SEL _cmd, NSSet *touches, UIEvent *event)
{
	UITouch *touch = [touches anyObject];
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	// International key
	if ([key isEqualToString:@"international"] || [key isEqualToString:@"emojiinternational"]) {
		isInternationalKey = YES;
	} else {
		isInternationalKey = NO;
	}
	
	original_keyboard_touchMovedMethod(self, _cmd, touches, event);
}
static void keyboard_touchesEndedMethod(id self, SEL _cmd, NSSet *touches, UIEvent *event)
{
	isInternationalKey = NO;
	original_keyboard_touchesEndedMethod(self, _cmd, touches, event);
}


@implementation UIView (UIKeyboardLayoutStar_Extras)

+ (void)load
{
	Class _UIKeyboardLayoutStar_ = objc_getClass("UIKeyboardLayoutStar");
	
	SwizzleSelector(_UIKeyboardLayoutStar_, @selector(touchesBegan:withEvent:), keyboard_touchBeganMethod, &original_keyboard_touchBeganMethod);
	SwizzleSelector(_UIKeyboardLayoutStar_, @selector(touchesMoved:withEvent:), keyboard_touchMovedMethod, &original_keyboard_touchMovedMethod);
	SwizzleSelector(_UIKeyboardLayoutStar_, @selector(touchesEnded:withEvent:), keyboard_touchesEndedMethod, &original_keyboard_touchesEndedMethod);
}

@end






