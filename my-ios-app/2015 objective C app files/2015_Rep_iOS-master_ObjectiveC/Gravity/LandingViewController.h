//
//  LandingViewController.h
//  Gravity
//
//  Created by Administrator on 22.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LandingViewController : VGViewController {
    IBOutlet UIButton *loginButton;
    IBOutlet UIButton *registerButton;
}

-(IBAction)loginAction;
-(IBAction)registerAction;

@end
