//
//  Card.h
//  Gravity
//
//  Created by Vlad Getman on 27.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Card : NSManagedObject

@property (nonatomic, retain) NSNumber * cardId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * cardNumber;
@property (nonatomic, retain) NSNumber * expirationMonth;
@property (nonatomic, retain) NSNumber * expirationYear;
@property (nonatomic, retain) NSString * zip;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * defaultCard;

@end
