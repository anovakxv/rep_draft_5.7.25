//
//  EditProfileViewController.h
//  Gravity
//
//  Created by Vlad Getman on 19.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditProfileViewController : VGViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate> {
    IBOutlet UIImageView *photoView;
    UIImage *photo;
    NSArray *titles;
    NSMutableDictionary *params;
    NSArray *cities;
    NSArray *userTypes;
    NSArray *skills;
    NSMutableDictionary *skillIds;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic) BOOL newUser;

- (IBAction)photoAction;

@end
