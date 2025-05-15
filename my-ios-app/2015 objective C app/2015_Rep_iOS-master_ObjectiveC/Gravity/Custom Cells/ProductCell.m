//
//  ProductCell.m
//  Gravity
//
//  Created by Vlad Getman on 28.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "ProductCell.h"

@implementation ProductCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setProduct:(Product *)product {
    _product = product;
    
    self.nameLabel.text = product.name.stringByStrippingHTMLItems;
    self.subtitleLabel.text = product.subtitle.stringByStrippingHTMLItems;
    self.priceLabel.text = product.price.priceValue;
    
    if (product.photo.length > 0) {
        [self.logoView sd_setImageWithURL:[NSURL URLWithString:product.photo]];
    } else if (product.photos.count > 0) {
        NSDictionary *photo = [product.photos firstObject];
        for (NSString *key in photo.allKeys) {
            if ([key rangeOfString:@"max_6"].location != NSNotFound) {
                [self.logoView sd_setImageWithURL:[NSURL URLWithString:[photo objectForKey:key]]];
                break;
            } else if ([key rangeOfString:@"original"].location != NSNotFound) {
                [self.logoView sd_setImageWithURL:[NSURL URLWithString:[photo objectForKey:key]]];
                break;
            }
        }
    } else {
        self.logoView.image = [UIImage imageNamed:@"example_logo1"];
    }
}

- (void)setCount:(NSInteger)count {
    _count = count;
    if (count == 0) {
        self.priceLabel.text = @"$";
    } else {
        CGFloat price = self.product.price.floatValue * count;
        self.priceLabel.text = @(price).priceValue;
    }
}

- (IBAction)touchDown:(UIButton *)sender {
    if (sender == self.minusBtn && self.count == 0) {
        return;
    } /*else if (sender == self.plusBtn && self.maxCount != NSNotFound && self.count == self.maxCount) {
        return;
    }*/
    
    self.count += sender == self.plusBtn ? 1 : (-1);
    
    if (self.changeBlock)
        self.changeBlock(self.count);
    
    [self performSelector:@selector(touchDown:) withObject:sender afterDelay:0.25];
}

- (IBAction)touchUp:(UIButton *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
