
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@protocol UITextInputPrivate <UITextInput>//, UITextInputTokenizer, UITextInputTraits_Private, UITextSelectingContainer>
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

@interface UIKeyboard : UIView
@end

@interface UIKeyboardImpl : UIView
+(id)sharedInstance;
@property(readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
-(BOOL)isLongPress;
-(id)_layout;
-(BOOL)callLayoutIsShiftKeyBeingHeld;
-(void)_KHKeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;
@end

@interface UIWebDocumentView : UIView {
    id m_parentTextView;
}
-(NSString*)text;
@end

@interface UIFieldEditor : UIView
-(NSRange)selectionRange;
-(void)setSelection:(NSRange)range;
-(NSString*)text;

-(BOOL)keyboardInput:(id)arg1 shouldInsertText:(id)arg2 isMarkedText:(BOOL)arg3;
-(BOOL)keyboardInputShouldDelete:(id)arg1;
-(BOOL)keyboardInputChanged:(id)arg1;
-(void)keyboardInputChangedSelection:(id)arg1;
-(void)selectAll;
-(void)selectionChanged;
@end


@interface KHPanGestureRecognizer : UIPanGestureRecognizer
@end

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
    static CGPoint startPoint;
    static NSRange startRange;
    static NSRange newRange;
    static BOOL shiftHeldDown = NO;
    static int numberOfTouches = 0;
    static BOOL hasStarted = NO;
    static BOOL longPress = NO;

    int touchesCount = [gesture numberOfTouches];
    if (touchesCount > numberOfTouches) {
        numberOfTouches = touchesCount;
    }

    Class webDocumentViewClass = %c(UIWebDocumentView);
    Class textFieldClass = %c(UIFieldEditor);

    UIKeyboardImpl *keyboardImpl = self;//[%c(UIKeyboardImpl) sharedInstance];

    id currentLayout = nil;
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }

    if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
        BOOL nLongTouch = [keyboardImpl isLongPress];
        if (nLongTouch) {
            longPress = nLongTouch;
        }
    }

    // Is UIKeyboardLayoutEmoji_iPhone or UIKeyboardLayoutEmoji_iPad actually.
    Class emojiLayoutClass = %c(UIKeyboardLayoutEmoji);
    // Hence use of isKindOfClass:
    if ([currentLayout isKindOfClass:emojiLayoutClass]) {
        return;
    }


    if ([keyboardImpl respondsToSelector:@selector(callLayoutIsShiftKeyBeingHeld)] && !shiftHeldDown) {
        shiftHeldDown = [keyboardImpl callLayoutIsShiftKeyBeingHeld];
    }

    id <UITextInputPrivate, NSObject, NSCoding> privateInputDelegate = nil;
    if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
        privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
    }

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        shiftHeldDown = NO;
        longPress = NO;
        hasStarted = NO;
        numberOfTouches = 0;
        gesture.cancelsTouchesInView = NO;
    }
    else if (longPress) {
        return;
    }
    else if (gesture.state == UIGestureRecognizerStateBegan) {
        startPoint = [gesture locationInView:self];

        if (privateInputDelegate) {
            if ([privateInputDelegate isKindOfClass:textFieldClass]) {
                UIFieldEditor *textField = (UIFieldEditor*)privateInputDelegate;
                if ([textField respondsToSelector:@selector(selectionRange)]) {
                    startRange = [textField selectionRange];
                }
            }
            else if ([privateInputDelegate isKindOfClass:webDocumentViewClass]) {
                UITextView *textView = MSHookIvar<UITextView *>(privateInputDelegate, "m_parentTextView");
                
                if (textView) {
                    if ([textView respondsToSelector:@selector(selectedRange)]) {
                        startRange = [textView selectedRange];
                    }
                }
            }
        }
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		CGPoint offset = [gesture translationInView:self];

        if (!hasStarted && offset.x < 5 && offset.x > -5) {
            return;
        }
        gesture.cancelsTouchesInView = YES;
        hasStarted = YES;

        int scale = 16;
        if (numberOfTouches >= 2) {
            scale = 8; // make it go faster
        }

        // Get caracters back it should go
        int pointsChanged = offset.x / scale;
        int newLocation = startRange.location;
        int newLength = startRange.length;

        // Get total length of text
        int textLength = -1;
        if ([privateInputDelegate respondsToSelector:@selector(text)]) {
            NSString *text = [(UIFieldEditor*)privateInputDelegate text];
            if ([text respondsToSelector:@selector(length)]) {
                textLength = [text length];
            }
        }

        if (shiftHeldDown) {
            if (pointsChanged > 0) {
                newLength += pointsChanged;
                
                if ((newLength + newLocation) > textLength) {
                    newLength = textLength - newLocation;
                }
            }
            else {
                newLocation += pointsChanged;
                newLength -= pointsChanged;

                int startPosition = newLocation + newLength;
                if (newLocation < 0) {
                    newLocation = 0;
                    newLength = startPosition;
                }
            }
        }
        else {
            newLength = 0;
            newLocation += pointsChanged;

            if (newLocation > textLength) {
                newLocation = textLength;
            }
            else if (newLocation < 0) {
                newLocation = 0;
            }
        }

        newRange = NSMakeRange(newLocation, newLength);

		if (privateInputDelegate) {
            if ([privateInputDelegate isKindOfClass:textFieldClass]) {
                UIFieldEditor *textField = (UIFieldEditor*)privateInputDelegate;
                if ([textField respondsToSelector:@selector(setSelection:)]) {
                    [textField setSelection:newRange];
                }
            }
            else if ([privateInputDelegate isKindOfClass:webDocumentViewClass]) {
                UITextView *textView = MSHookIvar<UITextView *>(privateInputDelegate, "m_parentTextView");
                if (textView) {
                    if ([textView respondsToSelector:@selector(setSelectedRange:)]) {
                        [textView setSelectedRange:newRange];
                    }
                }
            }
        }
	}
}

%end

@implementation KHPanGestureRecognizer
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer{
    UIKeyboardImpl *keyboardImpl = [%c(UIKeyboardImpl) sharedInstance];
    id currentLayout = nil;
    BOOL longPress = NO;
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }
    if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
        longPress = [keyboardImpl isLongPress];
    }
    
    // Is UIKeyboardLayoutEmoji_iPhone or UIKeyboardLayoutEmoji_iPad actually.
    Class emojiLayoutClass = %c(UIKeyboardLayoutEmoji);
    // Hence use of isKindOfClass:
    if ([currentLayout isKindOfClass:emojiLayoutClass] || longPress) {
        return NO;
    }

    return [super canPreventGestureRecognizer:gestureRecognizer];
}
@end
