//
//  GoalType.h
//  Gravity
//
//  Created by Administrator on 24.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GoalType : NSManagedObject

@property (nonatomic, retain) NSNumber * goalTypeId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * visible;

@end
