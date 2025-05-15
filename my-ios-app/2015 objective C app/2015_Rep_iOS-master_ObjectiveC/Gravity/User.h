//
//  User.h
//  Gravity
//
//  Created by Vlad Getman on 23.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * about;
@property (nonatomic, retain) NSString * broadcast;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * photo;
@property (nonatomic, retain) NSString * photoSmall;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSNumber * userTypeId;
@property (nonatomic, retain) NSNumber * cityId;
@property (nonatomic, retain) NSNumber * network;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSArray * skills;
@property (nonatomic, retain) NSString * manualCity;
@property (nonatomic, retain) NSString * otherSkill;

+ (void)getWithId:(NSNumber *)userId userBlock:(void (^)(User *user))block;

@end
