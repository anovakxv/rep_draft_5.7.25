//
//  LoginViewController.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import <LEAlertController.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Log In";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [loginBtn backgroundToImage];
    loginBtn.layer.cornerRadius = 5;
}

- (IBAction)forgotPassword {
    LEAlertController *alert = [LEAlertController alertControllerWithTitle:@"Forgot Password"
                                                                   message:nil
                                                            preferredStyle:LEAlertControllerStyleAlert];
    [alert addAction:[LEAlertAction actionWithTitle:@"Cancel"
                                              style:LEAlertActionStyleCancel
                                            handler:nil]];
    
    [alert addAction:[LEAlertAction actionWithTitle:@"Done"
                                              style:LEAlertActionStyleDefault
                                            handler:^(LEAlertAction *action) {
                                                [[UIApplication sharedApplication].keyWindow endEditing:YES];
                                                UITextField *tf = alert.textFields.firstObject;
                                                [DataMNG JSONTo:kServerUrl
                                                 withDictionary:@{@"email":tf.text}
                                                            log:NO
                                                       function:@"api_forgot_password"
                                                completionBlock:^(NSDictionary *json, NSError *error) {
                                                    if (error) {
                                                        [SUPPORT showError:error.localizedDescription];
                                                    } else {
                                                        [Support showDoneWithText:@"New password sent"];
                                                    }
                                                }];
                                                
                                            }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Email";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    alert.shouldEnableFirstOtherButtonBlock = ^(LEAlertController *alertController) {
        UITextField *tf = alertController.textFields.firstObject;
        return @(tf.text.length > 0).boolValue;
    };
    [alert show];
}

- (IBAction)login {
    
    [self.view endEditing:YES];
    
    if (emailField.text.length == 0 || passwordField.text.length == 0) {
        NSString *error = [(emailField.text.length == 0 ? @"Email" : @"Password") stringByAppendingString:@" must be filled"];
        [SUPPORT showError:error];
        return;
    }
    
    NSDictionary *params = @{@"email":emailField.text,
                             @"password":passwordField.text};
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_login_user"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [DATA mappingJSON:json
                         type:MAPPING_USER
             withCompletition:^(NSArray *items) {
                 
                 if (items.count > 0) {
                     APP.user = [items firstObject];
                     [Settings setObject:emailField.text forKey:@"email"];
                     [Settings synchronize];
                     [Keychain setObject:passwordField.text forKey:@"password"];
                     
                     [APP startApp];
                 }
             }];
        }
    }];
}

@end
