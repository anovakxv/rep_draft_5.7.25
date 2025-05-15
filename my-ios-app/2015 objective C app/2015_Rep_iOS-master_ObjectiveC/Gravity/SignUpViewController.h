//
//  SignUpViewController.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "VGViewController.h"

@interface SignUpViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
    
    UIImage *photo;
    NSArray *titles;
    NSMutableDictionary *params;
    NSArray *cities;
    NSArray *userTypes;
    NSArray *skills;
    NSMutableDictionary *skillIds;
    
    IBOutlet UIButton *registrationBtn;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
