//
//  Portal.h
//  Gravity
//
//  Created by Vlad Getman on 05.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GraphicSection;

@interface Portal : NSManagedObject

@property (nonatomic, retain) NSString * about;
@property (nonatomic, retain) NSNumber * categoryId;
@property (nonatomic, retain) NSNumber * cityId;
@property (nonatomic, retain) NSString * goalDescription;
@property (nonatomic, retain) NSArray * leads;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * photo;
@property (nonatomic, retain) NSNumber * portalId;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSArray * texts;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSDate * shareTimestamp;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSArray * users;
@property (nonatomic, retain) NSOrderedSet *sections;
@property (nonatomic, retain) NSNumber * usersCount;
@property (nonatomic, retain) NSString * manualCity;

- (NSString *)city;

@end

@interface Portal (CoreDataGeneratedAccessors)

- (void)insertObject:(GraphicSection *)value inSectionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSectionsAtIndex:(NSUInteger)idx;
- (void)insertSections:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSectionsAtIndex:(NSUInteger)idx withObject:(GraphicSection *)value;
- (void)replaceSectionsAtIndexes:(NSIndexSet *)indexes withSections:(NSArray *)values;
- (void)addSectionsObject:(GraphicSection *)value;
- (void)removeSectionsObject:(GraphicSection *)value;
- (void)addSections:(NSOrderedSet *)values;
- (void)removeSections:(NSOrderedSet *)values;
@end
