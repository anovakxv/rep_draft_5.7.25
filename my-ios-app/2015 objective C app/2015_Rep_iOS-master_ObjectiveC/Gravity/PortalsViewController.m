//
//  PatnersViewController.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "PortalsViewController.h"
#import "PortalCell.h"
#import "PortalDetailViewController.h"
#import "AppDelegate.h"
#import "InviteViewController.h"
#import "TeamChatViewController.h"
#import "ProfileViewController.h"

@interface PortalsViewController ()

@end

@implementation PortalsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.title = @"Partners";
        
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
    self.navigationItem.titleView = self.segmentedControl;
    
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(getPortals) forControlEvents:UIControlEventValueChanged];
    refreshControl.layer.masksToBounds = YES;
    [self.tableView insertSubview:refreshControl atIndex:0];
    
    [UIUtils setPlaceholderColor:searchField.textColor
                         forView:searchField
                     andSubViews:NO];
    [UIUtils setLeftPaddingForTextFieldsForView:searchField
                                    andSubViews:NO];
    
    [self.view insertSubview:menuView aboveSubview:self.tableView];
    
    [self.tableView registerCellClass:[PortalCell class]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:profileBtn];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    searchField.background = [UIUtils roundedImageWithSize:searchField.frame.size
                                                  andColor:[UIColor whiteColor]
                                                withBorder:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [profileBtn sd_setImageWithURL:[NSURL URLWithString:APP.user.photoSmall]];
    //APP.menuController.pan.enabled = NO;
    [self getPortals];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //APP.menuController.pan.enabled = YES;
    [searchField resignFirstResponder];
}

- (IBAction)switchView {
    [APP switchToPeopleOrPortals:YES];
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    [self getPortals];
}

- (IBAction)newChat {
    
}

- (void)openOwnProfile {
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.showMenu = YES;
    controller.userId = APP.user.userId;
    [self.navigationController pushViewController:controller animated:YES];
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


#pragma mark - server side

- (void)getPortals {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"limit"] = @"50";
    params[@"offset"] = @"0";
    params[@"show_hidden"] = @(self.segmentedControl.selectedSegmentIndex != 0).stringValue;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        params[@"users_id"] = APP.user.userId.stringValue;
    } else if (self.segmentedControl.selectedSegmentIndex == 1) {
        params[@"my_network"] = @"1";
    }
    if (searchField.text.length > 0)
        params[@"keyword"] = searchField.text;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:YES
           function:@"api_get_portals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_PORTALS
         withCompletition:^(NSArray *items) {
             
             switch (self.segmentedControl.selectedSegmentIndex) {
                 case 0:
                     openPortals = items;
                     break;
                     
                 case 1:
                     networkPortals = items;
                     break;
                     
                 case 2:
                     allPortals = items;
                     break;
             }
             
             if (refreshControl.isRefreshing)
                 [refreshControl endRefreshing];
             [self.tableView reloadData];
         }];
    }];
}

#pragma mark - table view

- (NSArray *)currentArray {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            return openPortals;
            
        case 1:
            return networkPortals;
            
        case 2:
            return allPortals;
            
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self currentArray].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PortalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.portal = [self currentArray][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Portal *portal = [self currentArray][indexPath.row];
    
    PortalDetailViewController *controller = [[PortalDetailViewController alloc] init];
    controller.portalId = portal.portalId;
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    Portal *portal = [self currentArray][indexPath.row];
    return portal.userId == APP.user.userId ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.segmentedControl.selectedSegmentIndex == 0 ? @"Hide" : @"Delete";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Portal *portal = [self currentArray][indexPath.row];
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":portal.portalId.stringValue, @"todo":@"hide"}
                log:NO
           function:@"api_hide_portal"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self.tableView beginUpdates];
            NSMutableArray *p = [[NSMutableArray alloc] initWithArray:[self currentArray]];
            [p removeObjectAtIndex:indexPath.row];
            
            switch (self.segmentedControl.selectedSegmentIndex) {
                case 0:
                    openPortals = [NSArray arrayWithArray:p];
                    break;
                    
                case 1:
                    networkPortals = [NSArray arrayWithArray:p];
                    break;
                    
                case 2:
                    allPortals = [NSArray arrayWithArray:p];
                    break;
            }
            
            [p removeAllObjects];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark textfield

- (IBAction)textFieldDidChange:(UITextField *)textField {
    [self getPortals];
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
