//
//  InviteViewController.m
//  Gravity
//
//  Created by Vlad Getman on 17.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "InviteViewController.h"
#import "PeopleCell.h"
#import "GoalsCell.h"

@interface InviteViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerCellClass:[PeopleCell class]
                       withIdentifier:@"PeopleCell"];
    [self.tableView registerCellClass:[GoalsCell class]
                       withIdentifier:@"GoalsCell"];
    
    if (self.invite.inbox.boolValue) {
        self.tableView.tableFooterView = actionsView;
        
        for (UIButton *btn in @[acceptBtn, declineBtn]) {
            [btn setBackgroundImage:[UIUtils roundedImageWithSize:btn.frame.size
                                                         andColor:btn.backgroundColor
                                                       withBorder:YES]
                           forState:UIControlStateNormal];
            btn.backgroundColor = nil;
        }
    } else {
        okBtn.hidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showPicker:YES animated:YES];
}

- (IBAction)inviteAction:(UIButton *)sender {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (sender == okBtn) {
        params[@"todo"] = @"mark_as_read";
    } else if (sender == acceptBtn) {
        params[@"todo"] = @"accept";
    } else {
        params[@"todo"] = @"decline";
    }
    
    params[@"aGoalsIDs"] = @[self.invite.goalId.stringValue];
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_manage_goals_invites"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self showPicker:NO animated:YES];
        }
        
    }];
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.invite.inbox.boolValue ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 2 ? 0 : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 64;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 64)];
    view.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(13, 38, CGRectGetWidth(tableView.frame) - 26, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor appGreen];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
    
    if (section == 0) {
        label.text = @"Rep:";
    } else if (section == 1) {
        if (self.invite.inbox.boolValue) {
            label.text = @"Has Invited you to Join:";
        } else {
            label.text = [NSString stringWithFormat:@"Has %@ your Invitation to:", self.invite.confirmed.boolValue ? @"ACCEPTED" : @"DECLINED"];
        }
    } else {
        label.text = @"Action:";
    }
    
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeopleCell"];
        cell.user = [DataModel getUserWithId:self.invite.userId1];
        return cell;
    } else if (indexPath.section == 1) {
        GoalsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GoalsCell"];
        cell.goal = [DataModel getGoalWithId:self.invite.goalId];
        return cell;
    }
    
    return [UITableViewCell new];
}

#pragma mark UI

- (void)showPicker:(BOOL)show animated:(BOOL)animated {
    
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         CGRect frame = contentView.frame;
                         frame.origin.y = show ? 0 : CGRectGetHeight(self.view.frame);
                         contentView.frame = frame;
                     } completion:nil];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:!show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         self.view.alpha = show ? 1 : 0;
                     } completion:^(BOOL finished) {
                         if (!show) {
                             if (self.delegate)
                                 [self.delegate inviteControllerClosed];
                             [self dismissViewControllerAnimated:NO completion:nil];
                         }
                     }];
}


@end
