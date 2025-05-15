//
//  SignCell.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "SignCell.h"

@implementation SignCell

- (void)awakeFromNib {
    [self.phoneField.formatter setDefaultOutputPattern:@"(###) ###-####"];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 0, 0, 0);
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.infoLabel.text = title;
    //self.textField.placeholder = title;
    self.phoneField.hidden = !([title isEqual:@"Phone"] || [title isEqual:@"Quota"] || [title isEqual:@"Rep Commision % (Optional)"]);
    self.textView.hidden = !([title isEqual:@"Broadcast"] || [title isEqual:@"Bio"] || [title isEqual:@"Description"] || [title isEqual:@"About"]);
    self.textField.hidden = !self.phoneField.hidden || !self.textView.hidden;
    
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
    
    self.textField.secureTextEntry = [title rangeOfString:@"Password"].location != NSNotFound;
    
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}


@end
