//
//  VGActionCell.m
//  Gravity
//
//  Created by Vlad Getman on 27.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "VGActionCell.h"

@implementation VGActionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.btn setBackgroundImage:[UIUtils roundedImageWithSize:self.btn.frame.size
                                                      andColor:UIColorFromRGB(0x9ED369)
                                                    withBorder:YES]
                        forState:UIControlStateNormal];
    self.btn.backgroundColor = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.btn setBackgroundImage:[UIUtils roundedImageWithSize:self.btn.frame.size
                                                      andColor:UIColorFromRGB(0x9ED369)
                                                    withBorder:YES]
                        forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.btn.highlighted = selected;
    [self performSelector:@selector(disableHighlight) withObject:nil afterDelay:0.1];
}

- (void)disableHighlight {
    self.btn.highlighted = NO;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.btn.highlighted = highlighted;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.btn.highlighted = YES;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self performSelector:@selector(disableHighlight) withObject:nil afterDelay:0.1];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self performSelector:@selector(disableHighlight) withObject:nil afterDelay:0.1];
}


@end
