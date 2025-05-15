//
//  SetAllViewController.m
//  Gravity
//
//  Created by Vlad Getman on 24.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "SetAllViewController.h"
#import "AllCell.h"
#import "EcoLoginViewController.h"
#import "AppDelegate.h"

@interface SetAllViewController ()

@end

@implementation SetAllViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Set ALL";
        
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
        
        selectedEcosystems = [[NSMutableSet alloc] init];
        ecosystems = @[@"Rep", @"Hub", @"System Testers"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerCellClass:[AllCell class]];
    self.tableView.tableFooterView = [UIView new];
    
    BOOL admin = YES;
    if (admin) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 54, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        
        [addBtn setBackgroundImage:[UIUtils roundedImageWithSize:addBtn.frame.size andColor:addBtn.backgroundColor withBorder:YES]
                          forState:UIControlStateNormal];
        addBtn.backgroundColor = nil;
        
        addBtn.hidden = NO;
    }
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    EcoLoginViewController *controller = [[EcoLoginViewController alloc] init];
    controller.completionBlock = ^() {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)addAll {
    
}

#pragma mark tableviw

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ecosystems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AllCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.nameLabel.text = ecosystems[indexPath.row];
    cell.checkBtn.selected = [selectedEcosystems containsObject:ecosystems[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([selectedEcosystems containsObject:ecosystems[indexPath.row]]) {
        [selectedEcosystems removeObject:ecosystems[indexPath.row]];
    } else {
        [selectedEcosystems addObject:ecosystems[indexPath.row]];
    }
    [tableView reloadData];
}

@end
