//
//  AllCell.m
//  Gravity
//
//  Created by Vlad Getman on 24.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "AllCell.h"

@implementation AllCell

- (void)awakeFromNib {
    self.checkBtn.layer.cornerRadius = CGRectGetHeight(self.checkBtn.frame) / 2;
    self.checkBtn.layer.borderColor = [UIColor appGreen].CGColor;
    self.checkBtn.layer.borderWidth = 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

@end
