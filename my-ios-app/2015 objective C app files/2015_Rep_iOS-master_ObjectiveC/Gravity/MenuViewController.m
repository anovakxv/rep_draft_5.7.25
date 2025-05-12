//
//  MenuViewController.m
//  Gravity
//
//  Created by Vlad Getman on 14.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "MenuViewController.h"
#import "AppDelegate.h"
#import "ProfileViewController.h"
#import "MenuCell.h"
#import "EditProfileViewController.h"
#import "PaymentsViewController.h"
#import "SetAllViewController.h"
#import "TextViewController.h"

@interface MenuViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSArray *items;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    items = @[@"Payments", @"Privacy", /*@"Set All", */@"Policy", @"Log Out"];
    [self.tableView registerCellClass:[MenuCell class]];
    self.tableView.tableFooterView = [UIView new];
    
    for (UIView *view in @[self.tableView.tableHeaderView]) {
        UIView *separator = [view viewWithTag:100];
        CGRect frame = separator.frame;
        frame.size.height = 0.5;
        if (view == self.tableView.tableHeaderView)
            frame.origin.y += 0.5;
        separator.frame = frame;
    }
    
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2;
    self.photoView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.photoView.layer.borderWidth = 2;
    [self.photoView addTarget:self action:@selector(meAction)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (APP.user) {
        self.nameLabel.text = APP.user.fullName;
        [self.photoView sd_setImageWithURL:[NSURL URLWithString:APP.user.photo] placeholderImage:nil];
    }
}

- (void)meAction {
    EditProfileViewController *controller = [[EditProfileViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [APP.menuController presentViewController:navigationController animated:YES completion:nil];
    [APP.menuController showRootController:YES];
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    
    NSString *imageName = [NSString stringWithFormat:@"Menu%@", items[indexPath.row]];
    imageName = [imageName stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    cell.image.image = [UIImage imageNamed:imageName];
    cell.label.text = items[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 3) {
        [SUPPORT logout];
        [APP startLogin];
        return;
    }
    
    UIViewController *controller;
    
    switch (indexPath.row) {
        case 0: {
            controller = [[PaymentsViewController alloc] init];
            break;
        }
            
        /*case 2: {
            controller = [[SetAllViewController alloc] init];
            break;
        }*/
            
        case 1:
        case 2: {
            TextViewController *c = [[TextViewController alloc] init];
            c.policy = indexPath.row == 2;
            controller = c;
            break;
        }
    }
    
    if (controller) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [APP.menuController presentViewController:navigationController animated:YES completion:nil];
        [APP.menuController showRootController:YES];
        
        /*controller.hidesBottomBarWhenPushed = YES;
        [APP.menuController pushController:controller animated:YES];
        [APP.menuController showRootController:YES];*/
        /*UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [APP.menuController setRootController:navigationController animated:YES];*/
    } else {
        [APP.menuController showRootController:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
