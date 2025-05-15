//
//  MenuViewController.h
//  Gravity
//
//  Created by Vlad Getman on 14.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageButton.h"

@interface MenuViewController : UIViewController

@property (nonatomic, strong) IBOutlet ImageButton *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@end
