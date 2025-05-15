//
//  AppDelegate.m
//  Gravity
//
//  Created by Vlad Getman on 08.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "PeopleViewController.h"
#import "PortalsViewController.h"
#import "MenuViewController.h"
#import "LandingViewController.h"
#import <TWMessageBarManager.h>
#import "ChatViewController.h"
#import "ProfileViewController.h"
#import <Flurry.h>

@interface TWAppDelegateDemoStyleSheet : NSObject <TWMessageBarStyleSheet>

+ (TWAppDelegateDemoStyleSheet *)styleSheet;

@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    RKLogConfigureByName("RestKit/*", RKLogLevelOff);
    // INITIALIZE CORE DATA STACK
    [DATA setup];
    [self cacheData];
    
    [Settings setObject:@[@"en"] forKey:@"AppleLanguages"];
    [Settings synchronize];
    
    self.mask = UIInterfaceOrientationMaskPortrait;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //[Stripe setDefaultPublishableKey:@"pk_test_eT3j5QCzjGEEsLLLXrcQMEvp"];
    [Stripe setDefaultPublishableKey:@"pk_live_V8JG0ktHiu7B43Po7Eoth6dN"];
    
    [Flurry startSession:@"xxx"];
    [Flurry setCrashReportingEnabled:YES];
    //[Flurry setEventLoggingEnabled:YES];
    
    //[self initBars];
    [self startLogin];
    
    self.window.tintColor = [UIColor appGreen];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [TWMessageBarManager sharedInstance].styleSheet = [TWAppDelegateDemoStyleSheet styleSheet];
    
    NSDictionary *launchNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    [self processNotification:launchNotification withAlert:NO];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    return YES;
}

- (void)startLogin {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[LandingViewController new]];
    navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigationController;
}

- (void)startApp {
    
    BOOL useTabs = NO;
    
    self.navigationDelegate = [[NavigationControllerDelegate alloc] init];
    
    self.menuController = [[DDMenuController alloc] init];
    self.menuController.pan.enabled = NO;
    if (useTabs) {
        self.menuController.rootViewController = [self createTabController];
    } else {
        PortalsViewController *controller = [[PortalsViewController alloc] init];
        controller.title = @"Portals";
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.delegate = self.navigationDelegate;
        navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.menuController.rootViewController = navigationController;
    }
    self.menuController.leftViewController = [[MenuViewController alloc] init];
    self.window.rootViewController = self.menuController;
    [self requestPush];
    [self inviteChecking];
    [SUPPORT startUpdatingLocation];
}

- (UITabBarController *)createTabController {
    
    UINavigationController *vc1 = [[UINavigationController alloc] initWithRootViewController:[[ProfileViewController alloc] init]];
    vc1.tabBarItem.title = [NSString stringWithFormat:@"%@%@", [APP.user.firstName substringToIndex:1], [APP.user.lastName substringToIndex:1]];
    vc1.tabBarItem.image = [UIImage imageNamed:@"BtnMe"];
    
    UINavigationController *vc2 = [[UINavigationController alloc] initWithRootViewController:[[PeopleViewController alloc] init]];
    vc2.tabBarItem.title = @"People";
    vc2.tabBarItem.image = [UIImage imageNamed:@"tabbar_people"];
    
    UINavigationController *vc3 = [[UINavigationController alloc] initWithRootViewController:[[PortalsViewController alloc] init]];
    vc3.tabBarItem.title = @"Partners";
    vc3.tabBarItem.image = [UIImage imageNamed:@"tabbar_portal"];
    
    for (UINavigationController *nc in @[vc1, vc2, vc3]) {
        nc.delegate = self.navigationDelegate;
        nc.interactivePopGestureRecognizer.enabled = NO;
    }
    
    UITabBarController *tabController = [[UITabBarController alloc] init];
    tabController.viewControllers = @[vc1, vc2, vc3];
    
    UITabBar *tabBar = tabController.tabBar;
    
    tabBar.layer.borderWidth = 1.0f;
    tabBar.layer.borderColor = [[UIColor clearColor] CGColor];

    tabController.view.backgroundColor = [UIColor whiteColor];
    
    return tabController;
}

- (void)switchToPeopleOrPortals:(BOOL)toPeople {
    /*[UIView transitionWithView:self.menuController.view
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{*/
                        
                        UIViewController *controller;
                        if (toPeople) {
                            controller = [[PeopleViewController alloc] init];
                        } else {
                            controller = [[PortalsViewController alloc] init];
                        }
                        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                        navigationController.delegate = self.navigationDelegate;
                        navigationController.interactivePopGestureRecognizer.enabled = NO;
                        [self.menuController setRootViewController:navigationController];
                    /*}
                    completion:nil];*/
}

- (void)initBars {
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13.0f]} forState:UIControlStateNormal];
    UIImage* tabBarBackground = [UIUtils imageWithSize:CGSizeMake(CGRectGetWidth(self.window.frame), 49)
                                              andColor:[UIColor whiteColor]];
    [[UITabBar appearance] setBackgroundImage:tabBarBackground];
    [[UITabBar appearance] setShadowImage:[UIImage imageNamed:@"line_grey"]];
    [[UITabBar appearance] setTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setBackgroundImage:[UIUtils imageWithSize:CGSizeMake(CGRectGetWidth(self.window.frame), 64)
                                                                   andColor:[UIColor whiteColor]]
                                       forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"line_grey"]];
}

- (void)cacheData {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"limit":@"150"}
                log:NO
           function:@"api_get_all_static_data"
    completionBlock:^(NSArray *json, NSError *error) {
        [DATA mappingJSON:json type:MAPPING_STATIC_DATA];
    }];
}

- (void)inviteChecking {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"limit":@"1", @"confirmed":@"0,-1", @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue}
                log:NO
           function:@"api_get_goals_team_invites"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [DATA mappingJSON:json
                     type:MAPPING_INVITES
         withCompletition:^(NSArray *items) {
             if (items.count > 0) {
                 InviteViewController *controller = [[InviteViewController alloc] init];
                 controller.invite = [items firstObject];
                 controller.delegate = self;
                 [APP.menuController presentTransparentController:controller animated:NO];
             } else {
                 [self performSelector:@selector(inviteChecking)
                            withObject:nil
                            afterDelay:5];
             }
         }];
    }];
}

- (void)inviteControllerClosed {
    [self performSelector:@selector(inviteChecking)
               withObject:nil
               afterDelay:5];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (application.applicationIconBadgeNumber > 0) {
        [application setApplicationIconBadgeNumber:0];
        [self readAllAcitvities];
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [DATA saveContext];
}

- (UIInterfaceOrientationMask) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return self.mask;
}

#pragma mark - push

- (void)readAllAcitvities {
    if (!self.user) {
        [self performSelector:@selector(readAllAcitvities)
                   withObject:nil
                   afterDelay:3];
        return;
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{}
                log:NO
           function:@"api_mark_all_activities_as_read"
    completionBlock:nil];
}

- (void)requestPush {
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)
                                           categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        /*[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];*/
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenString = [[[[deviceToken description]
                                     stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                    stringByReplacingOccurrencesOfString:@">" withString:@""]
                                   stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    self.deviceToken = deviceTokenString;
    [self registerPush];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // NSLog(@"%@",[error localizedDescription]);
}

- (void)registerPush {
    if (!self.user || !self.deviceToken) {
        [self performSelector:@selector(registerPush) withObject:nil afterDelay:1.0];
        return;
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"device_token":self.deviceToken}
                log:NO
           function:@"api_edit_user"
    completionBlock:nil];
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self processNotification:userInfo withAlert:[application applicationState] == UIApplicationStateActive];
}

- (void)processNotification:(NSDictionary *)notification withAlert:(BOOL)alert {
    
    if (!notification) return;

    id controller = [APP.menuController currentController];
    
    if ([[notification objectForKey:@"type"] isEqual:@"new_direct_message"]) {
        
        if ([controller isKindOfClass:[ChatViewController class]]) {
            ChatViewController *vc = controller;
            if ([[notification objectForKey:@"id"] integerValue] == vc.userId.integerValue) {
                return;
            }
        }
        if (alert) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"New Message"
                                                           description:[notification valueForKeyPath:@"aps.alert"]
                                                                  type:TWMessageBarMessageTypeInfo
                                                              callback:^{
                                                                  [self processNotification:notification];
                                                              }];
        } else {
            [self processNotification:notification];
        }
    }
}

- (void)processNotification:(NSDictionary *)notification {
    if ([[notification objectForKey:@"type"] isEqual:@"new_direct_message"]) {
        ChatViewController *controller = [[ChatViewController alloc] init];
        controller.userId = @([[notification objectForKey:@"id"] integerValue]);
        [APP.menuController pushController:controller animated:YES];
    }
}

@end

@implementation TWAppDelegateDemoStyleSheet

#pragma mark - Alloc/Init

+ (TWAppDelegateDemoStyleSheet *)styleSheet
{
    return [[TWAppDelegateDemoStyleSheet alloc] init];
}

#pragma mark - TWMessageBarStyleSheet

- (UIColor *)backgroundColorForMessageType:(TWMessageBarMessageType)type
{
    UIColor *backgroundColor = nil;
    switch (type)
    {
        case TWMessageBarMessageTypeError:
            backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75];
            break;
        case TWMessageBarMessageTypeSuccess:
            backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.75];
            break;
        case TWMessageBarMessageTypeInfo:
            backgroundColor = [UIColor colorFromHexString:@"#979898" alpha:1.0];
            break;
        default:
            break;
    }
    return backgroundColor;
}

- (UIColor *)strokeColorForMessageType:(TWMessageBarMessageType)type
{
    UIColor *strokeColor = nil;
    switch (type)
    {
        case TWMessageBarMessageTypeError:
            strokeColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
            break;
        case TWMessageBarMessageTypeSuccess:
            strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
            break;
        case TWMessageBarMessageTypeInfo:
            strokeColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
            break;
        default:
            break;
    }
    return strokeColor;
}

- (UIImage *)iconImageForMessageType:(TWMessageBarMessageType)type
{
    UIImage *iconImage = nil;//[UIImage imageNamed:@"null"];
    /*switch (type)
     {
     case TWMessageBarMessageTypeError:
     iconImage = [UIImage imageNamed:kAppDelegateDemoStyleSheetImageIconError];
     break;
     case TWMessageBarMessageTypeSuccess:
     iconImage = [UIImage imageNamed:kAppDelegateDemoStyleSheetImageIconSuccess];
     break;
     case TWMessageBarMessageTypeInfo:
     iconImage = [UIImage imageNamed:kAppDelegateDemoStyleSheetImageIconInfo];
     break;
     default:
     break;
     }*/
    return iconImage;
}

@end
