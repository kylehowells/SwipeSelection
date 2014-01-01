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


#pragma mark - Headers
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

// ?
-(CGRect)caretRect;
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
@end

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

@interface UIKeyboardLayout : UIView
-(UIKBKey*)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
-(BOOL)_disableSwipes;
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
-(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
-(void)handleDelete;
-(void)handleDeleteAsRepeat:(BOOL)repeat;
-(void)handleDeleteWithNonZeroInputCount;
-(void)stopAutoDelete;
-(BOOL)handwritingPlane;
@end

@interface UIFieldEditor : NSObject
+(UIFieldEditor*)sharedFieldEditor;
-(void)revealSelection;
@end

@interface UIWebDocumentView : UIView
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
-(void)scrollSelectionToVisible:(BOOL)visible;
@end

@interface UIView(Private_text) <UITextInput>
-(NSRange)selectedRange;
-(NSRange)selectionRange;
-(void)setSelectedRange:(NSRange)range;
-(void)setSelectionRange:(NSRange)range;
-(void)scrollSelectionToVisible:(BOOL)arg1;
-(CGRect)rectForSelection:(NSRange)range;
-(CGRect)textRectForBounds:(CGRect)rect;
@end




#pragma mark - Helper functions
UITextPosition *KH_tokenizerMovePositionWithGranularitInDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextGranularity granularity, UITextDirection direction);
UITextPosition *KH_tokenizerMovePositionWithGranularitInDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextGranularity granularity, UITextDirection direction){

    if (tokenizer && startPosition) {
        return [tokenizer positionFromPosition:startPosition toBoundary:granularity inDirection:direction];
    }

    return nil;
}
BOOL KH_positionsSame(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *position1, UITextPosition *position2);
BOOL KH_positionsSame(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *position1, UITextPosition *position2){
    return ([tokenizer comparePosition:position1 toPosition:position2] == NSOrderedSame);
}


#pragma mark - GestureRecognizer
@interface KHPanGestureRecognizer : UIPanGestureRecognizer
@end


#pragma mark - Hooks
%hook UIKeyboardImpl

-(id)initWithFrame:(CGRect)rect{
    id orig = %orig;

    if (orig){
        KHPanGestureRecognizer *pan = [[KHPanGestureRecognizer alloc] initWithTarget:self action:@selector(_KHKeyboardGestureDidPan:)];
        pan.cancelsTouchesInView = NO;
        [self addGestureRecognizer:pan];
        [pan release];
    }

    return orig;
}

%new
-(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture{

    // Location info (may change)
    static UITextRange *startingtextRange = nil;
    static CGPoint previousPosition;

    // Basic info
    static BOOL shiftHeldDown = NO;
    static BOOL hasStarted = NO;
    static BOOL longPress = NO;
    static BOOL handWriting = NO;
    static BOOL haveCheckedHand = NO;
    static BOOL isFirstShiftDown = NO;
	static BOOL isMoreKey = NO;
    static int touchesWhenShiting = 0;

    int touchesCount = [gesture numberOfTouches];

    UIKeyboardImpl *keyboardImpl = self; //[%c(UIKeyboardImpl) sharedInstance];

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
	
	if ([currentLayout respondsToSelector:@selector(_disableSwipes)] && !isMoreKey) {
		isMoreKey = [currentLayout _disableSwipes];
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


    if ([keyboardImpl respondsToSelector:@selector(callLayoutIsShiftKeyBeingHeld)] && !shiftHeldDown) {
        shiftHeldDown = [keyboardImpl callLayoutIsShiftKeyBeingHeld];
        isFirstShiftDown = YES;
        touchesWhenShiting = touchesCount;
    }

    id <UITextInputPrivate, NSObject, NSCoding> privateInputDelegate = nil;
    if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
        privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
    }
    if (!privateInputDelegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
        privateInputDelegate = (id)keyboardImpl.inputDelegate;
    }

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
            UITextRange *range = [privateInputDelegate selectedTextRange];
            if (range && !range.empty) {
                CGRect screenBounds = [UIScreen mainScreen].bounds;
                CGRect rect = CGRectMake(screenBounds.size.width * 0.5, screenBounds.size.height*0.5, 1, 1);

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
                

                UIMenuController *menu = [UIMenuController sharedMenuController];
                [menu setTargetRect:rect inView:view];
                [menu setMenuVisible:YES animated:YES];
            }
        }

		shiftHeldDown = NO;
		isMoreKey = NO;
		longPress = NO;
		hasStarted = NO;
		handWriting = NO;
		haveCheckedHand = NO;

        touchesCount = 0;
        touchesWhenShiting = 0;
        gesture.cancelsTouchesInView = NO;
    }
    else if (longPress || handWriting || !privateInputDelegate || isMoreKey) {
        return;
    }
    else if (gesture.state == UIGestureRecognizerStateBegan) {
        previousPosition = [gesture locationInView:self];

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
        if (!hasStarted && delta.x < deadZone && delta.x > (-deadZone)) {
			return;
		}
		
        // We are running so shut other things off/down
        gesture.cancelsTouchesInView = YES;
        hasStarted = YES;

        // Make x & y positive for comparision
        CGFloat positiveX = ((delta.x >= 0) ? delta.x : (-delta.x));
//        CGFloat positiveY = ((delta.y >= 0) ? delta.y : (-delta.y));

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
//        CGFloat yMinimum = 1;

        CGFloat neededTouches = 2;
        if (shiftHeldDown && (touchesWhenShiting >= 2)) {
            neededTouches = 3;
        }

        UITextGranularity granularity = UITextGranularityCharacter;
        // Handle different touches
        if (touchesCount >= neededTouches) {
            // make it skip words
            granularity = UITextGranularityWord;
            xMinimum = 26;
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


        id <UITextInputTokenizer> tokenizer = nil;
        if ([privateInputDelegate respondsToSelector:@selector(positionFromPosition:toBoundary:inDirection:)]) {
            tokenizer = privateInputDelegate;
        }
        else if ([privateInputDelegate respondsToSelector:@selector(tokenizer)]) {
            tokenizer = privateInputDelegate.tokenizer;
        }

        if (tokenizer) {
            // Move X
            if (positiveX >= 1) {
                UITextPosition *_position_old = _position;

                _position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, granularity, textDirection);
                
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
//            if (positiveY >= yMinimum) {
//                UITextPosition *_position_old = _position;
//
//                CGRect caretRect = [privateInputDelegate caretRectForPosition:_position];
//
//                CGFloat yDiff = delta.y * 0.8;
//
//                CGPoint newLinePoint = CGPointMake(caretRect.origin.x + (caretRect.size.width * 0.5), caretRect.origin.y + (caretRect.size.height * 0.5) + yDiff);
//                newLinePoint = [[privateInputDelegate textInputView] convertPoint:newLinePoint toView:nil];
//                _position = [privateInputDelegate closestPositionToPoint:newLinePoint];
//
//                if (!_position){ _position = _position_old; }
//            }
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

        if (textRange && (oldPrevious.x != previousPosition.x || oldPrevious.y != previousPosition.y)) {
            [privateInputDelegate setSelectedTextRange:textRange];
			
			UIFieldEditor *fieldEditor = [objc_getClass("UIFieldEditor") sharedFieldEditor];
			if (fieldEditor && [fieldEditor respondsToSelector:@selector(revealSelection)]) {
				[fieldEditor revealSelection];
			}
			
			if ([privateInputDelegate respondsToSelector:@selector(_scrollRectToVisible:animated:)]) {
				if ([privateInputDelegate respondsToSelector:@selector(caretRect)]) {
					CGRect caretRect = [privateInputDelegate caretRect];
					[privateInputDelegate _scrollRectToVisible:caretRect animated:NO];
				}
			}
			else if ([privateInputDelegate respondsToSelector:@selector(scrollSelectionToVisible:)]) {
				[(UIView*)privateInputDelegate scrollSelectionToVisible:YES];
			}
        }
	}
}

%end


#pragma mark - GestureRecognizer implementation
@implementation KHPanGestureRecognizer
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
    if ([preventingGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }

    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer{
    return NO;
}
@end




//
// Code from : @iamharicc
//
// iAmharic <iamharic@gmail.com>
//


static BOOL shiftByDelete = NO;
static BOOL isLongPressed = NO;
static BOOL isDeleteKey = NO;
static BOOL isMoreKey = NO;


%hook UIKeyboardLayoutStar
/*==============touchesBegan================*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];
	
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
	NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];
	
	// Delete key
	if ([key isEqualToString:@"delete"]) {
		shiftByDelete = YES;
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
	
	shiftByDelete = NO;
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
	
	
	shiftByDelete = NO;
	isLongPressed = NO;
	isMoreKey = NO;
}

-(BOOL)isShiftKeyBeingHeld {
	if (shiftByDelete) {
		return YES;
	}
	
	return %orig;
}

%new
-(BOOL)_disableSwipes{
	return isMoreKey;
}
%end


/*==============UIKeyboardImpl================*/
%hook UIKeyboardImpl
-(BOOL)isLongPress {
	isLongPressed = %orig;
	return isLongPressed;
}

-(void)handleDelete {
	if (!isLongPressed && isDeleteKey) {
		
	}
	else {
		%orig;
	}
}
%end
