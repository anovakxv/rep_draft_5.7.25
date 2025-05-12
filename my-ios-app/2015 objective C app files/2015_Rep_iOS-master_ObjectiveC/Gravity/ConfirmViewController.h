//
//  ConfirmViewController.h
//  Gravity
//
//  Created by Vlad Getman on 30.12.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKCardExpiryField.h"
#import <SHSPhoneTextField.h>

@interface ConfirmViewController : VGViewController <UITextFieldDelegate> {
    IBOutlet UIButton *actionButton;
    IBOutlet UIScrollView *scrollView;
    
    IBOutlet UITextField *nameField;
    IBOutlet BKCardExpiryField *expField;
    IBOutlet SHSPhoneTextField *numberField;
    IBOutlet SHSPhoneTextField *cvcField;
    
    IBOutlet UITextField *streetField;
    IBOutlet UITextField *cityField;
    IBOutlet UITextField *stateField;
    IBOutlet SHSPhoneTextField *zipField;
}

@property (nonatomic, strong) NSDictionary *basket;

@end
