//
//  PortalPaymentsViewController.m
//  Gravity
//
//  Created by Vlad Getman on 26.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "PortalPaymentsViewController.h"

@interface PortalPaymentsViewController ()

@end

@implementation PortalPaymentsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Portal Payments";
        
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBackHorizontal"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];
        self.navigationItem.leftBarButtonItem = backBtn;
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(done)];
        self.navigationItem.rightBarButtonItem = doneBtn;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.portalId) {
        [withdrawBtn setBackgroundImage:[UIUtils roundedImageWithSize:withdrawBtn.frame.size
                                                             andColor:withdrawBtn.backgroundColor
                                                           withBorder:YES]
                               forState:UIControlStateNormal];
        withdrawBtn.backgroundColor = nil;
        [self getBalance];
    }
    [self getBank];
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)done {
    for (UITextField *tf in @[bankField, accountField, routingField, addressField, nameField]) {
        if (tf.text.length == 0) {
            UILabel *label = (UILabel *)[tf.superview viewWithTag:tf.tag - 1];
            NSString *error = [NSString stringWithFormat:@"%@ must be filled", label.text];
            [SUPPORT showError:error];
            return;
        }
    }
    
    for (UITextField *tf in @[accountField, routingField]) {
        if ([tf.text rangeOfString:@"•"].location != NSNotFound) {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    }
    
    [SUPPORT showLoading:YES];
    STPBankAccount *bank = [[STPBankAccount alloc] init];
    bank.country = @"US";
    bank.accountNumber = accountField.text;
    bank.routingNumber = routingField.text;
    [[STPAPIClient sharedClient] createTokenWithBankAccount:bank
                                                 completion:^(STPToken *token, NSError *error) {
                                                     if (error) {
                                                         [SUPPORT showError:error.localizedDescription];
                                                         [SUPPORT showLoading:NO];
                                                     } else {
                                                         NSDictionary *params = @{@"flname":nameField.text,
                                                                                  @"bank_name":bankField.text,
                                                                                  @"bank_account_number":accountField.text,
                                                                                  @"bank_routing_number":routingField.text,
                                                                                  @"address":addressField.text,
                                                                                  @"stripe_token":token.tokenId};
                                                         
                                                         if (self.portalId) {
                                                             NSMutableDictionary *p = [params mutableCopy];
                                                             p[@"portals_id"] = self.portalId.stringValue;
                                                             params = p;
                                                         } else {
                                                             self.bankBlock(params);
                                                             return;
                                                         }
                                                         
                                                         [DataMNG JSONTo:kServerUrl
                                                          withDictionary:params
                                                                     log:NO
                                                                function:@"api_save_portal_bank_account_stripe"
                                                         completionBlock:^(NSDictionary *json, NSError *error) {
                                                             [SUPPORT showLoading:NO];
                                                             if (error) {
                                                                 [SUPPORT showError:error.localizedDescription];
                                                             } else {
                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }
                                                         }];
                                                     }
                                                 }];
}

- (void)getBalance {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":self.portalId.stringValue}
                log:NO
           function:@"api_portal_get_balance"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        if ([json isKindOfClass:[NSString class]]) {
            balance = @([(id)json integerValue]);
            balanceLabel.text = [NSString stringWithFormat:@"ACCOUNT BALANCE: %@", balance.priceValue];
            balanceView.hidden = NO;
        }
    }];
}

- (void)getBank {
    if (self.portalId) {
        [DataMNG JSONTo:kServerUrl
         withDictionary:@{@"portals_id":self.portalId.stringValue}
                    log:NO
               function:@"api_get_portal_bank_accounts"
        completionBlock:^(NSDictionary *json, NSError *error) {
            if ([json isKindOfClass:[NSArray class]] && [(id)json count] > 0) {
                NSDictionary *bank = [(id)json firstObject];
                nameField.text = bank[@"flname"];
                addressField.text = bank[@"address"];
                bankField.text = bank[@"name"];
                accountField.text = [@"••••••••" stringByAppendingString:bank[@"account_number"]];
                routingField.text = [@"••••••••" stringByAppendingString:bank[@"routing_number"]];
            }
        }];
    } else if (self.bankParams) {
        
        nameField.text = self.bankParams[@"flname"];
        addressField.text = self.bankParams[@"address"];
        bankField.text = self.bankParams[@"bank_name"];
        accountField.text = self.bankParams[@"bank_account_number"];
        routingField.text = self.bankParams[@"bank_routing_number"];
    }
}

- (IBAction)withdraw {
    if (balance.integerValue == 0)
        return;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":self.portalId.stringValue}
                log:NO
           function:@"api_withdraw_money"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [SUPPORT showAlert:@"Done"
                          body:@"Balance withdrawn to bank account"];
            [self getBalance];
        }
    }];
}

#pragma mark text

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    
    if (kbOffset > 100)
        kbOffset -= 90;
    else if (kbOffset < -100)
        kbOffset += 90;
    
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom += kbOffset;
    self.scrollView.contentInset = insets;
    self.scrollView.scrollIndicatorInsets = insets;
}

@end
