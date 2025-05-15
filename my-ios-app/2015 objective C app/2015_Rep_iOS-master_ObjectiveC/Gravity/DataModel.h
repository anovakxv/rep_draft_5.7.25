//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>
#import "MappingProvider.h"
#import "User.h"
#import "City.h"
#import "Categories.h"
#import "Portal.h"
#import "GoalMetrics.h"
#import "GoalType.h"
#import "ReportingIncrement.h"
#import "Goal.h"
#import "UserType.h"
#import "Progress.h"
#import "Feed.h"
#import "Skill.h"
#import "GraphicSection.h"
#import "Card.h"
#import "Chat.h"

typedef enum : NSInteger
{
    MAPPING_USER,
    MAPPING_USERS,
    MAPPING_CITIES,
    MAPPING_MESSAGES,
    MAPPING_MESSAGES_INVERSE,
    MAPPING_PORTAL,
    MAPPING_PORTALS,
    MAPPING_CATEGORIES,
    MAPPING_GOAL,
    MAPPING_GOALS,
    MAPPING_GOAL_TYPE,
    MAPPING_GOAL_METRICS,
    MAPPING_REPORTING_INCREMENT,
    MAPPING_PRODUCT,
    MAPPING_PRODUCTS,
    MAPPING_USER_TYPES,
    MAPPING_INVITES,
    MAPPING_PROGRESS,
    MAPPING_FEED,
    MAPPING_SKILLS,
    MAPPING_CARD,
    MAPPING_CARDS,
    MAPPING_STATIC_DATA
    
} MappingType;

@interface DataModel : NSObject

// CORE DATA PERSISTENT STORE
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// RESTKIT OBJECT STORE
@property (nonatomic, strong) RKManagedObjectStore *objectStore;

// DELEGATE AND PUBLIC SETUP METHOD
+ (id)sharedDataModel;
- (void)setup;
- (void)saveContext;
- (void)resetEntity:(NSString *)entity;

- (NSArray *)mappingJSON:(id)json type:(MappingType)mappingType;
- (void)mappingJSON:(id)json type:(MappingType)mappingType withCompletition:(void (^)(NSArray *items))completionBlock;
- (NSArray *)fetchData:(NSString*)mo withDescriptor:(NSArray*)sortDescriptor withPredicate:(NSPredicate*)predicate withAttributes:(NSArray*)attributes;

+ (Goal *)getGoalWithId:(NSNumber *)goalId;
+ (User *)getUserWithId:(NSNumber *)userId;
+ (City *)getCityWithId:(NSNumber *)cityId;
+ (Categories *)getCategoryWithId:(NSNumber *)categoryId;
+ (Portal *)getPortalWithId:(NSNumber *)portalId;
+ (GoalMetrics *)getGoalMetricsWithId:(NSNumber *)goalMetricsId;
+ (GoalType *)getGoalTypeWithId:(NSNumber *)goalTypeId;
+ (ReportingIncrement *)getReportingIncrementWithId:(NSNumber *)reportingIncrementId;
+ (Skill *)getSkillWithId:(NSNumber *)skillId;
+ (id)getItem:(Class)itemClass withId:(NSNumber *)itemId;

@end
