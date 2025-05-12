//
//  Progress.h
//  Gravity
//
//  Created by Vlad Getman on 20.01.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Goal;

@interface Progress : NSManagedObject

@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * dateStr;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSNumber * goalId;
@property (nonatomic, retain) NSNumber * index;

@property (nonatomic, retain) Goal *goal;

@end
