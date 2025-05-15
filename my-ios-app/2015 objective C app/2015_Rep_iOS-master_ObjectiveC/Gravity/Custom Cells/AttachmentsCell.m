//
//  AttachmentsCell.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "AttachmentsCell.h"

@implementation AttachmentsCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSection:(id)section {
    _section = section;
    if ([section isKindOfClass:[NSDictionary class]]) {
        self.photos = section[@"files"];
        self.titleLabel.text = section[@"title"];
    }
}

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    self.countLabel.text = @(photos.count).stringValue;
    self.image = photos.count > 0 ? [photos lastObject] : [UIImage imageNamed:@"GrapgicsPlaceholder"];
}

- (void)setImage:(id)image {
    _image = image;
    if ([image isKindOfClass:[NSString class]]) {
        self.photoView.image = [UIImage imageNamed:image];
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
            [self.photoView setImageWithURL:[NSURL URLWithString:photoUrl]
                           placeholderImage:nil
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                      weakSelf.photoView.image = image;
                                  } usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            /*[self.imageView setImageWithURL:[NSURL URLWithString:photoUrl]
             usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];*/
        }
    } else if ([image isKindOfClass:[UIImage class]]) {
        self.photoView.image = image;
    }
}

@end
