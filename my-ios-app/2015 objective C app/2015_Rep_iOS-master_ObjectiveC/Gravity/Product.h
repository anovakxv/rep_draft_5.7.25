//
//  Product.h
//  Gravity
//
//  Created by Vlad Getman on 28.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Product : NSManagedObject

@property (nonatomic, retain) NSString * about;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSArray * photos;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSNumber * productId;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSNumber * portalId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * photo;

@end
