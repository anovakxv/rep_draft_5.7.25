//
//  LandingViewController.h
//  Gravity
//
//  Created by Administrator on 22.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LandingViewController : VGViewController {
    IBOutlet UIButton *loginButton;
    IBOutlet UIButton *registerButton;
}

-(IBAction)loginAction;
-(IBAction)registerAction;

@end
