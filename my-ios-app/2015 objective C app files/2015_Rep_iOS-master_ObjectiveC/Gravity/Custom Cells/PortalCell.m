//
//  PatnersTableViewCell.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "PortalCell.h"

@implementation PortalCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setPortal:(Portal *)portal {
    _portal = portal;
    self.nameLabel.text = portal.name.stringByStrippingHTMLItems;
    self.subtitleLabel.text = portal.subtitle.stringByStrippingHTMLItems;
    
    if (portal.photo.length > 0) {
        [self.logoView sd_setImageWithURL:[NSURL URLWithString:portal.photo]];
    } else if (portal.sections.count > 0) {
        GraphicSection *section = [portal.sections firstObject];
        NSDictionary *photo = [section.files firstObject];
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
        [self.logoView sd_cancelCurrentImageLoad];
        self.logoView.image = [UIImage imageNamed:@"example_logo1"];
    }
    
    self.cityLabel.text = portal.city;
    Categories *category = [DataModel getCategoryWithId:portal.categoryId];
    if (category) {
        self.categoryLabel.text = category.name;
    }
}

@end
