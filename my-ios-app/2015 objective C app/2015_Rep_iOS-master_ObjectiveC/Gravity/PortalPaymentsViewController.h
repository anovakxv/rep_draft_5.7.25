//
//  PortalPaymentsViewController.h
//  Gravity
//
//  Created by Vlad Getman on 26.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "VGViewController.h"
#import <SHSPhoneTextField.h>

@interface PortalPaymentsViewController : VGViewController <UITextFieldDelegate> {
    IBOutlet UIButton *withdrawBtn;
    IBOutlet UILabel *balanceLabel;
    IBOutlet UIView *balanceView;
    
    IBOutlet UITextField *bankField;
    IBOutlet SHSPhoneTextField *accountField;
    IBOutlet SHSPhoneTextField *routingField;
    IBOutlet UITextField *addressField;
    IBOutlet UITextField *nameField;
    
    NSNumber *balance;
}

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSNumber *portalId;
@property (nonatomic, strong) void (^bankBlock)(NSDictionary *bank);
@property (nonatomic, strong) NSDictionary *bankParams;

- (IBAction)withdraw;

@end
