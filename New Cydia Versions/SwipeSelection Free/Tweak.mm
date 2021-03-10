// **************************************************** //
// **************************************************** //
// *********       SwipeSelection Pro         ********* //
// **************************************************** //
// **************************************************** //




#import "Header.h"
#import "SSPanGestureRecognizer.h"










#pragma mark - Psudo Properties

//
// Property:
//	NSString *firstKey
//
static NSString *_firstKey = nil;
NSString *firstKey(){
	return _firstKey;
}
void setFirstKey(NSString *_firstKey_){
	[_firstKey release];
	_firstKey = nil;
	
	_firstKey = [_firstKey_ copy];
}



//
// Property:
//	UITextRange *startTextRange
//
static UITextRange *_startTextRange = nil;
UITextRange *startTextRange(){
	return _startTextRange;
}
void setStartTextRange(UITextRange *_startTextRange_){
	[_startTextRange release];
	_startTextRange = nil;
	
	_startTextRange = [_startTextRange_ retain];
}














#pragma mark - Helper Functions


BOOL isDeleteKey(){
	return [firstKey() isEqualToString:@"delete"];
}

BOOL isASelectionKey(){
	BOOL _isASelectionKey = NO;
	
	NSString *key = firstKey();
	
	SET_IF_TRUE([key isEqualToString:@"delete"], _isASelectionKey);
	SET_IF_TRUE([key isEqualToString:@"shift"], _isASelectionKey);
	SET_IF_TRUE([key isEqualToString:@"ء"], _isASelectionKey);
	
	return _isASelectionKey;
}

BOOL isADontRunKey(){
	BOOL _isADontRunKey = NO;
	
	NSString *key = firstKey();
	
	SET_IF_TRUE([key isEqualToString:@"more"], _isADontRunKey);
	SET_IF_TRUE([key isEqualToString:@"international"], _isADontRunKey);
	
	
	
	// Get the swipeable area
	SSSwipeableArea swipeArea = [SSKHSettingsController swipeableArea];
	
	// Check if we have to avoid the spacebar
	if (swipeArea == SSSwipeAvoidSpacebar) {
		SET_IF_TRUE([key isEqualToString:@" "], _isADontRunKey);
	}
	else if (swipeArea == SSSwipeOnlySpaceBar) {
		BOOL spacebarkey = [key isEqualToString:@" "];
		BOOL isSelectionKey = isASelectionKey();
		
		// Check if we have to avoid everything but the spacebar
		SET_IF_TRUE(((spacebarkey == NO) && (isSelectionKey == NO)), _isADontRunKey);
	}
	
	
	return _isADontRunKey;
}

//
// [kb _getCurrentKeyboardName];
// @"Wildcat-Landscape-QWERTY"
// @"Wildcat-Landscape-QWERTY-Spanish"
// @"Wildcat-Landscape-Emoji"
// @"Wildcat-Landscape-Kana"
//


















#pragma mark - Hooks


@interface UIKeyboardImpl(Added)
-(void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture;

-(CGFloat)SS_offsetPerMoveForSpeed:(SSSwipeSpeed)speed;
-(CGFloat)SS_DeadzoneForSensitivity:(SSSwipeSensitivity)sensitivity;

-(BOOL)SS_KeyboardIsHandwriting:(UIKeyboardLayout*)layout;
-(BOOL)SS_InputIsBlackListed:(id <UITextInput>)textInput;

-(void)SS_SetTextRange:(UITextRange*)textRange inInputView:(id <UITextInput>)textInput;
-(void)SS_SetSelectedTextRange:(UITextRange*)textRange inInputView:(id <UITextInput>)textInput;

-(void)SS_ScrollInputViewInputView:(id <UITextInput>)textInput toSelectedTextRange:(UITextRange*)textRange;
-(void)SS_ShowMenuControllerForInputView:(id <UITextInput>)textInput withTextRange:(UITextRange*)textRange;
@end






/*==============UIKeyboardImpl================*/
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



// Fix: for SwipeExpander canceling touches an SS not knowing what to do
static BOOL active = NO;

%new
-(void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer*)gesture{
	//
	// Declare Variables
	//
    UIKeyboardImpl *keyboardImpl = self;
    UIKeyboardLayout *currentLayout = nil;
	id <UITextInput> inputDelegate = nil;
	
	static BOOL hasStarted = NO;
	static BOOL cancelled = NO;
	static CGPoint startPoint = CGPointZero;
	
	// WebView
	static CGFloat xOffset = 0;
	
	
	
	
	//
	// Initial Setup
	//
	inputDelegate = [keyboardImpl inputDelegate];
	
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }
	
	
	// Cancel if it's the handwriting keyboard, or a long press, or if we shouldn't run anyway.
	SET_IF_TRUE([self SS_KeyboardIsHandwriting:currentLayout], cancelled);
	SET_IF_TRUE([keyboardImpl isLongPress], cancelled);
	SET_IF_TRUE(isADontRunKey(), cancelled);
	// Check if settings say we should even run?
	SET_IF_TRUE(([SSKHSettingsController enabled] == NO), cancelled);
	
	
	
	//
	// Check for super buggy custom text views.
	//
	if (inputDelegate != nil && !cancelled && [self SS_InputIsBlackListed:inputDelegate])
	{
		inputDelegate = nil;
		cancelled = YES;
	}
	
	
	
	
	//
	// Gesture Recognizer statements.
	//
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
	{
		if (hasStarted)
		{
			// Show the UIMenuController if we selected some text
			UITextRange *textRange = [inputDelegate selectedTextRange];
			if (textRange && !textRange.empty) {
				[self SS_ShowMenuControllerForInputView:inputDelegate withTextRange:textRange];
			}
			
			// Update selection
			if ([keyboardImpl respondsToSelector:@selector(updateForChangedSelection)]) {
				[keyboardImpl updateForChangedSelection];
			}
		}
		
		
		// Clear things back to default
		hasStarted = NO;
		cancelled = NO;
		
		active = NO;
		
		setFirstKey(nil);
		gesture.cancelsTouchesInView = NO;
		
		
		//TODO: block incompatibile keyboards, such as 10 key.
	}
	else if (!inputDelegate || cancelled) {
		return;
	}
	else if (gesture.state == UIGestureRecognizerStateBegan) {
		active = YES;
		//
		// Where are we when we start?
		//
		startPoint = [gesture locationInView:self];
		setStartTextRange([inputDelegate selectedTextRange]);
		
		xOffset = 0;
		
		// What needs to be checked before we start
		
		/* Currently nothing, maybe move handwriting check in if we can find anything to go with it*/
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		//
		// Current selection range and distance finger has moved since the start.
		// ...maybe make it work like a track pad, use delta and take into account velocity?
		//
		
		// Speed cached for performance reasons
		static SSSwipeSpeed speed = SSSwipeSpeedNormal;
		
		
		static UITextPosition *pivotPosition = nil;
		static UITextPosition *startPosition = nil;
		
		static CGPoint previousPoint = CGPointZero;
		static CGPoint currentPoint = CGPointZero;
		
		static BOOL isSelection = NO;
		
		// Current position
		CGPoint position = [gesture locationInView:self];
		CGPoint difference = CGPointMake(position.x - startPoint.x, position.y - startPoint.y);
		
		
		
		
		
		
		
		
		
		//
		// Should we even run?
		//
		
		// Deadzone checks
		CGFloat deadZone = [self SS_DeadzoneForSensitivity:[SSKHSettingsController swipeSensitivity]];
		
		// If we are smaller than the deadzone (and haven't started) don't run.
		if (KH_POSITIVE(difference.x) < deadZone && !hasStarted) {
			return;
		}
		
		
		
		
		// Make x & y positive for comparision
		CGFloat positiveX = KH_POSITIVE(difference.x);
		CGFloat positiveY = KH_POSITIVE(difference.y);
		
		// Disable if swiping vertically
		if (positiveY > positiveX && !hasStarted) {
			cancelled = YES;
			return;
		}
		
		
		
		
		
		
		
		
		
		
		
		//
		// We are running so shut other things off/down
		// And set ourselves up
		//
		if (!hasStarted) {
			gesture.cancelsTouchesInView = YES;
			hasStarted = YES;
			
			// Set the start points.
			startPoint = position;
			previousPoint = startPoint;
			
			// Reset our movement to 0
			currentPoint = CGPointZero;
			
			
			isSelection = isASelectionKey();
			speed = [SSKHSettingsController swipeSpeed];
			
			
			
			
			//
			// Text position details
			//
			
			// Default to nil
			UITextPosition *pivot = nil;
			UITextPosition *start = nil;
			
			UITextRange *_startTextRange = startTextRange();
			
			
			if (isSelection) {
				// Moving finger from left to right
				if (difference.x > 0) {
					// Extend the right hand edge and keep the left as the pivot
					pivot = _startTextRange.start;
				}
				else {
					// Finger moving right to left, move the start and keep the end.
					pivot = _startTextRange.end;
				}
			}
			
			
			// Regardless of selection we want to start from the same place
			if (difference.x > 0) {
				// If moving right, start from the right most point
				start = _startTextRange.end;
			}
			else {
				// If moving left start from the eariliest point.
				start = _startTextRange.start;
			}
			
			
			// Setup the start and pivot points
			[pivotPosition release], pivotPosition = nil;
			pivotPosition = [pivot retain];
			
			[startPosition release], startPosition = nil;
			startPosition = [start retain];
		}
		
		
		
		//
		// Check for 3 finger swipe
		//
		if ([SSKHSettingsController threeFingerSwipe] && gesture.numberOfTouches >= 3) {
			UITextPosition *position = nil;
			
			// If moving right we want to go to the end of the document
			if (difference.x > 0) {
				position = inputDelegate.endOfDocument;
			}
			else {
				position = inputDelegate.beginningOfDocument;
			}
			
			UITextRange *textRange = [inputDelegate textRangeFromPosition:position toPosition:position];
			[self SS_SetSelectedTextRange:textRange inInputView:inputDelegate];
			
			cancelled = YES;
			return;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		//
		// Get the current offset for the touch movement
		//
		
		// Do our veloicty stuff
		CGFloat diffX = (position.x - previousPoint.x);
		CGFloat diffY = (position.x - previousPoint.x);
		
		// Move the point we are working with.
		currentPoint.x += diffX ;//+ (diffX * (velocityX * 0.75f));
		currentPoint.y += diffY ;//+ (diffY * (velocityY * 0.75f));
		
		
		
		
		// Get the offset for the current point
		CGFloat offsetPerMove = [self SS_offsetPerMoveForSpeed:speed];
		CGFloat offset = currentPoint.x / offsetPerMove;
		// Make it an int
		NSInteger offsetX = offset;
		
		
		UITextLayoutDirection textDirection = UITextLayoutDirectionRight;
		if (offsetX < 0) {
			textDirection = UITextLayoutDirectionLeft;
			offsetX = -offsetX;
		}
		
		
		
		
		
		
		
		
		
		
		
		// Get the 2 positions
//		UITextPosition *positionOne = [inputDelegate positionFromPosition:startPosition offset:offsetX];
		UITextPosition *positionOne = [inputDelegate positionFromPosition:startPosition inDirection:textDirection offset:offsetX];
		UITextPosition *positionTwo = pivotPosition;
		
		
		//
		// nil check
		// -positionFromPosition:offset: is allowed to return nil, check for it
		//
		static UITextPosition *currentPosition = nil;
		
		if (positionOne == nil) {
			// If we moved right and didn't get an answer we probably overran. Move to the end of the document
			if (offset > 0) {
				positionOne = inputDelegate.endOfDocument;
			}
			else {
				positionOne = inputDelegate.beginningOfDocument;
			}
		}
		else {
			[currentPosition release], currentPosition = nil;
			currentPosition = [positionOne retain];
		}
		
		
		
		//
		// Check for not selecting text
		//
		if (positionTwo == nil) {
			positionTwo = positionOne;
		}
		
		
		// TODO: DeleteWord letters staying pressed bug?
		// TODO: UITextLayoutDirection has an up & down too!!!!
		
		
		
		
		
		
		//
		// Get a new text range
		//
		UITextRange *textRange = [inputDelegate textRangeFromPosition:positionOne toPosition:positionTwo];
		
		
		//
		// Handle Safari's broken UITextInput support
		//
		BOOL webView = [NSStringFromClass([inputDelegate class]) isEqualToString:@"WKContentView"];
		if (webView) {
			xOffset += (position.x - previousPoint.x);
			
			if (ABS(xOffset) >= offsetPerMove) {
				BOOL positive = (xOffset > 0);
				int offset = (ABS(xOffset) / offsetPerMove);
				
				for (int i = 0; i < offset; i++) {
					[(WKContentView*)inputDelegate moveByOffset:(positive ? 1 : -1)];
				}
				
				xOffset += (positive ? -(offset * offsetPerMove) : (offset * offsetPerMove));
			}
		}
		
		
		//
		// Set the new text range & scroll it visible
		//
		[self SS_SetSelectedTextRange:textRange inInputView:inputDelegate];
		
		
		
		
		// Set it so we have it for next time around
		previousPoint = position;
	}
}

%new
-(CGFloat)SS_offsetPerMoveForSpeed:(SSSwipeSpeed)speed{
	CGFloat pointsPerOffsetMovement = 9.0f;
	
	if (speed == SSSwipeSpeedSlowest){
		pointsPerOffsetMovement = 15.0f;
	}
	else if (speed == SSSwipeSpeedSlower){
		pointsPerOffsetMovement = 11.0f;
	}
	else if (speed == SSSwipeSpeedNormal){
		pointsPerOffsetMovement = 9.0f;
	}
	else if (speed == SSSwipeSpeedFaster){
		pointsPerOffsetMovement = 7.0f;
	}
	else if (speed == SSSwipeSpeedFastest){
		pointsPerOffsetMovement = 5.0f;
	}
	
	return pointsPerOffsetMovement;
}

%new
-(CGFloat)SS_DeadzoneForSensitivity:(SSSwipeSensitivity)swipeSensitivity{
	CGFloat deadzone = 18.0f;
	BOOL isiPAD = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	
	
	if (swipeSensitivity == SSSwipeSensitivityNormal){
		deadzone = (isiPAD ? 30.0f : 18.0f);
	}
	else if (swipeSensitivity == SSSwipeSensitivityReduced){
		deadzone = (isiPAD ? 45.0f : 26.0f);
	}
	else if (swipeSensitivity == SSSwipeSensitivityInsensitive) {
		deadzone = (isiPAD ? 55.0f : 38.0f);
	}
	
	return deadzone;
}










//
// Check methods
//
%new
-(BOOL)SS_KeyboardIsHandwriting:(UIKeyboardLayout*)layout{
	BOOL isHandwriting = NO;
	
	//
	// Hand writing recognition
	//
    if ([layout respondsToSelector:@selector(handwritingPlane)]) {
        isHandwriting = [(UIKeyboardLayoutStar*)layout handwritingPlane];
	}
	
	return isHandwriting;
}

%new
-(BOOL)SS_InputIsBlackListed:(id <UITextInput>)textInput{
	NSString *classString = NSStringFromClass([textInput class]);
	
	//
	// Viber custom text view crashes
	//
	if ([classString isEqualToString:@"VBEmoticonsContentTextView"]) {
		return YES;
	}
	
	return NO;
}







//
// Controller methods
//
%new
-(void)SS_SetSelectedTextRange:(UITextRange*)textRange inInputView:(id <UITextInput>)textInput{
	if (textRange != nil && textInput != nil) {
		[self SS_SetTextRange:textRange inInputView:textInput];
		[self SS_ScrollInputViewInputView:textInput toSelectedTextRange:textRange];
	}
}




%new
-(void)SS_SetTextRange:(UITextRange*)textRange inInputView:(id <UITextInput>)textInput{
	[textInput setSelectedTextRange:textRange];
}


%new
-(void)SS_ScrollInputViewInputView:(id <UITextInput>)textInput toSelectedTextRange:(UITextRange*)textRange{
	UIFieldEditor *fieldEditor = [objc_getClass("UIFieldEditor") sharedFieldEditor];
	if (fieldEditor && [fieldEditor respondsToSelector:@selector(revealSelection)]) {
		[fieldEditor revealSelection];
	}
	
	if ([textInput respondsToSelector:@selector(_scrollRectToVisible:animated:)]) {
		if ([textInput respondsToSelector:@selector(caretRect)]) {
			CGRect caretRect = [(UIView*)textInput caretRect];
			[(UIView*)textInput _scrollRectToVisible:caretRect animated:YES];
		}
	}
	else if ([textInput respondsToSelector:@selector(scrollSelectionToVisible:)]) {
		[(UIView*)textInput scrollSelectionToVisible:YES];
	}
}


%new
-(void)SS_ShowMenuControllerForInputView:(id <UITextInput>)textInput withTextRange:(UITextRange*)textRange{
	CGRect screenBounds = [UIScreen mainScreen].bounds;
	CGRect rect = CGRectMake(screenBounds.size.width * 0.5, screenBounds.size.height * 0.5, 1, 1);
	
	rect = [textInput firstRectForRange:textRange];
	
	UIView *view = [textInput textInputView];
	
	UIMenuController *menu = [UIMenuController sharedMenuController];
	[menu setTargetRect:rect inView:view];
	[menu setMenuVisible:YES animated:YES];
}










static BOOL isLongPressed = NO;

// Doesn't work to get long press on delete key but does for other keys.
-(BOOL)isLongPress {
	isLongPressed = %orig;
	return isLongPressed;
}

// Legacy support (doesn't effect iOS 7 + so harmless leaving in & helps iOS 6)
-(void)handleDelete {
	if (!isLongPressed && isDeleteKey()) {
		
	}
	else {
		%orig;
	}
}

-(void)handleDeleteAsRepeat:(BOOL)repeat executionContext:(UIKeyboardTaskExecutionContext*)executionContext{
	// Long press is simply meant to indicate if it's should repeat delete so repeat will do.
	isLongPressed = repeat;
	
	if (!isLongPressed && isDeleteKey()) {
		[[executionContext executionQueue] finishExecution];
		return;
	}
	
	%orig;
}

%end
































static CGFloat tripleTapTime = 1.0f;

static int tapCount = 0;
static CFAbsoluteTime firstTapTime = 0;

void keyPressStart(NSString *key){
	if ([key isEqualToString:@"shift"] && [SSKHSettingsController tripleTapToggles])
	{
		CFAbsoluteTime currentTapTime = CFAbsoluteTimeGetCurrent();
		
		// If move than 3 seconds has past than reset
		if ((currentTapTime - tripleTapTime) > firstTapTime) {
			tapCount = 0;
			firstTapTime = currentTapTime;
		}
		
		tapCount++;
		
		
		if (tapCount >= 3) {
			// This will cause the next tap to reset us
			firstTapTime = 0;
			
			// Toggle enabled/disabled
			[SSKHSettingsController setEnabled:![SSKHSettingsController enabled]];
		}
	}
}







%hook UIKeyboardLayoutStar

/*==============touchesBegan================*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	UIKBTree *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];
	
	// To allow people to tap and hold on the shift key and then swipe with their other finger
	if (firstKey() == nil) {
		setFirstKey(key);
		keyPressStart(key);
	}
	
	%orig;
}
/*============touchesCancelled==============*/
-(void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
	%orig(arg1, arg2);
	
	isLongPressed = NO;
	
	
	// If we were canceled before we start firstKey() is a junk value we need to clear out
	if (!active) {
		setFirstKey(nil);
	}
}
/*==============touchesEnded================*/
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	%orig;
	
	UITouch *touch = [touches anyObject];
	NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];
	
	setFirstKey(nil);
	
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
	
	isLongPressed = NO;
}

%end



