//
//  NewGoalViewController.m
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "NewGoalViewController.h"
#import "AppDelegate.h"
#import "SignCell.h"
#import "PickerViewController.h"
#import "SelectLeadViewController.h"

@interface NewGoalViewController ()

@end

@implementation NewGoalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = cancelBtn;
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = doneBtn;
        
        types = [DATA fetchData:@"GoalType" withDescriptor:nil withPredicate:nil withAttributes:nil];
        reporting = [DATA fetchData:@"ReportingIncrement" withDescriptor:nil withPredicate:nil withAttributes:nil];
        
        params = [[NSMutableDictionary alloc] init];
        
        titles = @[@"Rep", @"Goal Type", @"Quota", /*@"Rep Commision % (Optional)", */@"Goal Leader Rep", @"Description", @"Reporting Increment"];
        keys = @[@"portals_id", @"goal_types_id", @"quota", /*@"rep_commission", */@"lead_id", @"description", @"reporting_increments_id"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerCellClass:[SignCell class]
                       withIdentifier:@"SignCell"];
    
    self.title = self.goal ? @"Edit Goal" : @"New Goal";
    
    params[@"portals_id"] = self.portalId.stringValue;
    params[@"lead_id"] = APP.user.userId.stringValue;
    if (self.goal) {
        bottomBar.hidden = NO;
        [deleteBtn setBackgroundImage:[UIUtils roundedImageWithSize:deleteBtn.frame.size
                                                           andColor:deleteBtn.backgroundColor
                                                         withBorder:YES]
                             forState:UIControlStateNormal];
        deleteBtn.backgroundColor = nil;
        self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 49, 0);
        [self reloadData];
    }
}

- (void)reloadData {
    params[@"goals_id"] = self.goal.goalId.stringValue;
    params[@"lead_id"] = self.goal.leadId.stringValue;
    params[@"goal_types_id"] = self.goal.typeId.stringValue;
    params[@"quota"] = self.goal.quota.stringValue;
    params[@"rep_commission"] = self.goal.repCommission.stringValue;
    params[@"lead_id"] = self.goal.leadId.stringValue;
    params[@"description"] = self.goal.about.stringByStrippingHTMLItems;
    params[@"reporting_increments_id"] = self.goal.reportingIncrementsId.stringValue;
    [self.tableView reloadData];
}

- (IBAction)deleteGoal {
    [UIAlertView showWithTitle:@"Are you sure you want to delete Goal?"
                       message:nil
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (alertView.cancelButtonIndex == buttonIndex)
                              return;
                          [DataMNG JSONTo:kServerUrl
                           withDictionary:@{@"goals_id":self.goal.goalId.stringValue}
                                      log:NO
                                 function:@"api_delete_goal"
                          completionBlock:^(NSDictionary *json, NSError *error) {
                              if (error) {
                                  [SUPPORT showError:error.localizedDescription];
                              } else {
                                  if (self.completionBlock)
                                      self.completionBlock();
                                  
                                  [self.navigationController dismissViewControllerAnimated:YES
                                                                                completion:nil];
                              }
                          }];
                      }];
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    
    for (NSInteger i = 0; i < titles.count; i++) {
        if (i != 3) {
            NSString *value = params[keys[i]];
            if (value.length == 0) {
                NSString *title = titles[i];
                NSString *action = (i == 2 || i == 5) ? @"filled" : @"selected";
                NSString *error = [NSString stringWithFormat:@"%@ must be %@", title, action];
                [SUPPORT showError:error];
                return;
            }
        }
    }
    
    [self createAction];
}


- (void)createAction {
    [SUPPORT showLoading:YES];
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:self.goal ? @"api_edit_goal" : @"api_create_goal"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self cancelAction];
        }
        [SUPPORT showLoading:NO];
    }];
}


#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 6) {
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        CGFloat titleWidth = [UIUtils findWidthForText:titles[indexPath.row]
                                          havingHeight:21
                                               andFont:font];
        titleWidth = MAX(titleWidth, 45);
        CGFloat viewWidth = CGRectGetWidth(tableView.frame) - titleWidth - 36 - 10;
        CGFloat height = [UIUtils findHeightForText:@"description"
                                        havingWidth:viewWidth
                                            andFont:font];
        
        height += 26;
        return MAX(44, height);
    }
    
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SignCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SignCell"];
    cell.title = titles[indexPath.row];
    cell.textField.delegate = self;
    cell.phoneField.delegate = self;
    cell.textView.delegate = self;
    cell.textField.text = params[keys[indexPath.row]];
    
    BOOL selection = [self needPickerForTitle:cell.title];
    cell.accessoryType = selection ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = selection ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    cell.textField.userInteractionEnabled = !selection && ![cell.title isEqual:@"Rep"];
    [cell.phoneField.formatter setDefaultOutputPattern:[cell.title isEqual:@"Quota"] ? @"########" : @"##"];
    if (!cell.phoneField.hidden) {
        [cell.phoneField setFormattedText:params[keys[indexPath.row]]];
    }
    if (!cell.textView.hidden) {
        cell.textView.text = params[keys[indexPath.row]];
    }
    
    if ([cell.title isEqual:@"Rep"]) {
        Portal *portal = [DataModel getPortalWithId:self.portalId];
        cell.textField.text = portal.name;
    } else if ([cell.title isEqual:@"Goal Type"]) {
        NSNumber *typeId = @([params[@"goal_types_id"] integerValue]);
        GoalType *goalType = [DataModel getGoalTypeWithId:typeId];
        cell.textField.text = goalType.name;
    } else if ([cell.title isEqual:@"Goal Leader Rep"]) {
        NSNumber *leadId = @([params[@"lead_id"] integerValue]);
        User *user = [DataModel getUserWithId:leadId];
        cell.textField.text = user.fullName;
    } else if ([cell.title isEqual:@"Reporting Increment"]) {
        NSNumber *incrementId = @([params[@"reporting_increments_id"] integerValue]);
        ReportingIncrement *increment = [DataModel getReportingIncrementWithId:incrementId];
        cell.textField.text = increment.name;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self needPickerForTitle:titles[indexPath.row]]) {
        [self.view endEditing:YES];
        UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                    initWithTitle:@" "
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:nil];
        self.navigationController.navigationBar.topItem.backBarButtonItem =btnBack;
        
        NSString *title = titles[indexPath.row];
        
        if ([title isEqual:@"Goal Leader Rep"]) {
            SelectLeadViewController *controller = [[SelectLeadViewController alloc] init];
            controller.leadId = params[@"lead_id"];
            controller.pickBlock = ^(NSString *leadId) {
                params[@"lead_id"] = leadId;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            PickerViewController *controller = [[PickerViewController alloc] init];
            NSInteger index = 0;
            if (indexPath.row == 1) {
                GoalType *goalType = [[types filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"goalTypeId == %@", @([params[@"goal_types_id"] integerValue])]] firstObject];
                index = [types indexOfObject:goalType];
                
                controller.titles = [types valueForKey:@"name"];
            } else {
                ReportingIncrement *increment = [[reporting filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"reportingIncrementId == %@", @([params[@"reporting_increments_id"] integerValue])]] firstObject];
                index = [reporting indexOfObject:increment];
                
                controller.titles = [reporting valueForKey:@"name"];
            }
            controller.selectedIndex = index;
            controller.pickBlock = ^(NSInteger index) {
                if (indexPath.row == 1) {
                    GoalType *goalType = types[index];
                    params[@"goal_types_id"] = goalType.goalTypeId.stringValue;
                } else {
                    ReportingIncrement *increment = reporting[index];
                    params[@"reporting_increments_id"] = increment.reportingIncrementId.stringValue;
                }
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

#pragma mark - text


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)needPickerForTitle:(NSString *)title {
    return ([title isEqual:@"Goal Type"] || [title isEqual:@"Goal Leader Rep"] || [title isEqual:@"Reporting Increment"]);
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGPoint center = textField.center;
    CGPoint rootViewPoint = [textField.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        NSString *text = textField.text;
        if ([textField isKindOfClass:[SHSPhoneTextField class]]) {
            SHSPhoneTextField *field = (SHSPhoneTextField *)textField;
            text = field.phoneNumber;
        }
        params[keys[indexPath.row]] = text;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        params[keys[indexPath.row]] = textView.text;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        params[keys[indexPath.row]] = textView.text;
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}


@end
