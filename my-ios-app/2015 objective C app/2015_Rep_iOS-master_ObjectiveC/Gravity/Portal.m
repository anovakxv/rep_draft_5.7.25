//
//  Portal.m
//  Gravity
//
//  Created by Vlad Getman on 05.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "Portal.h"
#import "GraphicSection.h"


@implementation Portal

@dynamic about;
@dynamic categoryId;
@dynamic cityId;
@dynamic goalDescription;
@dynamic leads;
@dynamic name;
@dynamic photo;
@dynamic portalId;
@dynamic subtitle;
@dynamic texts;
@dynamic timestamp;
@dynamic shareTimestamp;
@dynamic userId;
@dynamic users;
@dynamic sections;
@dynamic usersCount;
@dynamic manualCity;

- (NSString *)city {
    if (self.manualCity.length > 0) {
        return self.manualCity;
    } else {
        City *city = [DataModel getCityWithId:self.cityId];
        if (city) {
            return city.name;
        } else {
            return @"";
        }
    }
}

@end
