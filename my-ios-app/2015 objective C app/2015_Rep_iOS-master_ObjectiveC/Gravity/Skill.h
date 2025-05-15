//
//  Skill.h
//  Gravity
//
//  Created by Vlad Getman on 03.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Skill : NSManagedObject

@property (nonatomic, retain) NSNumber * skillId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * parentId;
@property (nonatomic, retain) NSDate * timestamp;

- (NSString *)skillDescription;

@end
