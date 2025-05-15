//
//  VGViewController.h
//
//  Created by Vlad Getman on 19.07.14.
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VGViewController : UIViewController <UIGestureRecognizerDelegate> {
    UITapGestureRecognizer *closeGesture;
}

- (void)kbWasShown:(NSNotification*)notification;
- (void)kbWillBeHidden:(NSNotification*)notification;
- (void)kbWillChangeFrame:(NSNotification*)notification;
- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset;

@end
