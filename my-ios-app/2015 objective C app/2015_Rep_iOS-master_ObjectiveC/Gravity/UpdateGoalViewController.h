//
//  UpdateGoalViewController.h
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SHSPhoneTextField.h>

@interface UpdateGoalViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate> {
    IBOutlet UITableViewCell *metricCell;
    IBOutlet UITableViewCell *notesCell;
    
    IBOutlet SHSPhoneTextField *metricField;
    IBOutlet UITextView *notesView;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Goal *goal;
@property (nonatomic, strong) NSArray *photos;

@end
