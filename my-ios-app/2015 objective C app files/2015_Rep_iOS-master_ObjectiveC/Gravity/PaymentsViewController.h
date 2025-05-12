//
//  PaymentsViewController.h
//  Gravity
//
//  Created by Vlad Getman on 05.01.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKCardExpiryField.h"
#import <SHSPhoneTextField.h>

@interface PaymentsViewController : VGViewController {
    IBOutlet UITextField *nameField;
    IBOutlet BKCardExpiryField *expField;
    IBOutlet SHSPhoneTextField *numberField;
    IBOutlet SHSPhoneTextField *cvcField;
}

@property (nonatomic, strong) Card *card;

@end
