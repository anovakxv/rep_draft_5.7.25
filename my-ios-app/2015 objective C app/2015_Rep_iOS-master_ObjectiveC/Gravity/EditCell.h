//
//  EditCell.h
//  Gravity
//
//  Created by Vlad Getman on 19.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SHSPhoneTextField.h>
#import <SZTextView.h>

@interface EditCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet SHSPhoneTextField *phoneField;
@property (nonatomic, strong) IBOutlet SZTextView *textView;
@property (nonatomic, strong) NSString *title;

@end
