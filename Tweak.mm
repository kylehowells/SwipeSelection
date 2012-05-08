
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface DOMNode : NSObject
@end

@interface UIThreadSafeNode : NSObject {
	DOMNode *_node; 
}
-(id)_realNode;
@end

@interface DOMHTMLInputElement : NSObject
-(NSString*)text;

-(void)setSelectionRange:(int)start end:(int)end;
-(void)setSelectionEnd:(int)arg1;
-(int)selectionEnd;
-(void)setSelectionStart:(int)arg1;
-(int)selectionStart;
@end

@interface DOMHTMLTextAreaElement : NSObject
-(NSString*)text;

-(void)setSelectionRange:(int)start end:(int)end;
-(void)setSelectionEnd:(int)arg1;
-(int)selectionEnd;
-(void)setSelectionStart:(int)arg1;
-(int)selectionStart;
@end


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

    // Location info (may change)
    static CGPoint startPoint;
    static NSRange startRange;
    static NSRange newRange;

    // Basic info
    static BOOL shiftHeldDown = NO;
    static int numberOfTouches = 0;
    static BOOL hasStarted = NO;
    static BOOL longPress = NO;
    static BOOL handWriting = NO;

    int touchesCount = [gesture numberOfTouches];
    if (touchesCount > numberOfTouches) {
        numberOfTouches = touchesCount;
    }

    Class webDocumentViewClass = %c(UIWebDocumentView);
    Class textFieldClass = %c(UIFieldEditor);
    Class threadSafeNode = %c(UIThreadSafeNode);

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
    // Chinese handwriting check - (hacky)
    if ([currentLayout respondsToSelector:@selector(subviews)] && !handWriting) {
        unsigned index = 1;
        NSArray *subviews = ((UIView*)currentLayout).subviews;
        if ([subviews count] > index) {
            UIView *subview = [subviews objectAtIndex:index];

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
        handWriting = NO;
    }
    else if (longPress || handWriting) {
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
            else if ([privateInputDelegate isKindOfClass:threadSafeNode]) {
                DOMHTMLInputElement *textView = privateInputDelegate;

                int start = 0;
                if ([textView respondsToSelector:@selector(selectionStart)]) {
                    start = [textView selectionStart];
                }

                int end = 0;
                if ([textView respondsToSelector:@selector(selectionEnd)]) {
                    end = [textView selectionEnd];
                }

                startRange = NSMakeRange(start, (end - start));
            }
        }
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		CGPoint offset = [gesture translationInView:self];

        if (!hasStarted && offset.x < 8 && offset.x > -8) {
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
            else if ([privateInputDelegate isKindOfClass:threadSafeNode]) {
                DOMHTMLInputElement *textView = privateInputDelegate;

                if ([textView respondsToSelector:@selector(setSelectionStart:)]) {
                    [textView setSelectionStart:newRange.location];
                }
                if ([textView respondsToSelector:@selector(setSelectionEnd:)]) {
                    [textView setSelectionEnd:(newRange.location + newRange.length)];
                }
            }
        }
	}
}

%end

@implementation KHPanGestureRecognizer
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
    if ([preventingGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }

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
