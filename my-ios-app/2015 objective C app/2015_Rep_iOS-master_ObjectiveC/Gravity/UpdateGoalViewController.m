//
//  UpdateGoalViewController.m
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "UpdateGoalViewController.h"
#import "AttachmentsCell.h"
#import "AttachmentsViewController.h"

@interface UpdateGoalViewController ()

@end

@implementation UpdateGoalViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Update Goal";
        
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerCellClass:[AttachmentsCell class]];
    
    [metricField.formatter setDefaultOutputPattern:@"##########"];
    notesView.textContainer.lineFragmentPadding = 0;
    notesView.textContainerInset = UIEdgeInsetsMake(13, 0, 0, 0);
    
    self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
}

- (void)cancelAction {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    [self.view endEditing:YES];
    if (metricField.text.length == 0) {
        [SUPPORT showError:@"Metric qty must be filled"];
        return;
    }
    
    [SUPPORT showLoading:YES];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *filesParams = [[NSMutableDictionary alloc] init];
    
    params[@"goals_id"] = self.goal.goalId.stringValue;
    params[@"added_value"] = metricField.text;
    if (notesView.text.length > 0)
        params[@"note"] = notesView.text;
    
    if (self.photos.count > 0) {
        for (NSInteger i = 0; i < self.photos.count; i++) {
            [mediaArray addObject:@(i).stringValue];
            UIImage *image = self.photos[i];
            MediaData *mediaData = [[MediaData alloc] initWithData:UIImageJPEGRepresentation(image, 1.0) name:@"photo.jpg" contentType:@"image/jpg"];
            filesParams[[NSString stringWithFormat:@"aMultipleFiles[%@]", @(i).stringValue]] = mediaData;
        }
        params[@"aSources"] = mediaArray;
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
         fileParams:filesParams
                log:NO
           function:@"api_update_goal_filled_quota"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [SUPPORT showLoading:NO];
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    switch (indexPath.row) {
        case 0:
            return 44;
            
        case 1: {
            CGFloat height = [UIUtils findHeightForText:notesView.text
                                            havingWidth:CGRectGetWidth(tableView.frame) - 124
                                                andFont:notesView.font];
            height += 26;
            
            return MAX(44, height);
        }
            
        case 2:
            return 87;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0)
        return metricCell;
    else if (indexPath.row == 1)
        return notesCell;
    
    AttachmentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.titleLabel.text = @"Attachments";
    cell.photos = self.photos;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row != 2)
        return;
    
    AttachmentsViewController *controller = [[AttachmentsViewController alloc] init];
    controller.title = @"Attachments";
    controller.photos = self.photos;
    controller.photosBlock = ^(NSArray *photos) {
        self.photos = photos;
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark input

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end
