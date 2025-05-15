//
//  UserType.h
//  Gravity
//
//  Created by Vlad Getman on 21.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserType : NSManagedObject

@property (nonatomic, retain) NSNumber * userTypeId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * about;

@end
