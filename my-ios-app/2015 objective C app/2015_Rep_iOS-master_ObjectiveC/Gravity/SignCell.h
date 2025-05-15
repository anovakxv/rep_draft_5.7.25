//
//  SignCell.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SZTextView.h>
#import <SHSPhoneTextField.h>
@interface SignCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet SHSPhoneTextField *phoneField;
@property (nonatomic, strong) IBOutlet SZTextView *textView;
@property (nonatomic, strong) NSString *title;

@end
