//
//  Header.h
//  
//
//  Created by Kyle Howells on 09/01/2014.
//
//

#pragma mark - Imports

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

#import "SSKHSettingsController.h"





#pragma mark - Helpers

#define SET_IF_TRUE(_value_, _variable_)	((_value_) ? _variable_ = _value_ : _variable_ = _variable_)
#define KH_POSITIVE(_x_)	(((_x_) < 0) ? (-(_x_)) : (_x_))






#pragma mark - Headers

/// iOS 7 Task Execution
@class UIKeyboardTaskExecutionContext;


@interface UIKeyboardTaskQueue : NSObject
@property(retain, nonatomic) UIKeyboardTaskExecutionContext *executionContext;
-(BOOL)isMainThreadExecutingTask;
-(void)performTask:(id)arg1;
-(void)waitUntilAllTasksAreFinished;
-(void)addDeferredTask:(id)arg1;
-(void)addTask:(id)arg1;
-(void)promoteDeferredTaskIfIdle;
-(void)performDeferredTaskIfIdle;
-(void)performTaskOnMainThread:(id)arg1 waitUntilDone:(void)arg2;
-(void)finishExecution;
-(void)continueExecutionOnMainThread;
-(void)unlock;
-(BOOL)tryLockWhenReadyForMainThread;
-(void)lockWhenReadyForMainThread;
-(void)lock;
@end


@interface UIKeyboardTaskExecutionContext : NSObject
@property(readonly, nonatomic) UIKeyboardTaskQueue *executionQueue;

-(void)transferExecutionToMainThreadWithTask:(id)arg1;
-(void)returnExecutionToParent;
-(id)childWithContinuation:(id)arg1;
-(id)initWithParentContext:(id)arg1 continuation:(id)arg2;
-(id)initWithExecutionQueue:(id)arg1;
@end



/** iOS 7 **/
@interface UIKBTree : NSObject <NSCopying>
+(id)keyboard;
+(id)key;
+(id)shapesForControlKeyShapes:(id)arg1 options:(int)arg2;
+(id)mergeStringForKeyName:(id)arg1;
+(BOOL)shouldSkipCacheString:(id)arg1;
+(id)stringForType:(int)arg1;
+(id)treeOfType:(int)arg1;
+(id)uniqueName;

@property(retain, nonatomic) NSString *layoutTag;
@property(retain, nonatomic) NSMutableDictionary *cache;
@property(retain, nonatomic) NSMutableArray *subtrees;
@property(retain, nonatomic) NSMutableDictionary *properties;
@property(retain, nonatomic) NSString *name;
@property(nonatomic) int type;
-(BOOL)isLeafType;
-(BOOL)usesKeyCharging;
-(BOOL)usesAdaptiveKeys;
-(BOOL)modifiesKeyplane;
-(BOOL)avoidsLanguageIndicator;
-(BOOL)isAlphabeticPlane;
-(BOOL)noLanguageIndicator;
-(BOOL)isLetters;
-(BOOL)subtreesAreOrdered;

-(NSString*)representedString;
-(NSString*)fullRepresentedString;
@end




@interface UIKeyboardLayout : UIView
-(UIKBTree*)keyHitTest:(CGPoint)point;
@end


@interface UIKeyboardLayoutStar : UIKeyboardLayout
@property(retain) UIKBTree * activeKey;
@property BOOL autoShift;
@property BOOL didLongPress;
@property(readonly) UIKBTree * keyboard;
@property(copy) NSString * keyboardName;
@property(readonly) UIKBTree * keyplane;
@property(copy) NSString * keyplaneName;
@property(copy) NSString * localizedInputKey;
@property(readonly) NSString * localizedInputMode;
@property int playKeyClickSoundOn;
@property(copy) NSString * preTouchKeyplaneName;
@property BOOL shift;
@property(readonly) BOOL showDictationKey;

// iOS 7
-(id)keyHitTest:(CGPoint)arg1;
-(id)keyHitTestWithoutCharging:(CGPoint)arg1;
-(id)keyHitTestClosestToPoint:(CGPoint)arg1;
-(id)keyHitTestContainingPoint:(CGPoint)arg1;

-(BOOL)isShiftKeyBeingHeld;
-(BOOL)handwritingPlane;

//-(BOOL)SS_shouldSelect;
//-(BOOL)SS_disableSwipes;
@end


@interface UIKeyboardImpl : UIView
+(UIKeyboardImpl*)sharedInstance;
+(UIKeyboardImpl*)activeInstance;
//@property (readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;

-(NSString*)UILanguagePreference;
-(NSString*)_getCurrentKeyboardName;
-(NSString*)_getCurrentKeyplaneName;
-(NSString*)_getLocalizedInputMode;

-(BOOL)isLongPress;
-(UIKeyboardLayout*)_layout;
-(BOOL)callLayoutIsShiftKeyBeingHeld;
-(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
-(void)handleDelete;
-(void)handleDeleteAsRepeat:(BOOL)repeat;
-(void)handleDeleteWithNonZeroInputCount;
-(void)stopAutoDelete;
-(BOOL)handwritingPlane;

-(void)updateForChangedSelection;
@end





















//
// Random Selection visible stuff, must find something better
//

@interface UIFieldEditor : NSObject
+(UIFieldEditor*)sharedFieldEditor;
-(void)revealSelection;
@end

@interface UIView(Private_text) <UITextInput>
-(CGRect)caretRect;
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;

-(void)scrollSelectionToVisible:(BOOL)arg1;
@end











// Safari webview

@interface WKContentView : UIView
-(void)moveByOffset:(NSInteger)offset;
@end

