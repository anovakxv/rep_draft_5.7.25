//
//  LandingViewController.m
//  Gravity
//
//  Created by Administrator on 22.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "LandingViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "DataManager.h"
#import "SignUpViewController.h"
#import "LoginViewController.h"

@interface LandingViewController ()

@end

@implementation LandingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (UIView *view in @[loginButton, registerButton]) {
        view.layer.cornerRadius = 5.;
        if (registerButton != view) {
            view.layer.borderColor = [UIColor whiteColor].CGColor;
            view.layer.borderWidth = 1.;
        }
    }
    [registerButton backgroundToImage];
    
    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                initWithTitle:@" "
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem =btnBack;
    
    
    if ([Settings objectForKey:@"email"] && [Keychain objectForKey:@"password"]) {
        if ([[Keychain objectForKey:@"password"] length] > 0) {
            [self showLoading:YES];
            [self loginWithEmail:[Settings objectForKey:@"email"] andPassword:[Keychain objectForKey:@"password"] autoLogin:YES];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)showLoading:(BOOL)show {
    for (UIView *view in self.view.subviews) {
        view.hidden = view.tag == 5 ? !show : show;
    }
}

- (IBAction)loginAction {
    
    LoginViewController *controller = [[LoginViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    
    /*UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Log In"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Log In", nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alertView textFieldAtIndex:0].placeholder = @"Email";
    [alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
    alertView.shouldEnableFirstOtherButtonBlock = ^(UIAlertView *alertView) {
        return (@([alertView textFieldAtIndex:0].text.length > 0 && [alertView textFieldAtIndex:1].text.length > 0)).boolValue;
    };
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.cancelButtonIndex == buttonIndex)
            return;
        [self.view endEditing:YES];
        [self loginWithEmail:[alertView textFieldAtIndex:0].text
                 andPassword:[alertView textFieldAtIndex:1].text
                   autoLogin:NO];
    };
    [alertView show];*/
}

- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password autoLogin:(BOOL)autoLogin {
    
    NSDictionary *params = @{@"email":email,@"password":password};
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_login_user"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        if (error) {
            [SUPPORT showError:error.localizedDescription];
            [self showLoading:NO];
        } else {
            
            [DATA mappingJSON:json
                         type:MAPPING_USER
             withCompletition:^(NSArray *items) {
                 
                 if (items.count > 0) {
                     APP.user = [items firstObject];
                     if (!autoLogin) {
                         [Settings setObject:email forKey:@"email"];
                         [Settings synchronize];
                         [Keychain setObject:password forKey:@"password"];
                     }
                     
                     [APP startApp];
                 }
             }];
        }
    }];
}

-(IBAction)registerAction{
    SignUpViewController *controller = [[SignUpViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
