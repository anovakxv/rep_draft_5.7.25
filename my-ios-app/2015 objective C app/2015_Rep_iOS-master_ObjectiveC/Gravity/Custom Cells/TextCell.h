//
//  TextCell.h
//  Gravity
//
//  Created by Vlad Getman on 05.11.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SZTextView.h>

@interface TextCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UITextField *titleField;
@property (nonatomic, strong) IBOutlet SZTextView *textView;

@property (nonatomic, assign) BOOL editable;

@end
