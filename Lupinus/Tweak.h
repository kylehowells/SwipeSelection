#include <substrate.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/runtime.h>

#define notificationDimTag @"setKeyboardToDim"

typedef void* CDUnknownBlockType;


static BOOL shiftByOtherKey = NO;
static BOOL isLongPressed = NO;
static BOOL isDeleteKey = NO;
static BOOL isInternationalKey = NO;
static BOOL isMoreKey = NO;

static BOOL isTwoFingerOn = NO;

static BOOL isSwiping = NO;

static BOOL isForceTouchDown = NO;

/// TextInout
@protocol UITextInputPrivate <UITextInput, UITextInputTokenizer> //, UITextInputTraits_Private, UITextSelectingContainer>
-(BOOL)shouldEnableAutoShift;
-(NSRange)selectionRange;
-(CGRect)rectForNSRange:(NSRange)nsrange;
-(NSRange)_markedTextNSRange;
//-(id)selectedDOMRange;
//-(id)wordInRange:(id)range;
//-(void)setSelectedDOMRange:(id)range affinityDownstream:(BOOL)downstream;
//-(void)replaceRangeWithTextWithoutClosingTyping:(id)textWithoutClosingTyping replacementText:(id)text;
//-(CGRect)rectContainingCaretSelection;
-(void)moveBackward:(unsigned)backward;
-(void)moveForward:(unsigned)forward;
-(unsigned short)characterBeforeCaretSelection;
-(id)wordContainingCaretSelection;
-(id)wordRangeContainingCaretSelection;
-(id)markedText;
-(void)setMarkedText:(id)text;
-(BOOL)hasContent;
-(void)selectAll;
-(id)textColorForCaretSelection;
-(id)fontForCaretSelection;
-(BOOL)hasSelection;
@end


@interface UIKeyboardImpl : UIView
	+(UIKeyboardImpl*)sharedInstance;
	+(UIKeyboardImpl*)activeInstance;
	@property (readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
	@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;
	-(BOOL)isLongPress;
	-(id)_layout;
	-(BOOL)callLayoutIsShiftKeyBeingHeld;
	-(void)handleDelete;
	-(void)handleDeleteAsRepeat:(BOOL)repeat;
	-(void)handleDeleteWithNonZeroInputCount;
	-(void)stopAutoDelete;
	-(BOOL)handwritingPlane;

	-(void)updateForChangedSelection;

	-(void)clearSelection;
	-(void)collapseSelection;

	// // SwipeSelection
	// -(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
	// -(void)SS_revealSelection:(UIView*)inputView;
@end

/** Text Selection Stuff **/
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

-(void)setSelectionGranularity:(long long)arg1 ;
-(void)setCaretRectForCursorPosition:(CGRect)arg1 ;

-(UITextPosition *)cursorPosition;
@end

/** Text Gesture Stuff **/
@interface _UIKeyboardTextSelectionGestureController : NSObject
	+(id)sharedInstance;
	-(_UIKeyboardTextSelectionController *)selectionController;

	-(void)setLastPanTranslation:(CGPoint)arg1 ;
	-(CGPoint)cursorLocationForTranslation:(CGPoint)arg1;
	-(void)indirectCursorPanGestureWithState:(long long)arg1 withTranslation:(CGPoint)arg2 withFlickDirection:(unsigned long long)arg3 ;
	-(CGPoint)acceleratedTranslation:(CGPoint)arg1 velocity:(CGPoint)arg2 final:(BOOL)arg3 ;
@end

@interface _UITextSelectionForceGesture : UILongPressGestureRecognizer

@end



/** Keyboard hit stuff **/
@interface UIKBKey : NSObject
	@property(copy) NSString *representedString;
@end

@interface UIKeyboardLayout : UIView
	- (UIKBKey *)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
	- (UIKBKey *)keyHitTest:(CGPoint)arg1;
	-(id)keyHitTestWithoutCharging:(CGPoint)arg1;
	-(id)keyHitTestClosestToPoint:(CGPoint)arg1;
	-(id)keyHitTestContainingPoint:(CGPoint)arg1;
	- (void)setKeyboardToDim:(NSNotification*) notification;
	- (void)setKeyboardDim:(BOOL)arg1 ;

	-(BOOL)SS_shouldSelect;
	-(BOOL)SS_disableSwipes;
	-(BOOL)isShiftKeyBeingHeld;
	-(void)deleteAction;
@end

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

	-(int)flickDirection;

	- (BOOL)isLeafType;
	- (BOOL)usesKeyCharging;
	- (BOOL)usesAdaptiveKeys;
	- (BOOL)modifiesKeyplane;
	- (BOOL)avoidsLanguageIndicator;
	- (BOOL)isAlphabeticPlane;
	- (BOOL)noLanguageIndicator;
	- (BOOL)isLetters;
	- (BOOL)subtreesAreOrdered;
@end


/// iOS 7 Task Execution
/// Handle Delete Key
@class UIKeyboardTaskExecutionContext;

@interface UIKeyboardTaskQueue : NSObject
	-(void)finishExecution;
@end

@interface UIKeyboardTaskExecutionContext : NSObject
@property(readonly, nonatomic) UIKeyboardTaskQueue *executionQueue;
@end





