//
//  PeopleDetailViewController.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "ProfileViewController.h"
#import "GoalsCell.h"
#import "GoalsDetailViewController.h"
#import "PortalCell.h"
#import "AppDelegate.h"
#import "PortalDetailViewController.h"
#import "NewPortalViewController.h"
#import "ActionCell.h"
#import "EditProfileViewController.h"
#import "UserType.h"
#import "VGActionSheet.h"
#import "InviteToTeamViewController.h"
#import "SharedPortalCell.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBack"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];
        
        self.navigationItem.leftBarButtonItem = backBtn;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if (!self.userId) {
        self.userId = APP.user.userId;
        self.navigationItem.leftBarButtonItem = nil;
        self.tabBarItem.title = [NSString stringWithFormat:@"%@%@", [APP.user.firstName substringToIndex:1], [APP.user.lastName substringToIndex:1]];
        
        UIBarButtonItem *menuBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_sidemenu"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(menuAction)];
        self.navigationItem.leftBarButtonItem = menuBtn;
    }
    
    [self.tableView registerCellClass:[GoalsCell class]
                       withIdentifier:@"GoalsCell"];
    [self.tableView registerCellClass:[PortalCell class]
                       withIdentifier:@"PartnersCell"];
    [self.tableView registerCellClass:[ActionCell class]
                       withIdentifier:@"ActionCell"];
    [self.tableView registerCellClass:[SharedPortalCell class]
                       withIdentifier:@"SharePortalCell"];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 49, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    messagesButton.hidden = self.userId == APP.user.userId;
    [actionButton setBackgroundImage:[UIUtils roundedImageWithSize:actionButton.frame.size
                                                          andColor:actionButton.backgroundColor
                                                        withBorder:YES]
                            forState:UIControlStateNormal];
    actionButton.backgroundColor = nil;
    bottomBar.hidden = APP.user.userId == self.userId;
    
    user = [DataModel getUserWithId:self.userId];
    [self getProfileData];
    
    if (self.showMenu) {
        UIBarButtonItem *menuBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_sidemenu"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(menuAction)];
        self.navigationItem.leftBarButtonItem = menuBtn;
        
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backAction)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [headerView addGestureRecognizer:swipeGesture];
        
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBack"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];
        
        self.navigationItem.rightBarButtonItem = backBtn;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    //APP.menuController.pan.enabled = NO;
    [self reloadData];
    
    if (segmentedControl.selectedSegmentIndex == 2) {
        [self getSharedPortals];
    } else if (segmentedControl.selectedSegmentIndex == 0) {
        [self getPortals];
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        [self getGoals];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    //APP.menuController.pan.enabled = YES;
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)menuAction {
    [APP.menuController showLeftController:YES];
}

- (void)getProfileData {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":self.userId.stringValue}
                log:NO
           function:@"api_user_profile"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [self getPortals];
        [self getGoals];
        [DATA mappingJSON:json
                     type:MAPPING_USER
         withCompletition:^(NSArray *items) {
             if (items.count > 0) {
                 user = [items firstObject];
                 [self reloadData];
             }
         }];
    }];
}

- (void)getPortals {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":self.userId.stringValue, @"limit":@"200", @"show_hidden":@"1", @"home":@"1"}
                log:NO
           function:@"api_get_portals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_PORTALS
         withCompletition:^(NSArray *items) {
             portals = items;
             [self.tableView reloadData];
         }];
    }];
}


- (void)getSharedPortals {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":self.userId.stringValue, @"limit":@"200", @"show_hidden":@"1"}
                log:NO
           function:@"api_get_shared_portals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_PORTALS
         withCompletition:^(NSArray *items) {
             shared = items;
             [self.tableView reloadData];
         }];
    }];
}

- (void)getGoals {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":self.userId.stringValue, @"limit":@"200", @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue}
                log:NO
           function:@"api_get_goals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_GOALS
         withCompletition:^(NSArray *items) {
             goals = items;
             [self.tableView reloadData];
         }];
    }];
}

- (void)reloadData {
    
    if (!user)
        return;
    
    self.title = user.fullName;
    
    [photoView setImageWithURL:[NSURL URLWithString:user.photo]
              placeholderImage:nil
   usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    infoLabel.text = user.fullName;
    aboutLabel.text = user.about.stringByStrippingHTMLItems;
    broadcastLabel.text = user.broadcast.stringByStrippingHTMLItems;
    
    UserType *type = [[DATA fetchData:@"UserType"
                       withDescriptor:nil
                        withPredicate:[NSPredicate predicateWithFormat:@"userTypeId == %@", user.userTypeId]
                       withAttributes:nil] firstObject];
    City *city = [[DATA fetchData:@"City"
                   withDescriptor:nil
                    withPredicate:[NSPredicate predicateWithFormat:@"cityId == %@", user.cityId]
                   withAttributes:nil] firstObject];
    
    NSMutableString *infoString = [[NSMutableString alloc] init];
    if (type) {
        [infoString appendFormat:@"Rep Type: %@   ", type.title];
    }
    if (city || user.manualCity.length > 0) {
        [infoString appendFormat:@"City: %@", user.manualCity.length > 0 ? user.manualCity : city.name];
    }
    
    infoLabel.text = infoString;
    
    NSMutableString *skills = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < user.skills.count; i++) {
        NSDictionary *s = user.skills[i];
        NSNumber *sId = @([s[@"id"] integerValue]);
        Skill *skill = [DataModel getSkillWithId:sId];
        [skills appendFormat:@"%@. %@\n", @(i + 1).stringValue, skill.skillDescription];
    }
    if (user.otherSkill.length > 0) {
        [skills appendFormat:@"%@. %@", @(user.skills.count + 1).stringValue, user.otherSkill];
    }
    skillsLabel.text = [skills stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [self.tableView reloadData];
}

- (IBAction)OnChangeSegmentedController:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    
    switch (sender.selectedSegmentIndex) {
            
        case 2:
            [self getSharedPortals];
            break;
            
        case 0:
            [self getPortals];
            break;
            
        case 1:
            [self getGoals];
            break;
    }
}

- (IBAction)messageAction {
    if (self.userId == APP.user.userId)
        return;
    
    ChatViewController *controller = [[ChatViewController alloc] init];
    controller.userId = self.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)showActions {
    
    NSArray *items = [self actions];
    
    VGActionSheet *actionSheet = [[VGActionSheet alloc] init];
    actionSheet.items = items;
    actionSheet.selectionBlock = ^(NSInteger buttonIndex) {
        
        if ([items[buttonIndex] isEqual:@"Recruit"]) {
            
            InviteToTeamViewController *controller = [[InviteToTeamViewController alloc] init];
            controller.userId = self.userId;
            [self presentTransparentController:controller animated:NO];
            
        } else if ([items[buttonIndex] isEqual:@"Pay"]) {
            
        } else if ([items[buttonIndex] isEqual:@"Edit Profile"]) {
            
            EditProfileViewController *controller = [[EditProfileViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
            
        } else if ([items[buttonIndex] rangeOfString:@"Ntwk"].location != NSNotFound) {
            [self networkAction];
        }
    };
    [actionSheet showInViewController:self];
}

- (NSArray *)actions {
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    if (self.userId != APP.user.userId) {
        [actions addObject:@"Recruit"];
    } else {
        [actions addObject:@"Edit Profile"];
    }
    //[actions addObject:@"Pay"];
    [actions addObject:user.network.boolValue ? @"- Ntwk" : @"+ Ntwk"];
    return actions;
}

- (void)networkAction {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":self.userId.stringValue,@"todo":user.network.boolValue ? @"delete" : @"add"}
                log:NO
           function:@"api_add_to_network_action"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            user.network = @(!user.network.boolValue);
            [DATA saveContext];
        }
    }];
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (segmentedControl.selectedSegmentIndex == 2) {
        return 2;
    }
    
    return (self.userId == APP.user.userId && APP.user.userTypeId.integerValue == 1 && segmentedControl.selectedSegmentIndex == 0) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 2:
            return section == 0 ? 2 : shared.count;
        
        case 0:
            return section == 0 ? portals.count : 1;
            
        case 1:
            return goals.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        switch (segmentedControl.selectedSegmentIndex) {
            case 2: {
                
                UILabel *label = indexPath.row == 0 ? broadcastLabel : aboutLabel;
                
                CGFloat height = [UIUtils findHeightForText:label.text
                                                havingWidth:CGRectGetWidth(tableView.frame) - 20
                                                    andFont:label.font];
                
                return height + 25;
            }
            
            case 0:
            case 1:
                return 90;
                
        }
    } else {
        return (segmentedControl.selectedSegmentIndex == 2 && indexPath.section == 1) ? 104 : 35;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (segmentedControl.selectedSegmentIndex == 2 && section == 1) ? 30 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (segmentedControl.selectedSegmentIndex == 2 && section == 1) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor clearColor];
        return view;
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.section == 0) {
        switch (segmentedControl.selectedSegmentIndex) {
                
            case 2:
                return indexPath.row == 0 ? broadcastCell : aboutCell;;
                
            case 0: {
                PortalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PartnersCell"];
                cell.portal = portals[indexPath.row];
                return cell;
            }
            case 1: {
                GoalsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GoalsCell"];
                cell.goal = goals[indexPath.row];
                return cell;
            }
                
        }
    } else {
        if (segmentedControl.selectedSegmentIndex == 2 && indexPath.section == 1) {
            SharedPortalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SharePortalCell"];
            cell.portal = shared[indexPath.row];
            return cell;
        } else {
            ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
            cell.title = @"Add Partner";
            return cell;
        }
    }
    
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((indexPath.section == 0 &&
         segmentedControl.selectedSegmentIndex == 0) ||
        (indexPath.section == 1 &&
         segmentedControl.selectedSegmentIndex == 2)) {
        
        Portal *portal = (segmentedControl.selectedSegmentIndex == 2 ? shared : portals)[indexPath.row];
        
        PortalDetailViewController *controller = [[PortalDetailViewController alloc] init];
        controller.portalId = portal.portalId;
        controller.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.section == 0 &&
               segmentedControl.selectedSegmentIndex == 1) {
        
        Goal *goal = goals[indexPath.row];
        /*
         //uncomment it when you want to show goals detials
         //only for goal's team
         if (!goal.teamMember.boolValue)
         return;
         */
        GoalsDetailViewController *controller = [[GoalsDetailViewController alloc] init];
        controller.goalId = goal.goalId;
        controller.goal = goal;
        controller.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.section == 1) {
        NewPortalViewController *controller = [[NewPortalViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
