// **************************************************** //
// **************************************************** //
// **********        Design outline          ********** //
// **************************************************** //
// **************************************************** //
//
// 1 finger moves the cursour
// 2 fingers moves it one word at a time
//
// Should be able to move between 1 and 2 fingers without lifting your hand.
// If a selection has been made and you move right the selection starts moving from the end.
// - else it starts at the beginning.
//
// Holding shift selects text between the starting point and the destination.
// - the starting point is the reverse of the non selection movement.
// - - movement to the right starts at the start of existing selections.
//
// Movement upwards when in 2 finger mode should jump to the nearest word in the new line.
// - But another movement up again (without sideways movement) will jump to the nearest word to the originals x location,
// - - this ensures that the cursour doesn't jump about moving far away from it's start point.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/runtime.h>


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



/** iOS 5-6 **/
@interface UIKBShape : NSObject
@end

@interface UIKBKey : UIKBShape
@property(copy) NSString * name;
@property(copy) NSString * representedString;
@property(copy) NSString * displayString;
@property(copy) NSString * displayType;
@property(copy) NSString * interactionType;
@property(copy) NSString * variantType;
//@property(copy) UIKBAttributeList * attributes;
@property(copy) NSString * overrideDisplayString;
@property(copy) NSString * clientVariantRepresentedString;
@property(copy) NSString * clientVariantActionName;
@property BOOL visible;
@property BOOL hidden;
@property BOOL disabled;
@property BOOL isGhost;
@property int splitMode;
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


@interface UIKeyboardLayout : UIView
-(UIKBKey*)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
// iOS 7
-(id)keyHitTest:(CGPoint)arg1;
-(id)keyHitTestWithoutCharging:(CGPoint)arg1;
-(id)keyHitTestClosestToPoint:(CGPoint)arg1;
-(id)keyHitTestContainingPoint:(CGPoint)arg1;

-(BOOL)SS_shouldSelect;
-(BOOL)SS_disableSwipes;
-(BOOL)isShiftKeyBeingHeld;
-(void)deleteAction;
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

// SwipeSelection
-(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
-(void)SS_revealSelection:(UIView*)inputView;
@end


@interface UIFieldEditor : NSObject
+(UIFieldEditor*)sharedFieldEditor;
-(void)revealSelection;
@end


//@interface UIWebDocumentView : UIView
//-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
//-(void)scrollSelectionToVisible:(BOOL)visible;
//@end


@interface UIView(Private_text) <UITextInput>
// UIWebDocumentView
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
-(void)scrollSelectionToVisible:(BOOL)visible;

// UITextInputPrivate
-(CGRect)caretRect;
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;

-(NSRange)selectedRange;
-(NSRange)selectionRange;
-(void)setSelectedRange:(NSRange)range;
-(void)setSelectionRange:(NSRange)range;
-(void)scrollSelectionToVisible:(BOOL)arg1;
-(CGRect)rectForSelection:(NSRange)range;
-(CGRect)textRectForBounds:(CGRect)rect;
@end


// Safari webview
@interface WKContentView : UIView
-(void)moveByOffset:(NSInteger)offset;
@end














#pragma mark - Helper functions

UITextPosition *KH_MovePositionDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextDirection direction){
	if (tokenizer && startPosition) {
		return [tokenizer positionFromPosition:startPosition inDirection:direction offset:1];
	}
	return nil;
}

UITextPosition *KH_tokenizerMovePositionWithGranularitInDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextGranularity granularity, UITextDirection direction){

	if (tokenizer && startPosition) {
		return [tokenizer positionFromPosition:startPosition toBoundary:granularity inDirection:direction];
	}

	return nil;
}

BOOL KH_positionsSame(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *position1, UITextPosition *position2){
	return ([tokenizer comparePosition:position1 toPosition:position2] == NSOrderedSame);
}





// AltKeyboard2 compatibility
Class AKFlickGestureRecognizer(){
	static Class AKFlickGestureRecognizer_Class = nil;
	static BOOL checked = NO;
	
	if (!checked) {
		AKFlickGestureRecognizer_Class = objc_getClass("AKFlickGestureRecognizer");
	}
	
	return AKFlickGestureRecognizer_Class;
}


#pragma mark - GestureRecognizer
@interface SSPanGestureRecognizer : UIPanGestureRecognizer
@end

#pragma mark - GestureRecognizer implementation
@implementation SSPanGestureRecognizer
-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
	
	if ([preventingGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
		([preventingGestureRecognizer isKindOfClass:AKFlickGestureRecognizer()] == NO))
	{
		return YES;
	}
	
	return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer{
	return NO;
}
@end







#pragma mark - Hooks
%hook UIKeyboardImpl

-(id)initWithFrame:(CGRect)rect{
	id orig = %orig;

	if (orig){
		SSPanGestureRecognizer *pan = [[SSPanGestureRecognizer alloc] initWithTarget:self action:@selector(SS_KeyboardGestureDidPan:)];
		pan.cancelsTouchesInView = NO;
		[self addGestureRecognizer:pan];
		[pan release];
	}

	return orig;
}

%new
-(void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture{
	// Location info (may change)
	static UITextRange *startingtextRange = nil;
	static CGPoint previousPosition;
	
	// Webview fix
	static CGFloat xOffset = 0;
	static CGPoint realPreviousPosition;

	// Basic info
	static BOOL shiftHeldDown = NO;
	static BOOL hasStarted = NO;
	static BOOL longPress = NO;
	static BOOL handWriting = NO;
	static BOOL haveCheckedHand = NO;
	static BOOL isFirstShiftDown = NO; // = first run of the code shift is held, then pick the pivot point
	static BOOL isMoreKey = NO;
	static int touchesWhenShiting = 0;
	static BOOL cancelled = NO;

	int touchesCount = [gesture numberOfTouches];

	UIKeyboardImpl *keyboardImpl = self;

	if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
		BOOL nLongTouch = [keyboardImpl isLongPress];
		if (nLongTouch) {
			longPress = nLongTouch;
		}
	}
	
	// Get current layout
	id currentLayout = nil;
	if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
		currentLayout = [keyboardImpl _layout];
	}
	
	// Check more key, unless it's already ues
	if ([currentLayout respondsToSelector:@selector(SS_disableSwipes)] && !isMoreKey) {
		isMoreKey = [currentLayout SS_disableSwipes];
	}
	
	// Hand writing recognition
	if ([currentLayout respondsToSelector:@selector(handwritingPlane)] && !haveCheckedHand) {
		handWriting = [currentLayout handwritingPlane];
	}
	else if ([currentLayout respondsToSelector:@selector(subviews)] && !handWriting && !haveCheckedHand) {
		NSArray *subviews = [((UIView*)currentLayout) subviews];
		for (UIView *subview in subviews) {

			if ([subview respondsToSelector:@selector(subviews)]) {
				NSArray *arrayToCheck = [subview subviews];

				for (id view in arrayToCheck) {
					NSString *classString = [NSStringFromClass([view class]) lowercaseString];
					NSString *substring = [@"Handwriting" lowercaseString];

					if ([classString rangeOfString:substring].location != NSNotFound) {
						handWriting = YES;
						break;
					}
				}
			}
		}
		haveCheckedHand = YES;
	}
	haveCheckedHand = YES;
	
	
	
	// Check for shift key being pressed
	if ([currentLayout respondsToSelector:@selector(SS_shouldSelect)] && !shiftHeldDown) {
		shiftHeldDown = [currentLayout SS_shouldSelect];
		isFirstShiftDown = YES;
		touchesWhenShiting = touchesCount;
	}
	
	
	// Get the text input
	id <UITextInputPrivate> privateInputDelegate = nil;
	if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
		privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
	}
	if (!privateInputDelegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
		privateInputDelegate = (id)keyboardImpl.inputDelegate;
	}

	// Viber custom text view, which is super buggy with the tockenizer stuff.
	if (privateInputDelegate != nil && [NSStringFromClass([privateInputDelegate class]) isEqualToString:@"VBEmoticonsContentTextView"]) {
		privateInputDelegate = nil;
		cancelled = YES; // Try disabling it
	}
	
	
	
	
	//
	// Start Gesture stuff
	//
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
		
		if (hasStarted)
		{
			if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
				UITextRange *range = [privateInputDelegate selectedTextRange];
				if (range && !range.empty) {
					CGRect screenBounds = [UIScreen mainScreen].bounds;
					CGRect rect = CGRectMake(screenBounds.size.width * 0.5, screenBounds.size.height * 0.5, 1, 1);
					
					if ([privateInputDelegate respondsToSelector:@selector(firstRectForRange:)]) {
						rect = [privateInputDelegate firstRectForRange:range];
					}
					
					UIView *view = nil;
					if ([privateInputDelegate isKindOfClass:[UIView class]]) {
						view = (UIView*)privateInputDelegate;
					}
					else if ([privateInputDelegate respondsToSelector:@selector(inputDelegate)]) {
						id v = [keyboardImpl inputDelegate];
						if (v != privateInputDelegate) {
							if ([v isKindOfClass:[UIView class]]) {
								view = (UIView*)v;
							}
						}
					}
					
					// Should fix this to actually get the onscreen rect
					UIMenuController *menu = [UIMenuController sharedMenuController];
					[menu setTargetRect:rect inView:view];
					[menu setMenuVisible:YES animated:YES];
				}
			}
			
			// Tell auto correct/suggestions the cursor has moved
			if ([keyboardImpl respondsToSelector:@selector(updateForChangedSelection)]) {
				[keyboardImpl updateForChangedSelection];
			}
		}
		

		shiftHeldDown = NO;
		isMoreKey = NO;
		longPress = NO;
		hasStarted = NO;
		handWriting = NO;
		haveCheckedHand = NO;
		cancelled = NO;

		touchesCount = 0;
		touchesWhenShiting = 0;
		gesture.cancelsTouchesInView = NO;
	}
	else if (longPress || handWriting || !privateInputDelegate || isMoreKey || cancelled) {
		return;
	}
	else if (gesture.state == UIGestureRecognizerStateBegan) {
		xOffset = 0;
		
		previousPosition = [gesture locationInView:self];
		realPreviousPosition = previousPosition;

		if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
			[startingtextRange release], startingtextRange = nil;
			startingtextRange = [[privateInputDelegate selectedTextRange] retain];
		}
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		UITextRange *currentRange = startingtextRange;
		if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
			currentRange = nil;
			currentRange = [[[privateInputDelegate selectedTextRange] retain] autorelease];
		}

		CGPoint position = [gesture locationInView:self];
		CGPoint delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y);
		
		// Should we even run?
		CGFloat deadZone = 18;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			deadZone = 30;
		}
		
		// If hasn't started, and it's either moved to little or the user swiped up (accents) kill it.
		if (hasStarted == NO && ABS(delta.y) > deadZone) {
			if (ABS(delta.y) > ABS(delta.x)) {
				cancelled = YES;
			}
		}
		if ((hasStarted == NO && delta.x < deadZone && delta.x > (-deadZone)) || cancelled) {
			return;
		}
		
		// We are running so shut other things off/down
		gesture.cancelsTouchesInView = YES;
		hasStarted = YES;

		// Make x & y positive for comparision
		CGFloat positiveX = ABS(delta.x);
		// CGFloat positiveY = ((delta.y >= 0) ? delta.y : (-delta.y));

		// Determine the direction it should be going in
		UITextDirection textDirection;
		if (delta.x < 0) {
			textDirection = UITextStorageDirectionBackward;
		}
		else {
			textDirection = UITextStorageDirectionForward;
		}


		// Only do these new big 'jumps' if we've moved far enough
		CGFloat xMinimum = 10;
		// CGFloat yMinimum = 1;

		CGFloat neededTouches = 2;
		if (shiftHeldDown && (touchesWhenShiting >= 2)) {
			neededTouches = 3;
		}

		UITextGranularity granularity = UITextGranularityCharacter;
		// Handle different touches
		if (touchesCount >= neededTouches) {
			// make it skip words
			granularity = UITextGranularityWord;
			xMinimum = 20;
		}

		// Should we move the cusour or extend the current range.
		BOOL extendRange = shiftHeldDown;

		static UITextPosition *pivotPoint = nil;

		// Get the new range
		UITextPosition *positionStart = currentRange.start;
		UITextPosition *positionEnd = currentRange.end;

		// The moving position is
		UITextPosition *_position = nil;

		// If this is the first run we are selecting then pick our pivot point
		if (isFirstShiftDown) {
			[pivotPoint release], pivotPoint = nil;
			if (delta.x > 0 || delta.y < -20) {
				pivotPoint = [positionStart retain];
			}
			else {
				pivotPoint = [positionEnd retain];
			}
		}
		if (extendRange && pivotPoint) {
			// Find which position isn't our pivot and move that.
			BOOL startIsPivot = KH_positionsSame(privateInputDelegate, pivotPoint, positionStart);
			if (startIsPivot) {
				_position = positionEnd;
			}
			else {
				_position = positionStart;
			}
		}
		else {
			_position = (delta.x > 0) ? positionEnd : positionStart;

			if (!pivotPoint) {
				pivotPoint = _position;
			}
		}


		// Is it right to left at the current selection point?
		if ([privateInputDelegate baseWritingDirectionForPosition:_position inDirection:UITextStorageDirectionForward] == UITextWritingDirectionRightToLeft) {
			if (textDirection == UITextStorageDirectionForward){
				textDirection = UITextStorageDirectionBackward;
			}
			else {
				textDirection = UITextStorageDirectionForward;
			}
		}

		
		// Try and get the tockenizer
		id <UITextInputTokenizer, UITextInput> tokenizer = nil;
		if ([privateInputDelegate respondsToSelector:@selector(positionFromPosition:toBoundary:inDirection:)]) {
			tokenizer = privateInputDelegate;
		}
		else if ([privateInputDelegate respondsToSelector:@selector(tokenizer)]) {
			tokenizer = (id <UITextInput, UITextInputTokenizer>)privateInputDelegate.tokenizer;
		}
		
		if (tokenizer) {
			// Move X
			if (positiveX >= 1) {
				UITextPosition *_position_old = _position;
				
				if (granularity == UITextGranularityCharacter &&
					[tokenizer respondsToSelector:@selector(positionFromPosition:inDirection:offset:)] &&
					NO) {
					_position = KH_MovePositionDirection(tokenizer, _position, textDirection);
				}
				else {
					_position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, granularity, textDirection);
				}
				
				
				// If I tried to move it and got nothing back reset it to what I had.
				if (!_position){ _position = _position_old; }

				// If I tried to move it a word at a time and nothing happened
				if (granularity == UITextGranularityWord && (KH_positionsSame(privateInputDelegate, currentRange.start, _position) &&
										!KH_positionsSame(privateInputDelegate, privateInputDelegate.beginningOfDocument, _position))) {
				
					_position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, UITextGranularityCharacter, textDirection);
					xMinimum = 4;
				}

				// Another sanity check
				if (!_position || positiveX < xMinimum){
					_position = _position_old;
				}
			}
			
			// Move Y
			// if (positiveY >= yMinimum) {
			// 	UITextPosition *_position_old = _position;

//
			// 	CGRect caretRect = [privateInputDelegate caretRectForPosition:_position];
			//
			// 	CGFloat yDiff = delta.y * 0.8;
			//
			// 	CGPoint newLinePoint = CGPointMake(caretRect.origin.x + (caretRect.size.width * 0.5), caretRect.origin.y + (caretRect.size.height * 0.5) + yDiff);
			// 	newLinePoint = [[privateInputDelegate textInputView] convertPoint:newLinePoint toView:nil];
			// 	_position = [privateInputDelegate closestPositionToPoint:newLinePoint];
			//
			// 	if (!_position){ _position = _position_old; }
			// }
		}

		if (!extendRange && _position) {
			[pivotPoint release], pivotPoint = nil;
			pivotPoint = [_position retain];
		}

		// Get a new text range
		UITextRange *textRange = startingtextRange = nil;
		if ([privateInputDelegate respondsToSelector:@selector(textRangeFromPosition:toPosition:)]) {
			textRange = [privateInputDelegate textRangeFromPosition:pivotPoint toPosition:_position];
		}

		CGPoint oldPrevious = previousPosition;
		// Should I change X?
		if (positiveX > xMinimum) { //|| positiveY > yMinimum) {
			//CGFloat xDiff = ((delta.x < 0) ? (delta.x + xMinimum) : (delta.x - xMinimum));
			//CGPoint accountForLeftOver = CGPointMake(position.x - xDiff, position.y);
			previousPosition = position;
		}

		isFirstShiftDown = NO;
		
		
		
		//
		// Handle Safari's broken UITextInput support
		//
		BOOL webView = [NSStringFromClass([privateInputDelegate class]) isEqualToString:@"WKContentView"];
		if (webView) {
			xOffset += (position.x - realPreviousPosition.x);
			
			if (ABS(xOffset) >= xMinimum) {
				BOOL positive = (xOffset > 0);
				int offset = (ABS(xOffset) / xMinimum);
				
				for (int i = 0; i < offset; i++) {
					[(WKContentView*)privateInputDelegate moveByOffset:(positive ? 1 : -1)];
				}
				
				xOffset += (positive ? -(offset * xMinimum) : (offset * xMinimum));
			}
			[self SS_revealSelection:(UIView*)privateInputDelegate];
		}
		
		
		//
		// Normal text input
		//
		if (textRange && (oldPrevious.x != previousPosition.x || oldPrevious.y != previousPosition.y)) {
			[privateInputDelegate setSelectedTextRange:textRange];
			[self SS_revealSelection:(UIView*)privateInputDelegate];
		}
		
		realPreviousPosition = position;
	}
}

%new
-(void)SS_revealSelection:(UIView*)inputView{
	UIFieldEditor *fieldEditor = [objc_getClass("UIFieldEditor") sharedFieldEditor];
	if (fieldEditor && [fieldEditor respondsToSelector:@selector(revealSelection)]) {
		[fieldEditor revealSelection];
	}
	
	if ([inputView respondsToSelector:@selector(_scrollRectToVisible:animated:)]) {
		if ([inputView respondsToSelector:@selector(caretRect)]) {
			CGRect caretRect = [inputView caretRect];
			[inputView _scrollRectToVisible:caretRect animated:NO];
		}
	}
	else if ([inputView respondsToSelector:@selector(scrollSelectionToVisible:)]) {
		[inputView scrollSelectionToVisible:YES];
	}
}

%end










//
// Code from : @iamharicc
//
// iAmharic <iamharic@gmail.com>
//


static BOOL shiftByOtherKey = NO;
static BOOL isLongPressed = NO;
static BOOL isDeleteKey = NO;
static BOOL isMoreKey = NO;


%hook UIKeyboardLayoutStar
/*==============touchesBegan================*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
//	NSLog(@"key=[%@]  -  keyObject=%@  -  flickDirection = %d", key, keyObject, [(UIKBTree*)keyObject flickDirection]);
	
	
	// Delete key
	if ([key isEqualToString:@"delete"]) {
		isDeleteKey = YES;
	}
	else {
		isDeleteKey = NO;
	}
	
	
	// More key
	if ([key isEqualToString:@"more"]) {
		isMoreKey = YES;
	}
	else {
		isMoreKey = NO;
	}
	
	
	%orig;
}

/*==============touchesMoved================*/
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	
	// Delete key (or the arabic key which is where the shift key would be)
	if ([key isEqualToString:@"delete"] ||
		[key isEqualToString:@"ء"]) {
		shiftByOtherKey = YES;
	}
	
	// More key
	if ([key isEqualToString:@"more"]) {
		isMoreKey = YES;
	}
	else {
		isMoreKey = NO;
	}
	
	
	%orig;
}

-(void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
	%orig(arg1, arg2);
	
	shiftByOtherKey = NO;
	isLongPressed = NO;
	isMoreKey = NO;
}

/*==============touchesEnded================*/
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	%orig;
	
	isDeleteKey = NO;
	
	UITouch *touch = [touches anyObject];
	NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];
	
	
	// Delete key
	if ([key isEqualToString:@"delete"] && !isLongPressed) {
		UIKeyboardImpl *kb = [UIKeyboardImpl activeInstance];
		if ([kb respondsToSelector:@selector(handleDelete)]) {
			[kb handleDelete];
		}
		else if ([kb respondsToSelector:@selector(handleDeleteAsRepeat:)]) {
			[kb handleDeleteAsRepeat:NO];
		}
		else if ([kb respondsToSelector:@selector(handleDeleteWithNonZeroInputCount)]) {
			[kb handleDeleteWithNonZeroInputCount];
		}
	}
	
	
	shiftByOtherKey = NO;
	isLongPressed = NO;
	isMoreKey = NO;
}



// Old approach, keep incase the next one breaks anything
//-(BOOL)isShiftKeyBeingHeld {
//	if (shiftByOtherKey) {
//		return YES;
//	}
//	
//	return %orig;
//}

%new
-(BOOL)SS_shouldSelect{
	return ([self isShiftKeyBeingHeld] || shiftByOtherKey);
}


%new
-(BOOL)SS_disableSwipes{
	return isMoreKey;
}
%end





/*==============UIKeyboardImpl================*/
%hook UIKeyboardImpl

// Doesn't work to get long press on delete key but does for other keys.
-(BOOL)isLongPress {
	isLongPressed = %orig;
	return isLongPressed;
}

// Legacy support (doesn't effect iOS 7 + so harmless leaving in & helps iOS 6)
-(void)handleDelete {
	if (!isLongPressed && isDeleteKey) {
		
	}
	else {
		%orig;
	}
}

-(void)handleDeleteAsRepeat:(BOOL)repeat executionContext:(UIKeyboardTaskExecutionContext*)executionContext{
	// Long press is simply meant to indicate if it's should repeat delete so repeat will do.
	isLongPressed = repeat;
	
	if (!isLongPressed && isDeleteKey) {
		[[executionContext executionQueue] finishExecution];
		return;
	}
	
	%orig;
}


//-(BOOL)handleKeyCommand:(id)arg1 repeatOkay:(BOOL*)arg2{ %log; return %orig; }
%end


