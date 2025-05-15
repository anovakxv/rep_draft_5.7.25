//
//  GraphicSection.h
//  Gravity
//
//  Created by Vlad Getman on 05.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Portal;

@interface GraphicSection : NSManagedObject

@property (nonatomic, retain) NSNumber * sectionId;
@property (nonatomic, retain) NSNumber * portalId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSArray * files;
@property (nonatomic, retain) Portal *portal;

@end
