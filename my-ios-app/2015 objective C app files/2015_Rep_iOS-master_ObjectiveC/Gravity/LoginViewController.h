//
//  LoginViewController.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "VGViewController.h"

@interface LoginViewController : VGViewController <UITextFieldDelegate> {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIButton *loginBtn;
}

@end
