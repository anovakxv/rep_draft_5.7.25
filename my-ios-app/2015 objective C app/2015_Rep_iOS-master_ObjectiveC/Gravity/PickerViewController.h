//
//  PickerViewController.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PickerViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    IBOutlet UITableViewCell *otherCell;
    IBOutlet UITextField *otherField;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL showOther;
@property (nonatomic, strong) NSString *manualCity;
@property (nonatomic, strong) void (^pickBlock)(NSInteger index);
@property (nonatomic, strong) void (^selectBlock)(PickerViewController *controller);

@end
