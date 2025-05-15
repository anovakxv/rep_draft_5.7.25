//
//  AppDelegate.h
//  Gravity
//
//  Created by Vlad Getman on 08.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DDMenuController.h"
#import "User.h"
#import "InviteViewController.h"
#import "NavigationControllerDelegate.h"
#import "TransitionManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, InviteDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DDMenuController *menuController;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) NSString *deviceToken;
@property (assign, nonatomic) NSUInteger mask;
@property (strong, nonatomic) NavigationControllerDelegate *navigationDelegate;

- (void)startApp;
- (void)startLogin;
- (void)inviteChecking;
- (void)switchToPeopleOrPortals:(BOOL)toPeople;

@end

