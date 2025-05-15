//
//  InviteNetworksViewController.m
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "InviteToTeamViewController.h"
#import "InviteNetworksCell.h"
#import "AppDelegate.h"
#import "GoalsCell.h"

@interface InviteToTeamViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation InviteToTeamViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        ids = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.goalId || self.sharing) {
        [self getUsers];
        //self.tableView.tableHeaderView = headerView;
        [self.tableView registerCellClass:[InviteNetworksCell class]];
        if (self.sharing) {
            [contactsBtn setTitle:@"Feed" forState:UIControlStateNormal];
        }
    } else {
        titleLabel.text = self.portalId ? @"Select Team:" : @"Select Goal:";
        [self getGoals];
        [self.tableView registerCellClass:[GoalsCell class]];
    }
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    for (UIButton *btn in @[actionButton, contactsBtn]) {
        [btn setBackgroundImage:[UIUtils roundedImageWithSize:btn.frame.size
                                                     andColor:btn.backgroundColor
                                                   withBorder:YES]
                       forState:UIControlStateNormal];
        btn.backgroundColor = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showContent:YES animated:YES];
}

- (IBAction)inviteContacts {
    if (self.sharing) {
        [self shareToFeed:YES];
        return;
    }
    [self loadContacts];
}

-(void)loadContacts {
    CFErrorRef * error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    __block BOOL accessGranted = NO;
    if (&ABAddressBookRequestAccessWithCompletion != NULL) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
         ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    if (accessGranted) {
        
        //self.tableView.tableHeaderView = nil;
        [ids removeAllObjects];
        
        NSMutableArray *tempContacts = [NSMutableArray new];
        
        //NSMutableArray *emails = [NSMutableArray new];
        NSMutableArray *phones = [NSMutableArray new];
        
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        for(int i = 0; i < numberOfPeople; i++){
            ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
            ABMultiValueRef mv = ABRecordCopyValue(person, kABPersonEmailProperty);
            CFIndex numberOfAddresses = ABMultiValueGetCount(mv);
            ABMultiValueRef ph = ABRecordCopyValue(person, kABPersonPhoneProperty);
            CFIndex numberOfPhones = ABMultiValueGetCount(ph);
            
            if(numberOfAddresses > 0 || numberOfPhones > 0) {
                NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                
                if (firstName.length == 0) firstName = @"";
                if (lastName.length == 0) lastName = @"";
                
                NSInteger count = numberOfPhones/* + numberOfAddresses*/;
                BOOL multi = count > 1;
                
                if (numberOfPhones > 0) {
                    for (int n = 0; n < numberOfPhones; n++) {
                        NSString* phone = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(ph, n));
                        [phones addObject:[phone onlyNumbers]];
                        if (firstName.length != 0 || lastName.length != 0) {
                            
                            [tempContacts addObject:@{@"fname":firstName, @"lname":lastName, @"id":[phone onlyNumbers],
                                                      @"phone":@"1", @"multi":@(multi).stringValue,
                                                      @"flname":[NSString stringWithFormat:@"%@ %@", firstName, lastName]}];
                        }
                    }
                }
                /*if (numberOfAddresses > 0) {
                    for (int j = 0; j < numberOfAddresses; j++) {
                        NSString* email = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(mv, j));
                        
                        if (firstName.length != 0 || lastName.length != 0) {
                            
                            [tempContacts addObject:@{@"fname":firstName, @"lname":lastName, @"id":email,
                                                      @"phone":@"0", @"multi":@(multi).stringValue,
                                                      @"flname":[NSString stringWithFormat:@"%@ %@", firstName, lastName]}];
                        }
                        
                        [emails addObject:email];
                    }
                }*/
                
            }
        }
        
        contacts = tempContacts;
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lname" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        contacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
        
        [self.tableView reloadData];
    } else {
        
        BOOL canOpenSettings = (UIApplicationOpenSettingsURLString != NULL);
        
        NSString *error = @"This action requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app.";
        [UIAlertView showWithTitle:@"Error"
                           message:error
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:canOpenSettings ? @[@"Open Settings"] : nil
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex == alertView.cancelButtonIndex)
                                  return;
                              
                              NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                              [[UIApplication sharedApplication] openURL:url];
                          }];
    }
}

- (void)shareToFeed:(BOOL)toFeed {
    
    NSString *function;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"portals_id"] = self.portalId.stringValue;
    if (toFeed) {
        params[@"todo"] = @"share";
        function = @"api_portal_share_via_feed";
    } else {
        params[@"aUsersIDs"] = ids.allObjects;
        function = @"api_portal_share_via_message";
    }

    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:function
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self showContent:NO animated:YES];
        }
    }];
}

- (IBAction)inviteAction {
    
    if (ids.count == 0)
        return;
    
    if (self.sharing) {
        [self shareToFeed:NO];
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *function;
    if (contacts.count > 0) {
        params[@"goals_id"] = self.goalId.stringValue;
        params[@"todo"] = @"add";
        params[@"aPhones"] = ids.allObjects;
        
        function = @"api_invite_to_goal";
    } else {
        if (!self.portalId)
            params[@"aUsers"] = self.goalId ? ids.allObjects : @[self.userId.stringValue];
        params[@"todo"] = @"join";
        params[@"aGoalsIDs"] = self.goalId ? @[self.goalId.stringValue] : ids.allObjects;
        
        function = self.portalId ? @"api_join_goal" : @"api_manage_goal_team";
    }
    
    [SUPPORT showLoading:YES];
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:self.portalId ? @"api_join_goal" : @"api_manage_goal_team"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [SUPPORT showAlert:@"Invites sent" body:nil];
            [self showContent:NO animated:YES];
        }
        [SUPPORT showLoading:NO];
    }];
}

- (void)getUsers {
    
    NSDictionary *params;
    if (self.sharing) {
        params = @{@"users_id":APP.user.userId.stringValue};
    } else {
        params = @{@"users_id":APP.user.userId.stringValue, @"invited_goal_id":self.goalId.stringValue};
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_members_of_my_network"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *itms) {
             items = itms;
             [self.tableView reloadData];
         }];
    }];
}

- (void)getGoals {
    
    NSDictionary *params;
    if (self.portalId) {
        params = @{@"invited_user_id":self.userId.stringValue,
                   @"portals_id":self.portalId.stringValue,
                   @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue};
    } else {
        params = @{@"invited_user_id":self.userId.stringValue,
                   @"manage_goal_team_permission":@"1",
                   @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue};
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_get_goals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_GOALS
         withCompletition:^(NSArray *itms) {
             items = itms;
             [self.tableView reloadData];
         }];
    }];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return contacts.count > 0 ? contacts.count : items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.goalId || self.sharing) {
        InviteNetworksCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
        if (contacts.count > 0) {
            cell.contact = contacts[indexPath.row];
            cell.inviteBtn.selected = [ids containsObject:cell.contact[@"id"]];
        } else {
            cell.user = items[indexPath.row];
            cell.inviteBtn.selected = [ids containsObject:cell.user.userId.stringValue];
        }
        
        [cell.inviteBtn addTarget:self
                           action:@selector(inviteAction:)
                 forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    } else {
        GoalsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.goal = items[indexPath.row];
        cell.inviteBtn.hidden = NO;
        cell.inviteBtn.selected = [ids containsObject:cell.goal.goalId.stringValue];
        [cell.inviteBtn addTarget:self
                           action:@selector(inviteAction:)
                 forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void)inviteAction:(UIButton *)sender {
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (!indexPath)
        return;
    
    NSString *itemId;
    if (self.goalId || self.sharing) {
        
        if (contacts.count > 0) {
            itemId = contacts[indexPath.row][@"id"];
        } else {
            User *user = items[indexPath.row];
            itemId = user.userId.stringValue;
        }
    } else {
        Goal *goal = items[indexPath.row];
        itemId = goal.goalId.stringValue;
    }
    
    if (![ids containsObject:itemId]) {
        [ids addObject:itemId];
    } else {
        [ids removeObject:itemId];
    }
    sender.selected = !sender.selected;
    [self reloadButton];
}

- (void)reloadButton {
    
    NSString *title = self.sharing ? @"Share" : @"Invite";
    
    [actionButton setTitle:ids.count > 0 ? title : @"+" forState:UIControlStateNormal];
    actionButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, ids.count > 0 ? 4 : 12, 0);
    actionButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold"
                                                   size:ids.count > 0 ? 18 : 40];
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
                         CGRect frame = self.tableView.frame;
                         frame.origin.y = show ? 64 : (CGRectGetHeight(self.view.frame) - 48);
                         self.tableView.frame = frame;
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
                             [self dismissViewControllerAnimated:NO completion:nil];
                         }
                     }];
}

@end
