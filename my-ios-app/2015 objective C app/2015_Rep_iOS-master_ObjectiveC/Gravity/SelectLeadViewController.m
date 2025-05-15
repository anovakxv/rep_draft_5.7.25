//
//  SelectLeadViewController.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "SelectLeadViewController.h"
#import "ProfileCell.h"

@interface SelectLeadViewController ()

@end

@implementation SelectLeadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select Lead";
    [self.tableView registerCellClass:[ProfileCell class]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    ids = [[NSMutableSet alloc] init];
    
    if (self.multiselect) {
        [ids addObjectsFromArray:self.leadIds];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    }
    
    [self getUsers];
}

- (void)getUsers {
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"limit"] = @"1000";
    params[@"users_types_id"] = @"1";
    if (self.searchBar.text.length > 0)
        params[@"keyword"] = self.searchBar.text;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_get_users"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             users = [items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES]]];
             [self.tableView reloadData];
         }];
    }];
}

- (void)done {
    self.multiPickBlock(ids.allObjects);
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark searchbar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self getUsers];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.user = users[indexPath.row];
    if (self.multiselect) {
        NSString *imageName = [ids containsObject:cell.user.userId.stringValue] ? @"BtnSelected" : @"BtnSelection";
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    } else {
        cell.accessoryType = [cell.user.userId.stringValue isEqual:self.leadId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    User *user = users[indexPath.row];
    if (self.multiselect) {
        NSString *userId = user.userId.stringValue;
        if ([ids containsObject:userId]) {
            [ids removeObject:userId];
        } else {
            [ids addObject:userId];
        }
        [self.tableView reloadData];
    } else {
        
        self.pickBlock(user.userId.stringValue);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
