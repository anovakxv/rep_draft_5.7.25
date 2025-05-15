//
//  DoubleImageCell.m
//  Gravity
//
//  Created by Vlad Getman on 10.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "DoubleImageCell.h"

@implementation DoubleImageCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setFirstImage:(id)firstImage {
    _firstImage = firstImage;
    [self setImage:firstImage forImageView:self.firstImageView];
}

- (void)setSecondImage:(id)secondImage {
    _secondImage = secondImage;
    [self setImage:secondImage forImageView:self.secondImageView];
}

- (void)setImage:(id)image forImageView:(UIImageView *)imageView {
    
    if (!image) {
        imageView.image = nil;
        return;
    }
    
    if ([image isKindOfClass:[UIImage class]]) {
        imageView.image = image;
    } else if ([image isKindOfClass:[NSString class]]) {
        imageView.image = [UIImage imageNamed:image];
    } else if ([image isKindOfClass:[NSDictionary class]]) {
        NSDictionary *photo = image;
        for (NSString *key in photo.allKeys) {
            if ([key rangeOfString:@"max_6"].location != NSNotFound) {
                [imageView sd_setImageWithURL:[NSURL URLWithString:[photo objectForKey:key]]];
                break;
            } else if ([key rangeOfString:@"original"].location != NSNotFound) {
                [imageView sd_setImageWithURL:[NSURL URLWithString:[photo objectForKey:key]]];
                break;
            }
        }
    }
}

@end
