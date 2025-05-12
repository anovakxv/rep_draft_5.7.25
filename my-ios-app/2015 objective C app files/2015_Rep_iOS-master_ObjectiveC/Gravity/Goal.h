//
//  Goal.h
//  Gravity
//
//  Created by Vlad Getman on 20.01.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Progress;

@interface Goal : NSManagedObject

@property (nonatomic, retain) NSString * about;
@property (nonatomic, retain) NSNumber * goalId;
@property (nonatomic, retain) NSNumber * leadId;
@property (nonatomic, retain) NSNumber * managePermission;
@property (nonatomic, retain) NSNumber * metricId;
@property (nonatomic, retain) NSNumber * portalId;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSNumber * quota;
@property (nonatomic, retain) NSNumber * repCommission;
@property (nonatomic, retain) NSNumber * reportingIncrementsId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * typeId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSOrderedSet *latestProgress;
@property (nonatomic, retain) NSNumber * teamMember;

@end

@interface Goal (CoreDataGeneratedAccessors)

- (void)insertObject:(Progress *)value inLatestProgressAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLatestProgressAtIndex:(NSUInteger)idx;
- (void)insertLatestProgress:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLatestProgressAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLatestProgressAtIndex:(NSUInteger)idx withObject:(Progress *)value;
- (void)replaceLatestProgressAtIndexes:(NSIndexSet *)indexes withLatestProgress:(NSArray *)values;
- (void)addLatestProgressObject:(Progress *)value;
- (void)removeLatestProgressObject:(Progress *)value;
- (void)addLatestProgress:(NSOrderedSet *)values;
- (void)removeLatestProgress:(NSOrderedSet *)values;
@end
