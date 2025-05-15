//
//  VGProgressBar.h
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface VGProgressBar : UIView

@property (nonatomic) IBInspectable UIColor *graphColor;
@property (nonatomic) IBInspectable CGFloat progress;
@property (nonatomic) IBInspectable BOOL showProgress;

@end
