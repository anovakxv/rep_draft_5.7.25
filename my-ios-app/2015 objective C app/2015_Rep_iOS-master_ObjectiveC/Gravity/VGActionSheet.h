//
//  VGActionSheet.h
//  Gravity
//
//  Created by Vlad Getman on 27.11.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VGActionSheet : UIViewController

@property (nonatomic, strong) NSArray *items;
@property (strong, nonatomic) void (^selectionBlock)(NSInteger selectedIndex);

- (void)showInViewController:(UIViewController *)controller;

@end
