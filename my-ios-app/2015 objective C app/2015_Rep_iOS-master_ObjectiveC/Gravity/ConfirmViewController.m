//
//  ConfirmViewController.m
//  Gravity
//
//  Created by Vlad Getman on 30.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "ConfirmViewController.h"
#import "AppDelegate.h"
#import <Luhn.h>

@interface ConfirmViewController ()

@end

@implementation ConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [actionButton setBackgroundImage:[UIUtils roundedImageWithSize:actionButton.frame.size
                                                          andColor:actionButton.backgroundColor
                                                        withBorder:YES]
                            forState:UIControlStateNormal];
    actionButton.backgroundColor = nil;
    
    [numberField.formatter setDefaultOutputPattern:@"#### #### #### #### ###"];
    [cvcField.formatter setDefaultOutputPattern:@"####"];
    [zipField.formatter setDefaultOutputPattern:@"#########"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showContent:YES animated:YES];
}

- (IBAction)finalConfirmation {
    
    NSArray *names = [nameField.text componentsSeparatedByString:@" "];
    if (names.count != 2) {
        [SUPPORT showError:@"Name must contain First and Last Name"];
        return;
    }
    
    if (![numberField.phoneNumberWithoutPrefix isValidCreditCardNumber]) {
        [SUPPORT showError:@"Incorrect card number"];
        return;
    } else if (expField.dateComponents.month == NSNotFound ||
               expField.dateComponents.year == NSNotFound ||
               expField.dateComponents.year < [BKCardExpiryField currentYear]) {
        [SUPPORT showError:@"Incorrect expiration date"];
        return;
    } else if (cvcField.text.length < 3) {
        [SUPPORT showError:@"Incorrect CVV"];
        return;
    }
    
    /*for (UITextField *tf in @[streetField, cityField, stateField, zipField]) {
        if (tf.text.length == 0) {
            UILabel *label = (UILabel *)[tf.superview viewWithTag:tf.tag - 10];
            NSString *error = [NSString stringWithFormat:@"%@ must be filled", label.text];
            [SUPPORT showError:error];
            return;
        }
    }*/
    
    [SUPPORT showLoading:YES];
    STPCard *card = [[STPCard alloc] init];
    card.number = numberField.phoneNumberWithoutPrefix;
    card.expMonth = expField.dateComponents.month;
    card.expYear = expField.dateComponents.year;
    card.cvc = cvcField.phoneNumberWithoutPrefix;
    [[STPAPIClient sharedClient] createTokenWithCard:card
                                          completion:^(STPToken *token, NSError *error) {
                                              if (error) {
                                                  [SUPPORT showError:error.localizedDescription];
                                                  [SUPPORT showLoading:NO];
                                              } else {
                                                  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                                  params[@"card_number"] = numberField.phoneNumberWithoutPrefix;
                                                  params[@"card_expiration_month"] = @(expField.dateComponents.month).stringValue;
                                                  params[@"card_expiration_year"] = @(expField.dateComponents.year).stringValue;
                                                  params[@"card_ccv"] = cvcField.phoneNumberWithoutPrefix;
                                                  params[@"card_fname"] = [names firstObject];
                                                  params[@"card_lname"] = [names lastObject];
                                                  params[@"stripe_token"] = token.tokenId;
                                                  
                                                  [DataMNG JSONTo:kServerUrl
                                                   withDictionary:params
                                                              log:NO
                                                         function:@"api_add_payment_card"
                                                  completionBlock:^(NSDictionary *json, NSError *error) {
                                                      [SUPPORT showLoading:NO];
                                                      if (error) {
                                                          [SUPPORT showError:error.localizedDescription];
                                                      } else {
                                                          [DataMNG JSONTo:kServerUrl
                                                           withDictionary:@{@"aBasket":self.basket}
                                                                      log:NO
                                                                 function:@"api_basket_checkout"
                                                          completionBlock:^(NSDictionary *json, NSError *error) {
                                                              [SUPPORT showLoading:NO];
                                                              if (error) {
                                                                  [SUPPORT showError:error.localizedDescription];
                                                              } else {
                                                                  [SUPPORT showAlert:@"The Purchase is complete"
                                                                                body:nil];
                                                                  [self.presentingViewController.presentingViewController
                                                                   dismissViewControllerAnimated:YES completion:nil];
                                                              }
                                                          }];
                                                      }
                                                  }];
                                              }
                                          }];
    
    /*NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"card_number"] = numberField.phoneNumberWithoutPrefix;
    params[@"card_expiration_month"] = @(expField.dateComponents.month).stringValue;
    params[@"card_expiration_year"] = @(expField.dateComponents.year).stringValue;
    params[@"card_ccv"] = cvcField.phoneNumberWithoutPrefix;
    params[@"line1"] = streetField.text;
    params[@"city"] = cityField.text;
    params[@"state"] = stateField.text;
    params[@"zip"] = zipField.text;
    params[@"fname"] = [names firstObject];
    params[@"lname"] = [names lastObject];
    params[@"country_code"] = @"US";
    
    [SUPPORT showLoading:YES];
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_add_payment_card"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
            [SUPPORT showLoading:NO];
        } else {
            [DataMNG JSONTo:kServerUrl
             withDictionary:@{@"aBasket":@{@"aProducts":self.ids}}
                        log:NO
                   function:@"api_basket_checkout"
            completionBlock:^(NSDictionary *json, NSError *error) {
                [SUPPORT showLoading:NO];
                if (error) {
                    [SUPPORT showError:error.localizedDescription];
                } else {
                    [SUPPORT showAlert:@"The Purchase is complete"
                                  body:nil];
                    [self.presentingViewController.presentingViewController
                     dismissViewControllerAnimated:YES completion:nil];
                }
            }];
        }
    }];*/
}

#pragma mark UI

- (IBAction)cancelAction {
    [self showContent:NO animated:YES];
}

- (void)showContent:(BOOL)show animated:(BOOL)animated {
    
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         CGRect frame = scrollView.frame;
                         frame.origin.y = show ? 64 : (CGRectGetHeight(self.view.frame) - 48);
                         scrollView.frame = frame;
                     } completion:nil];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:!show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         self.view.alpha = show ? 1 : 0;
                     } completion:^(BOOL finished) {
                         if (!show) {
                             /*if (self.selectionBlock && self.tableView.indexPathForSelectedRow) {
                              self.selectionBlock(self.tableView.indexPathForSelectedRow.section);
                              }*/
                             //[self.navigationController popViewControllerAnimated:NO];
                             [self dismissViewControllerAnimated:NO completion:nil];
                         }
                     }];
}

#pragma mark text

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    
    UIEdgeInsets insets = scrollView.contentInset;
    insets.bottom += kbOffset;
    scrollView.contentInset = insets;
    scrollView.scrollIndicatorInsets = insets;
}

@end
