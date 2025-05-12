//
//  Category.h
//  Gravity
//
//  Created by Vlad Getman on 23.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Categories : NSManagedObject

@property (nonatomic, retain) NSNumber * categoryId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * visible;

@end
