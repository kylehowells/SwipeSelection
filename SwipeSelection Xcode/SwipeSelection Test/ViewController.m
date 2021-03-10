//
//  ViewController.m
//  SwipeSelection Test
//
//  Created by Kyle Howells on 24/02/2017.
//  Copyright © 2017 Kyle Howells. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) IBOutlet UITextView *textView;
@end


@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidChangeFrameNotification object:nil];
}


-(void)keyboardFrameChanged:(NSNotification*)notification {
	NSDictionary *info = [notification userInfo];
	NSValue *kbFrameValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect kbFrame = kbFrameValue.CGRectValue;
	
	NSLog(@"Rect: %@", NSStringFromCGRect( kbFrame ));
	
	CGRect frameOverlap = [self.textView convertRect:kbFrame fromView:nil];
	
	UIEdgeInsets contentInset = self.textView.contentInset;
	contentInset.bottom = MAX(self.textView.frame.size.height - frameOverlap.origin.y, 0);
	self.textView.contentInset = contentInset;
}

@end
