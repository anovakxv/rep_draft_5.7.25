//
//  VGProgressBar.h
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface VGProgressBar : UIView

@property (nonatomic) IBInspectable UIColor *graphColor;
@property (nonatomic) IBInspectable CGFloat progress;
@property (nonatomic) IBInspectable BOOL showProgress;

@end
