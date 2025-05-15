//
//  ImageCell.m
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "ImageCell.h"

@implementation ImageCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setImage:(id)image {
    _image = image;
    if ([image isKindOfClass:[NSString class]]) {
        self.imageView.image = [UIImage imageNamed:image];
    } else if ([image isKindOfClass:[NSDictionary class]]) {
        NSString *photoUrl;
        NSDictionary *photo = image;
        for (NSString *key in photo.allKeys) {
            if ([key rangeOfString:@"max_6"].location != NSNotFound) {
                photoUrl = [photo objectForKey:key];
                break;
            } else if ([key rangeOfString:@"original"].location != NSNotFound) {
                photoUrl = [photo objectForKey:key];
                break;
            }
        }
        if (photoUrl) {
            __weak typeof(self) weakSelf = self;
            [self.imageView setImageWithURL:[NSURL URLWithString:photoUrl]
                           placeholderImage:nil
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                      weakSelf.imageView.image = image;
                                  } usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

            /*[self.imageView setImageWithURL:[NSURL URLWithString:photoUrl]
                usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];*/
        }
    } else if ([image isKindOfClass:[UIImage class]]) {
        self.imageView.image = image;
    }
}

@end
