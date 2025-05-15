//
//  EditCell.m
//  Gravity
//
//  Created by Vlad Getman on 19.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "EditCell.h"

@implementation EditCell

- (void)awakeFromNib {
    [self.phoneField.formatter setDefaultOutputPattern:@"(###) ###-####"];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneField.placeholder = @"Phone";
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 0, 0, 0);
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.infoLabel.text = [title stringByAppendingString:@":"];
    self.textField.placeholder = title;
    self.phoneField.hidden = ![title isEqual:@"Phone"];
    self.textView.hidden = !([title isEqual:@"Broadcast"] || [title isEqual:@"Bio"]);
    self.textField.hidden = !self.phoneField.hidden || !self.textView.hidden;
    if ([title isEqual:@"Broadcast"] || [title isEqual:@"Bio"]) {
        self.textView.placeholder = title;
    }
    
    if ([title isEqual:@"Email"]) {
        self.textField.keyboardType = UIKeyboardTypeEmailAddress;
    } else {
        self.textField.keyboardType = UIKeyboardTypeDefault;
    }
    
    if ([title isEqual:@"Name"]) {
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else {
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    
    self.textField.secureTextEntry = [title isEqual:@"Password"];
    
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

@end
