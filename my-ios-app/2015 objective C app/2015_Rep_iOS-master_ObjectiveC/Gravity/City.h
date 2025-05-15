//
//  City.h
//  Gravity
//
//  Created by Vlad Getman on 23.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface City : NSManagedObject

@property (nonatomic, retain) NSNumber * cityId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * visible;

@end
