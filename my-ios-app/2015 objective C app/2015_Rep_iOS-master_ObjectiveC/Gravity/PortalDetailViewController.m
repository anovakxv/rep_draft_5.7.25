//
//  PatnersDetailViewController.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "PortalDetailViewController.h"
#import "PortalCell.h"
#import "GoalsCell.h"
#import "ScrollPhotoCell.h"
#import "LogosCell.h"
#import "ActionCell.h"
#import "GoalsDetailViewController.h"
#import "NewGoalViewController.h"
#import "NewProductViewController.h"
#import "AppDelegate.h"
#import "ProductCell.h"
#import "TextCell.h"
#import "NewPortalViewController.h"
#import "ChatViewController.h"
#import "VGActionSheet.h"
#import "BuyViewController.h"
#import "ProfileViewController.h"
#import "LeadCell.h"
#import "InviteToTeamViewController.h"

@interface PortalDetailViewController ()

@end

@implementation PortalDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        values = [[NSMutableDictionary alloc] init];
        
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
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadContent) forControlEvents:UIControlEventValueChanged];
    refreshControl.layer.masksToBounds = YES;
    [self.tableView insertSubview:refreshControl atIndex:0];
    
    [self.tableView registerCellClass:[LogosCell class]
                       withIdentifier:@"LogosCell"];
    [self.tableView registerCellClass:[ScrollPhotoCell class]
                       withIdentifier:@"ScrollPhotoCell"];
    [self.tableView registerCellClass:[GoalsCell class]
                       withIdentifier:@"GoalsCell"];
    [self.tableView registerCellClass:[ProductCell class]
                       withIdentifier:@"ProductCell"];
    [self.tableView registerCellClass:[ActionCell class]
                       withIdentifier:@"ActionCell"];
    [self.tableView registerCellClass:[TextCell class]
                       withIdentifier:@"TextCell"];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 49, 0);
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.collectionView registerCellClass:[LeadCell class]];
    
    portal = [DataModel getPortalWithId:self.portalId];
    
    for (UIButton *btn in @[actionButton, deleteButton]) {
        [btn setBackgroundImage:[UIUtils roundedImageWithSize:btn.frame.size
                                                     andColor:btn.backgroundColor
                                                   withBorder:YES]
                       forState:UIControlStateNormal];
        btn.backgroundColor = nil;
    }
    
    [self reloadData];
    [self getPortal];
    [self getGoals];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //APP.menuController.pan.enabled = NO;
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //APP.menuController.pan.enabled = YES;
}

- (void)reloadData {
    self.title = portal.name;
    descriptionLabel.text = portal.about.stringByStrippingHTMLItems;
    
    leads = @[portal.userId.stringValue];
    if (portal.leads.count > 0)
        leads = [leads arrayByAddingObjectsFromArray: portal.leads];
    
    [self.collectionView reloadData];
    [self.tableView reloadData];
    if (refreshControl.isRefreshing)
        [refreshControl endRefreshing];
}

- (IBAction)messageAction {
    
    [SUPPORT showLoading:YES];
    
    NSDictionary *params = @{@"portals_id":self.portalId.stringValue,
                             @"lat":@([SUPPORT getLocation].coordinate.latitude).stringValue,
                             @"lng":@([SUPPORT getLocation].coordinate.longitude).stringValue,
                             @"distance":@"100",
                             @"restrict_by_distance":@"1"};
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_get_portal_nearest_rep"
    completionBlock:^(NSDictionary *json, NSError *error) {
        
        [SUPPORT showLoading:NO];
        
        if (error) {
            [SUPPORT showError:error.localizedDescription];
            return;
        }
        
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             
             User *user = [items firstObject];
             if (!user)
                 return;
             
             ChatViewController *controller = [[ChatViewController alloc] init];
             controller.userId = user.userId;
             controller.hidesBottomBarWhenPushed = YES;
             [self.navigationController pushViewController:controller animated:YES];
         }];
    }];
}

- (IBAction)showActions {
    
    if (actionButton.selected) {
        NSInteger sum = 0;
        NSMutableArray *prdcts = [[NSMutableArray alloc] init];
        for (Product *p in products) {
            if ([values.allKeys indexOfObject:p.productId.stringValue] != NSNotFound) {
                [prdcts addObject:p];
                NSInteger count = [values[p.productId.stringValue] integerValue];
                sum += count * p.price.integerValue;
            }
        }
        if (sum >= 10000) {
            [SUPPORT showAlert:@"Please message a Lead Rep for Offering transactions over $10,000" body:nil];
            return;
        }
        BuyViewController *controller = [[BuyViewController alloc] init];
        controller.values = values;
        controller.products = prdcts;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.navigationBarHidden = YES;
        [self presentTransparentController:navigationController animated:NO];
        return;
    }
    
    VGActionSheet *actionSheet = [[VGActionSheet alloc] init];
    actionSheet.items = @[@"Join Team", @"Share", @"Support"];
    if (portal.userId.integerValue == APP.user.userId.integerValue && APP.user.userTypeId.integerValue == 1) {
        actionSheet.items = [actionSheet.items arrayByAddingObject:@"Edit Portal"];
    }
    
    actionSheet.selectionBlock = ^(NSInteger buttonIndex) {
        
        
        switch (buttonIndex) {
            case 0:
            case 1: {
                InviteToTeamViewController *controller = [[InviteToTeamViewController alloc] init];
                controller.userId = APP.user.userId;
                controller.portalId = self.portalId;
                controller.sharing = buttonIndex == 1;
                [self presentTransparentController:controller animated:NO];
                break;
            }
                
            case 2: {
                if (segmentedControl.selectedSegmentIndex != 1) {
                    [segmentedControl setSelectedSegmentIndex:1];
                    [self OnChangeSegmentedController:segmentedControl];
                }
                if (![self hasPurchases]) {
                    [self showBuyPrompt];
                } else {
                    [self showActions];
                }
                break;
        }
        
            case 3: {
                NewPortalViewController *controller = [[NewPortalViewController alloc] init];
                controller.portal = portal;
                controller.completionBlock = ^() {
                    [self.navigationController popViewControllerAnimated:NO];
                };
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                [self.navigationController presentViewController:navigationController animated:YES completion:nil];
                break;
            }
        }
    };
    [actionSheet showInViewController:self];
}

- (void)showBuyPrompt {
    [SUPPORT showAlert:@"Please Select Offering"
                  body:nil];
}

- (BOOL)hasPurchases {
    if (values.allKeys.count == 0) {
        return NO;
    } else {
        NSInteger sum = 0;
        for (NSString *key in values.allKeys) {
            NSInteger count = [values[key] integerValue];
            sum += count;
            if (sum > 0) break;
        }
        if (sum == 0) {
            return NO;
        }
    }
    return YES;
}

- (void)updateAction {
    BOOL hasPurchases = [self hasPurchases];
    if (segmentedControl.selectedSegmentIndex != 1)
        hasPurchases = NO;
    
    [actionButton setTitle:hasPurchases ? @"Support" : @"+" forState:UIControlStateNormal];
    actionButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, hasPurchases ? 4 : 12, 0);
    actionButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold"
                                                   size:hasPurchases ? 18 : 40];
    actionButton.selected = hasPurchases;
}

- (IBAction)deleteAction {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete Portal and associated goals?"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex)
        return;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":self.portalId.stringValue}
                log:NO
           function:@"api_delete_portal"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mart TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger sections = segmentedControl.selectedSegmentIndex == 0 ? 4 : 2;
    
    if (segmentedControl.selectedSegmentIndex != 0) {
        BOOL acceptAdding = NO;
        if (portal) {
            acceptAdding = (portal.userId.integerValue == APP.user.userId.integerValue || [leads indexOfObject:APP.user.userId.stringValue] != NSNotFound) && APP.user.userTypeId.integerValue == 1;
        }
        
        if (acceptAdding) {
            sections++;
        }
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            switch (section) {
                case 1:
                    return 2;
                    
                case 2:
                    return portal.texts.count;
                    
                case 3:
                    return portal.sections.count - 1;
            };
            
        case 1:
            return section == 1 ? products.count : 1;
            
        case 2:
            return section == 1 ? goals.count : 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            if (!portal)
                return 0;
            else if (portal.sections.count == 0)
                return 0;
            else
                return [ScrollPhotoCell imageSize].height + 1;
            
        } else {
            return CGRectGetHeight(controlCell.frame);
        }
        
    } else if (indexPath.section == 1) {
        
        if (segmentedControl.selectedSegmentIndex == 0) {
            if (indexPath.row == 0) {
                return 56;
            } else {
                CGFloat height = [UIUtils findHeightForText:descriptionLabel.text
                                                havingWidth:CGRectGetWidth(tableView.frame) - 20
                                                    andFont:descriptionLabel.font];
                
                return height + 35;
            }
        } else {
            return segmentedControl.selectedSegmentIndex < 3 ? 90 : 50;
        }
    } else if (indexPath.section == 2 && segmentedControl.selectedSegmentIndex != 0) {
        return 35;
    } else if (indexPath.section == 2 && segmentedControl.selectedSegmentIndex == 0) {
        CGFloat height = [UIUtils findHeightForText:[portal.texts[indexPath.row] objectForKey:@"text"]
                                        havingWidth:CGRectGetWidth(tableView.frame) - 20
                                            andFont:[UIFont systemFontOfSize:14]];
        height += 30;
        
        height = MAX(44, height);
        
        return height;
    } else if (indexPath.section == 3 && segmentedControl.selectedSegmentIndex == 0) {
        return [LogosCell size].height + 19;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ScrollPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScrollPhotoCell"];
            if (portal) {
                if (portal.sections.count == 0) {
                    return [UITableViewCell new];
                }
                GraphicSection *section = [portal.sections.array firstObject];
                cell.photos = section.files;
                [cell.collectionView reloadData];
            } else {
                return [UITableViewCell new];
            }
            return cell;
        } else {
            return controlCell;
        }
    } else if (indexPath.section == 1) {
        switch (segmentedControl.selectedSegmentIndex) {
            case 0: {
                switch (indexPath.row) {
                    case 0:
                        return leadCell;
                        
                    case 1:
                        return descriptionCell;
                }
            }
                
            case 1: {
                ProductCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProductCell"];
                Product *product = products[indexPath.row];
                cell.product = product;
                cell.count = [values[product.productId.stringValue] integerValue];
                cell.changeBlock = ^(NSInteger count) {
                    if (count == 0) {
                        [values removeObjectForKey:product.productId.stringValue];
                    } else {
                        values[product.productId.stringValue] = @(count).stringValue;
                    }
                    [self updateAction];
                };
                return cell;
            }
                
            case 2: {
                GoalsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GoalsCell"];
                cell.goal = goals[indexPath.row];
                return cell;
            }
        }
    } else if (indexPath.section == 2 && segmentedControl.selectedSegmentIndex != 0) {
        
        ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
        cell.title = segmentedControl.selectedSegmentIndex == 1 ? @"Add Offering" : @"Add Goal";
        return cell;
        
    } else if (indexPath.section == 2 && segmentedControl.selectedSegmentIndex == 0) {
        TextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextCell"];
        cell.editable = NO;
        cell.titleField.text = [[portal.texts[indexPath.row] objectForKey:@"title"] stringByStrippingHTMLItems];
        cell.textView.text = [[portal.texts[indexPath.row] objectForKey:@"text"] stringByStrippingHTMLItems];
        return cell;
    } else if (indexPath.section == 3 && segmentedControl.selectedSegmentIndex == 0) {
        LogosCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogosCell"];
        GraphicSection *section = portal.sections[indexPath.row + 1];
        cell.photos = section.files;
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && segmentedControl.selectedSegmentIndex == 2) {
        Goal *goal = goals[indexPath.row];
        /*
        //uncomment it when you want to show goals detials
        //only for goal's team
        if (!goal.teamMember.boolValue)
            return;
        */
        GoalsDetailViewController *controller = [[GoalsDetailViewController alloc] init];
        controller.goal = goal;
        controller.goalId = goal.goalId;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.section == 2) {
        if (segmentedControl.selectedSegmentIndex == 1) {
            [self addProduct];
        } else if (segmentedControl.selectedSegmentIndex == 2) {
            [self addGoal];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1 && segmentedControl.selectedSegmentIndex == 1) {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Product *product = products[indexPath.row];
    [SUPPORT showLoading:YES];
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"products_id":product.productId.stringValue}
                log:NO
           function:@"api_delete_product"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [tableView beginUpdates];
            
            NSMutableArray *p = [[NSMutableArray alloc] initWithArray:products];
            [p removeObjectAtIndex:indexPath.row];
            products = [NSArray arrayWithArray:p];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [tableView endUpdates];
        }
        [SUPPORT showLoading:NO];
    }];
}

- (void)reloadContent {
    switch (segmentedControl.selectedSegmentIndex) {
        
        case 0:
            [self getPortal];
            break;
            
        case 1:
            [self getProducts];
            break;
            
        case 2:
            [self getGoals];
            
        default:
            [refreshControl endRefreshing];
            break;
    }
}

- (IBAction)OnChangeSegmentedController:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    [self updateAction];
    switch (sender.selectedSegmentIndex) {
        case 1:
            [self getProducts];
            break;
            
        case 2:
            [self getGoals];
            break;
    }
}

#pragma mark collectionview

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return leads.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LeadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.userId = leads[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.userId = @([leads[indexPath.row] integerValue]);
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - server side

- (void)getPortal {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":portal.portalId.stringValue}
                log:NO
           function:@"api_portal_details"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_PORTAL
         withCompletition:^(NSArray *items) {
             if (items.count > 0) {
                 portal = [items firstObject];
                 [self reloadData];
             }
         }];
    }];
}

- (void)getGoals {
    
    NSDictionary *params = @{@"portals_id":self.portalId.stringValue,
                             @"limit":@"200",
                             @"offset":@"0",
                             @"seconds_from_gmt":@([[NSTimeZone localTimeZone] secondsFromGMT]).stringValue};
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_get_goals"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_GOALS
         withCompletition:^(NSArray *items) {
             goals = items;
             [self reloadData];
         }];
    }];
}

- (void)getProducts {
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"portals_id":self.portalId.stringValue,@"limit":@"200",@"offset":@"0"}
                log:NO
           function:@"api_get_products"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_PRODUCTS
         withCompletition:^(NSArray *items) {
             products = items;
             [self reloadData];
         }];
    }];
}

- (void)addProduct {
    NewProductViewController *controller = [[NewProductViewController alloc] init];
    controller.portalId = self.portalId;
    UINavigationController *navigationControlller = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationControlller animated:YES completion:nil];
}

- (void)addGoal {
    NewGoalViewController *controller = [[NewGoalViewController alloc] init];
    controller.portalId = self.portalId;
    UINavigationController *navigationControlller = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationControlller animated:YES completion:nil];
}

- (IBAction)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
