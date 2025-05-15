//
//  TextCell.m
//  Gravity
//
//  Created by Vlad Getman on 05.11.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "TextCell.h"

@implementation TextCell

- (void)awakeFromNib {
    self.textView.placeholder = @"Text";
    [self.textView setTextContainerInset:UIEdgeInsetsZero];
    self.textView.textContainer.lineFragmentPadding = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEditable:(BOOL)editable {
    _editable = editable;
    self.titleField.userInteractionEnabled = editable;
    self.textView.userInteractionEnabled = editable;
}

@end
