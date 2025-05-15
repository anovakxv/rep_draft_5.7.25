//
//  PickerViewController.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "PickerViewController.h"

@interface PickerViewController ()

@end

@implementation PickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select";
    if (self.manualCity) {
        otherField.text = self.manualCity;
        self.selectedIndex = self.selectedIndex;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count + (self.showOther ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.titles.count) {
        return otherCell;
    }
    
    static NSString *MyIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    }
    cell.textLabel.text = self.titles[indexPath.row];
    
    if (self.selectedIndex != NSNotFound && indexPath.row == self.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    self.selectedIndex = indexPath.row;
    [self.tableView reloadData];
    
    if (indexPath.row == self.titles.count) {
        return;
    }
    
    [self done];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    otherCell.accessoryType = selectedIndex == self.titles.count ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.navigationItem.rightBarButtonItem = selectedIndex == self.titles.count ? [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)] : nil;
}

- (void)done {
    
    if (self.selectedIndex == self.titles.count && otherField.text.length == 0) {
        [SUPPORT showError:@"Other city must be filled"];
        return;
    }
    
    self.manualCity = otherField.text;
    
    if (self.pickBlock)
        self.pickBlock(self.selectedIndex);
    if (self.selectBlock)
        self.selectBlock(self);
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSMutableCharacterSet *filteredChars = [NSMutableCharacterSet letterCharacterSet];
    //[filteredChars formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *blockedCharSet = [filteredChars invertedSet];
    if (([string rangeOfCharacterFromSet:blockedCharSet].location != NSNotFound)) {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    return (newLength > 3) ? NO : YES;
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

@end
