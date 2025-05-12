//
//  GoalsDetailViewController.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "GoalsDetailViewController.h"
#import "GoalsDetailFeedCell.h"
#import "GoalsDetailTeamCell.h"
#import "ActionCell.h"
#import "AppDelegate.h"
#import "ChatViewController.h"
#import "VGActionSheet.h"
#import "InviteToTeamViewController.h"
#import "UpdateGoalViewController.h"
#import "ProfileViewController.h"
#import "NewGoalViewController.h"

@interface GoalsDetailViewController ()

@end

@implementation GoalsDetailViewController

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
    
    [self.tableView registerCellClass:[ActionCell class]
                       withIdentifier:@"ActionCell"];
    [self.tableView registerCellClass:[GoalsDetailFeedCell class]
                       withIdentifier:@"GoalsDetailFeedCell"];
    [self.tableView registerCellClass:[GoalsDetailTeamCell class]
                       withIdentifier:@"GoalsDetailTeamCell"];
    self.tableView.contentInset = self.tableView.scrollIndicatorInsets;
    
    messagesButton.hidden = self.goal.userId == APP.user.userId;
    [actionButton setBackgroundImage:[UIUtils roundedImageWithSize:actionButton.frame.size
                                                          andColor:actionButton.backgroundColor
                                                        withBorder:YES]
                            forState:UIControlStateNormal];
    actionButton.backgroundColor = nil;
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //APP.menuController.pan.enabled = NO;
    [self getGoal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //APP.menuController.pan.enabled = YES;
}

- (void)getGoal {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"goals_id":self.goalId.stringValue}
                log:NO
           function:@"api_goal_details"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_GOAL
         withCompletition:^(NSArray *items) {
             if (items.count > 0) {
                 self.goal = [items firstObject];
                 [self reloadData];
             }
         }];
    }];
    [self getTeam];
    [self getBarData];
    [self getFeed];
}

- (void)getTeam {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"goals_id":self.goalId.stringValue, @"confirmed":@"1"}
                log:NO
           function:@"api_get_goal_users"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             team = items;
             [self.tableView reloadData];
         }];
    }];
}

- (void)getBarData {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"goals_id":self.goalId.stringValue, @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue}
                log:NO
           function:@"api_get_goals_progress_log"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [DATA mappingJSON:json
                     type:MAPPING_PROGRESS
         withCompletition:^(NSArray *items) {
             barItems = items;
             [barChart reloadData];
         }];
    }];
}

- (void)getFeed {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"goals_id":self.goalId.stringValue}
                log:NO
           function:@"api_get_goals_progress_feed"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [DATA mappingJSON:json
                     type:MAPPING_FEED
         withCompletition:^(NSArray *items) {
             feed = items;
             [self.tableView reloadData];
         }];
    }];
}

- (void)reloadData {
    
    GoalMetrics *metrics = [DataModel getGoalMetricsWithId:self.goal.metricId];
    GoalType * gType = [DataModel getGoalTypeWithId:self.goal.typeId];
    ReportingIncrement *reporting = [DataModel getReportingIncrementWithId:self.goal.reportingIncrementsId];
    Portal *portal = [DataModel getPortalWithId:self.goal.portalId];
    
    progressBar.progress = self.goal.progress.floatValue;
    
    if (metrics) {
        metricLabel.attributedText = [self infoStringForTitle:@"METRIC" andValue:metrics.name];
        self.title = [NSString stringWithFormat:@"%@ %@", portal.name, metrics.name];
    } else {
        metricLabel.text = @"";
        self.title = portal.name;
    }
    if (gType) {
        goalTypeLabel.attributedText = [self infoStringForTitle:@"GOAL TYPE" andValue:gType.name];
    } else {
        goalTypeLabel.text = @"";
    }
    if (reporting) {
        progressLabel.attributedText = [self infoStringForTitle:@"PROGRESS MARKERS" andValue:reporting.name];
    } else {
        progressLabel.text = @"";
    }
    
    overalGoalLabel.attributedText = [self infoStringForTitle:@"QUOTA METRIC QTY" andValue:self.goal.quota.formattedString];
    
    [self.tableView reloadData];
}

- (NSAttributedString *)infoStringForTitle:(NSString *)title andValue:(NSString *)value {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    [string.mutableString appendFormat:@"%@: %@", title, value];
    [string addFontWithName:@"HelveticaNeue-Bold" size:11 substring:string.string];
    [string addFontWithName:@"HelveticaNeue" size:11 substring:value];
    [string addColor:UIColorFromRGB(0x8C8C8C) substring:value];
    return string;
}

- (IBAction)messageAction {
    if (self.goal.userId == APP.user.userId)
        return;
    
    ChatViewController *controller = [[ChatViewController alloc] init];
    controller.userId = self.goal.userId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)showActions {
    
    NSArray *items = [self actions];
    
    if (items.count == 0)
        return;
    
    VGActionSheet *actionSheet = [[VGActionSheet alloc] init];
    actionSheet.items = items;
    actionSheet.selectionBlock = ^(NSInteger buttonIndex) {
        
        NSString *title = items[buttonIndex];
        
        if ([title isEqual:@"Invite to Team"]) {
            InviteToTeamViewController *controller = [[InviteToTeamViewController alloc] init];
            controller.goalId = self.goalId;
            [self presentTransparentController:controller animated:NO];
        } else if ([title isEqual:@"Update"]) {
            UpdateGoalViewController *controller = [[UpdateGoalViewController alloc] init];
            controller.goal = self.goal;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            [APP.menuController presentViewController:navigationController
                                             animated:YES
                                           completion:nil];
        } else if ([title isEqual:@"Edit Goal"]) {
            NewGoalViewController *controller = [[NewGoalViewController alloc] init];
            controller.portalId = self.goal.portalId;
            controller.goal = self.goal;
            controller.completionBlock = ^{
                [self.navigationController popViewControllerAnimated:YES];
            };
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            [APP.menuController presentViewController:navigationController
                                             animated:YES
                                           completion:nil];
        }
    };
    [actionSheet showInViewController:self];
}

- (NSArray *)actions {
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    if (self.goal.teamMember.boolValue || self.goal.managePermission.boolValue) {
        [actions addObject:@"Invite to Team"];
    }
    if (self.goal.typeId.integerValue != 1 && self.goal.typeId.integerValue != 5 && self.goal.typeId.integerValue != 2 && (self.goal.managePermission.boolValue || self.goal.teamMember.boolValue))
        [actions addObject:@"Update"];
    if (self.goal.managePermission.boolValue) {
        [actions addObject:@"Edit Goal"];
    }
    
    return actions;
}

#pragma mart TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4;
    } else {
        switch (segmentedControl.selectedSegmentIndex) {
            case 0:
                return feed.count;
                
            case 1:
                return 1;
                
            case 2:
                return team.count;
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            NSString *text = self.goal.about.stringByStrippingHTMLItems;
            if (text.length > 0) {
                UIFont *font = [UIFont boldSystemFontOfSize:13];
                CGFloat width = CGRectGetWidth(tableView.frame);
                CGFloat height = [UIUtils findHeightForText:text
                                                havingWidth:width
                                                    andFont:font];
                height += 4;
                
                height = MAX(35, height);
                
                return height;
            } else {
                return 0;
            }
        } else {
           return 35;
        }
    } else {
        switch (segmentedControl.selectedSegmentIndex) {
            case 0: {
                Feed *feedItem = feed[indexPath.row];
                CGFloat height = 95;
                if (feedItem.notes.length > 0) {
                    NSString *notes = [@"Notes: " stringByAppendingString:feedItem.notes];
                    CGFloat width = CGRectGetWidth(tableView.frame) - 81;
                    UIFont *font = [UIFont systemFontOfSize:12];
                    CGFloat textHeigh = [UIUtils findHeightForText:notes
                                                       havingWidth:width
                                                           andFont:font];
                    textHeigh += 80;
                    height = textHeigh;
                }
                if (feedItem.attachments.count > 0) {
                    CGFloat width = (CGRectGetWidth(tableView.frame) - 13) / 4;
                    height += (width - 15);
                }
                height = MAX(95, height);
                return height;
            }
                
            case 1:
                return 354;
                
            case 2:
                return 50;
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? 0 : CGRectGetHeight(headerView.frame);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return section == 0 ? nil : headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
        cell.button.userInteractionEnabled = NO;
        cell.arrow.hidden = YES;
        
        cell.button.hidden = indexPath.row == 1;
        cell.label.hidden = !cell.button.hidden;
        
        switch (indexPath.row) {
            case 0: {
                GoalMetrics *metric = [DataModel getGoalMetricsWithId:self.goal.metricId];
                if (metric)
                    cell.title = [@"Metric: " stringByAppendingString:metric.name];
                else
                    cell.title = @"Metric";
                break;
            }
                
            case 1:
                cell.label.text = [@"Description: " stringByAppendingString:self.goal.about.stringByStrippingHTMLItems];
                break;
                
            case 2:
                cell.title = [@"Quota: " stringByAppendingString:self.goal.quota.formattedString];
                break;
                
            case 3:
                cell.title = [@"Progress: " stringByAppendingString:self.goal.value.formattedString];
                break;
        }
        return cell;
        
    } else {
        switch (segmentedControl.selectedSegmentIndex) {
            case 0: {
                GoalsDetailFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GoalsDetailFeedCell"];
                cell.goal = self.goal;
                cell.feed = feed[indexPath.row];
                return cell;
            }
                
            case 1:
                return reportCell;
                
            case 2: {
                GoalsDetailTeamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GoalsDetailTeamCell"];
                cell.user = team[indexPath.row];
                return cell;
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1 && segmentedControl.selectedSegmentIndex == 2) {
        User *user = team[indexPath.row];
        ProfileViewController *controller = [[ProfileViewController alloc] init];
        controller.userId = user.userId;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (IBAction)OnChangeSegmentedController:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    /*if (sender.selectedSegmentIndex == 2) {
        AddView *view = [AddView addViewWithTitle:@"Invite Team Member"];
        [view addTarget:self action:@selector(inviteAction)];
        self.tableView.tableFooterView = view;
    } else {
        self.tableView.tableFooterView = nil;
    }*/
}

- (IBAction)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark barchart

- (NSUInteger)numberOfBarsInBarChart:(VGBarChart *)barChart {
    return barItems.count;
}

- (CGFloat)barChart:(VGBarChart *)barChart percentForBarAtIndex:(NSUInteger)index {
    
    Progress *progress = barItems[index];
    return progress.progress.floatValue;
}

/*- (CGFloat)barChart:(VGBarChart *)barChart predictablePercentForBarAtIndex:(NSUInteger)index {
    Progress *progress = barItems[index];
    return progress.progress.floatValue;
}*/

- (NSString *)barChart:(VGBarChart *)barChart textForBarAtIndex:(NSUInteger)index {
    Progress *progress = barItems[index];
    NSString *title = [NSString stringWithFormat:@"%.0f%%", progress.progress.floatValue * 100];
    return title;
}

- (NSString *)barChart:(VGBarChart *)barChart bottomTextForBarAtIndex:(NSUInteger)index {
    Progress *progress = barItems[index];
    return progress.dateStr;
}

@end
