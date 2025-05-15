//
//  Skill.m
//  Gravity
//
//  Created by Vlad Getman on 03.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "Skill.h"


@implementation Skill

@dynamic skillId;
@dynamic title;
@dynamic parentId;
@dynamic timestamp;

- (NSString *)skillDescription {
    NSMutableString *skill = [[NSMutableString alloc] init];
    if (self.parentId.integerValue == 0) {
        [skill appendString:self.title];
    } else {
        Skill *s = [DataModel getSkillWithId:self.parentId];
        [skill appendFormat:@"%@ - %@", s.title, self.title];
    }
    return skill;
}

@end
