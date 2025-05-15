//
//  Feed.h
//  Gravity
//
//  Created by Vlad Getman on 29.01.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Feed : NSManagedObject

@property (nonatomic, retain) NSNumber * feedId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSNumber * goalId;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSArray * attachments;

@end
