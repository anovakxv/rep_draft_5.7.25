//
//  ViewController.m
//  Goals
//
//  Created by Ahad on 9/5/14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "PeopleViewController.h"
#import "PeopleCell.h"
#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "ChatViewController.h"
#import "TeamChatViewController.h"

@interface PeopleViewController ()

@end

@implementation PeopleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.title = @"People";
        
        profileBtn = [[ImageButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
        [profileBtn addTarget:self
                       action:@selector(openOwnProfile)];
        profileBtn.layer.cornerRadius = CGRectGetHeight(profileBtn.frame) / 2;
        
        UIBarButtonItem *dropBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_dropdown"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(dropAction)];
        self.navigationItem.rightBarButtonItem = dropBtn;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(getItems) forControlEvents:UIControlEventValueChanged];
    refreshControl.layer.masksToBounds = YES;
    [self.tableView insertSubview:refreshControl atIndex:0];
    
    self.navigationItem.titleView = self.segmentedControl;
    
    [UIUtils setPlaceholderColor:searchField.textColor
                         forView:searchField
                     andSubViews:NO];
    [UIUtils setLeftPaddingForTextFieldsForView:searchField
                                    andSubViews:NO];
    
    [self.tableView registerCellClass:[PeopleCell class]];
    [self getChats];
    [self getNetwork];
    [self getAllUsers];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:profileBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    //APP.menuController.pan.enabled = NO;
    [self getItems];
    [profileBtn sd_setImageWithURL:[NSURL URLWithString:APP.user.photoSmall]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //APP.menuController.pan.enabled = YES;
    [searchField resignFirstResponder];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    searchField.background = [UIUtils roundedImageWithSize:searchField.frame.size
                                                  andColor:[UIColor whiteColor]
                                                withBorder:NO];
}

- (IBAction)switchView {
    [APP switchToPeopleOrPortals:NO];
}

- (void)openOwnProfile {
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.showMenu = YES;
    controller.userId = APP.user.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)newChat {
    
}

- (IBAction)newTeam {
    TeamChatViewController *controller = [[TeamChatViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [self showMenu:NO];
}

- (void)dropAction {
    [self showMenu:![self menuShowed]];
}

- (BOOL)menuShowed {
    return !menuView.hidden;
}

- (void)showMenu:(BOOL)show {
    
    if (animationInProgress)
        return;
    
    if (show) {
        menuView.hidden = NO;
    } else {
        [searchField resignFirstResponder];
    }
    animationInProgress = YES;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = menuView.frame;
                         frame.origin.y = 64 + (show ? 0 : -CGRectGetHeight(menuView.frame));
                         menuView.frame = frame;
                         
                         CGPoint offset = self.tableView.contentOffset;
                         offset.y += CGRectGetHeight(menuView.frame) * (show ? -1 : 1);
                         self.tableView.contentOffset = offset;
                         
                         UIEdgeInsets insets = self.tableView.contentInset;
                         insets.top = show ? CGRectGetHeight(menuView.frame) : 0;
                         self.tableView.contentInset = insets;
                         self.tableView.scrollIndicatorInsets = insets;
                     } completion:^(BOOL finished) {
                         if (!show) {
                             menuView.hidden = YES;
                         }
                         animationInProgress = NO;
                     }];
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    [self getItems];
}

#pragma mark - server side

- (void)getItems {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            [self getChats];
            break;
            
        case 1:
            [self getNetwork];
            break;
            
        case 2:
            [self getAllUsers];
            break;
    }
}

- (void)getChats {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"limit":@"200", @"show_hidden":@"0", @"keyword":searchField.text.length == 0 ? @"" : searchField.text}
                log:NO
           function:@"api_get_messages"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_MESSAGES_INVERSE
         withCompletition:^(NSArray *items) {
             chats = items;
             if (refreshControl.isRefreshing)
                 [refreshControl endRefreshing];
             [self.tableView reloadData];
         }];
    }];
}

- (void)getAllUsers {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"limit":@"4096", @"keyword":searchField.text.length == 0 ? @"" : searchField.text}
                log:NO
           function:@"api_get_users"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             users = items;
             if (refreshControl.isRefreshing)
                 [refreshControl endRefreshing];
             [self.tableView reloadData];
         }];
    }];
}

- (void)getNetwork {
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"users_id":APP.user.userId.stringValue, @"keyword":searchField.text.length == 0 ? @"" : searchField.text}
                log:NO
           function:@"api_members_of_my_network"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             network = items;
             if (refreshControl.isRefreshing)
                 [refreshControl endRefreshing];
             [self.tableView reloadData];
         }];
    }];
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            return chats.count;
            
        case 1:
            return network.count;
            
        case 2:
            return users.count;
            
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            cell.message = chats[indexPath.row];
            break;
            
        case 1:
            cell.user = network[indexPath.row];
            break;
            
        case 2:
            cell.user = users[indexPath.row];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        Message *message = chats[indexPath.row];
        if (message.chatId.integerValue > 0) {
            TeamChatViewController *controller = [[TeamChatViewController alloc] init];
            controller.chatId = message.chatId;
            controller.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            ChatViewController *controller = [[ChatViewController alloc] init];
            controller.userId = message.otherId;
            controller.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:controller animated:YES];
        }
    } else {
        User *user = (self.segmentedControl.selectedSegmentIndex == 1 ? network : users)[indexPath.row];
        
        ProfileViewController *controller = [[ProfileViewController alloc] init];
        controller.userId = user.userId;
        controller.hidesBottomBarWhenPushed = user.userId.integerValue != APP.user.userId.integerValue;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.segmentedControl.selectedSegmentIndex == 0 ? @"Hide" : @"Delete";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        Message *message = chats[indexPath.row];
        NSString *key = message.chatId.integerValue > 0 ? @"chats_id" : @"users_id";
        NSString *itemId = message.chatId.integerValue > 0 ? message.chatId.stringValue : message.otherId.stringValue;
        
        NSString *function = message.chatId.integerValue > 0 ? @"api_hide_chat_conversation" : @"api_hide_conversation";
        
        if (!itemId) {
            [SUPPORT showError:@"Someting wrong"];
            return;
        }
        
        [DataMNG JSONTo:kServerUrl
         withDictionary:@{key:itemId, @"todo":@"hide"}
                    log:NO
               function:function
        completionBlock:^(NSDictionary *json, NSError *error) {
            
            if (error) {
                [SUPPORT showError:error.localizedDescription];
            } else {
                [self.tableView beginUpdates];
                NSMutableArray *m = [[NSMutableArray alloc] initWithArray:chats];
                [m removeObjectAtIndex:indexPath.row];
                chats = [NSArray arrayWithArray:m];
                [m removeAllObjects];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark textfield

- (IBAction)textFieldDidChange:(UITextField *)textField {
    [self getItems];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

@end
