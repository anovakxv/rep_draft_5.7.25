//
//  VGActionSheet.m
//  Gravity
//
//  Created by Vlad Getman on 27.11.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "VGActionSheet.h"
#import "AppDelegate.h"
#import "VGActionCell.h"

@interface VGActionSheet () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation VGActionSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerCellClass:[VGActionCell class]];
    CGRect frame = APP.window.bounds;
    frame.size.height -= 49;
    if (frame.size.height > [self heigth]) {
        frame.size.height -= [self heigth];
        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor clearColor];
        self.tableView.tableHeaderView = view;
        self.tableView.scrollEnabled = NO;
    } else {
        self.tableView.tableHeaderView = nil;
        self.tableView.scrollEnabled = YES;
    }
    frame = self.tableView.frame;
    frame.origin.y += [self heigth];
    self.tableView.frame = frame;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showPicker:YES animated:YES];
}

- (void)showInViewController:(UIViewController *)controller; {
    self.view.frame = APP.window.frame;
    [APP.window.rootViewController addChildViewController:self];
    [APP.window.rootViewController.view addSubview:self.view];
}

- (IBAction)cancelAction {
    [self showPicker:NO animated:YES];
}

- (void)showPicker:(BOOL)show animated:(BOOL)animated {
    
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         CGRect frame = self.tableView.frame;
                         frame.origin.y -= show ? [self heigth] : (-[self heigth]);
                         self.tableView.frame = frame;
                     } completion:nil];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:!show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         self.view.alpha = show ? 1 : 0;
                     } completion:^(BOOL finished) {
                         if (!show) {
                             if (self.selectionBlock && self.tableView.indexPathForSelectedRow) {
                                 self.selectionBlock(self.tableView.indexPathForSelectedRow.section);
                             }
                             [self.view removeFromSuperview];
                             [self removeFromParentViewController];
                         }
                     }];
}

- (CGFloat)heigth {
    return (78 + 38) * self.items.count;
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 78;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 38;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VGActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    [cell.btn setTitle:self.items[indexPath.section] forState:UIControlStateNormal];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self cancelAction];
}

@end
