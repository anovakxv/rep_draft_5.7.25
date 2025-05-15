//
//  PaymentsViewController.m
//  Gravity
//
//  Created by Vlad Getman on 05.01.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "PaymentsViewController.h"
#import <Luhn.h>

@interface PaymentsViewController ()

@end

@implementation PaymentsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        UIBarButtonItem *cancelAction = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = cancelAction;
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = doneBtn;
        
        self.title = @"Mobile Payments";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [numberField.formatter setDefaultOutputPattern:@"#### #### #### #### ###"];
    [cvcField.formatter setDefaultOutputPattern:@"####"];
    
    [SUPPORT showLoading:YES];
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{}
                log:NO
           function:@"api_get_payment_cards"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_CARDS
         withCompletition:^(NSArray *items) {
             [SUPPORT showLoading:NO];
             if (items.count > 0) {
                 self.card = [items firstObject];
             }
         }];
    }];
}

- (void)cancelAction {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    
    [self.view endEditing:YES];
    
    if (self.card) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
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
    
    [SUPPORT showLoading:YES];
    STPCard *card = [[STPCard alloc] init];
    card.number = numberField.phoneNumberWithoutPrefix;
    card.expMonth = expField.dateComponents.month;
    card.expYear = expField.dateComponents.year;
    card.cvc = cvcField.phoneNumberWithoutPrefix;
    card.name = nameField.text;
    
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
                                                          [self cancelAction];
                                                      }
                                                  }];
                                              }
                                          }];
    
    
}

- (void)setCard:(Card *)card {
    _card = card;
    nameField.text = card.name;
    numberField.text = [@"•••• •••• •••• " stringByAppendingString:card.cardNumber.stringValue];
    expField.text = [NSString stringWithFormat:@"%@ / %@", card.expirationMonth.stringValue, card.expirationYear.stringValue];
}

@end
