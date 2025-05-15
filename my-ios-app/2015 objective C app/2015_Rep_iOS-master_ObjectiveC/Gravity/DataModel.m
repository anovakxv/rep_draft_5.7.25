//
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

@synthesize managedObjectContext=__managedObjectContext, managedObjectModel=__managedObjectModel, persistentStoreCoordinator=__persistentStoreCoordinator;

+(id)sharedDataModel {
    static DataModel *__sharedDataModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedDataModel = [[DataModel alloc] init];
    });
    return __sharedDataModel;
}

-(void)setup {
    self.objectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Gravity.sqlite"];
    NSLog(@"Setting up store at %@", path);
    [self.objectStore addSQLitePersistentStoreAtPath:path
                              fromSeedDatabaseAtPath:nil
                                   withConfiguration:nil
                                             options:[self optionsForSqliteStore]
                                               error:nil];
    [self.objectStore createManagedObjectContexts];
    [RKManagedObjectStore setDefaultStore:self.objectStore];
    
    //self.objectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:self.objectStore.persistentStoreManagedObjectContext];
}

#pragma mark - Core Data stack

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Gravity" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [self.objectStore mainQueueManagedObjectContext];
}

- (id)optionsForSqliteStore {
    return @{
             NSInferMappingModelAutomaticallyOption: @YES,
             NSMigratePersistentStoresAutomaticallyOption: @YES
             };
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    return __persistentStoreCoordinator;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    if (managedObjectContext != nil)
    {
        BOOL hasChanges = [managedObjectContext hasChanges];
        if (hasChanges && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)resetEntity:(NSString *)entity {
    
    NSManagedObjectContext *moc = [[self objectStore] persistentStoreManagedObjectContext];
    
    NSFetchRequest * allEvents = [[NSFetchRequest alloc] init];
    [allEvents setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:moc]];
    [allEvents setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * events = [moc executeFetchRequest:allEvents error:&error];
    
    for (NSManagedObject * evt in events) {
        [moc deleteObject:evt];
    }
    
    NSError *saveError = nil;
    [moc save:&saveError];
}

#pragma mark - work with core data

- (NSArray *)mappingJSON:(id)json type:(MappingType)mappingType {
    
    if (!json) {
        return nil;
    }
    
    NSError *error;
    RKManagedObjectStore *store = [self objectStore];
    
    RKManagedObjectMappingOperationDataSource *mappingDS = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:store.persistentStoreManagedObjectContext cache:store.managedObjectCache];
    
    NSDictionary *mappingDictionary;
    NSString *entity;
    NSPredicate *predicate;
    NSArray *descriptors;
    NSArray *array;
    
    switch (mappingType) {
            
        case MAPPING_USER:
            mappingDictionary = @{@"":[MappingProvider userMapping], @"aSkills":[MappingProvider skillMapping]};
            entity = @"User";
            predicate = [NSPredicate predicateWithFormat:@"userId == %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_USERS:
            mappingDictionary = @{@"":[MappingProvider userMapping]};
            entity = @"User";
            array = json;
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"userId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_CITIES:
            mappingDictionary = @{@"":[MappingProvider cityMapping]};
            entity = @"City";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"cityId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_MESSAGES:
        case MAPPING_MESSAGES_INVERSE:
            mappingDictionary = @{@"aData":[MappingProvider messageMapping], @"aUsers":[MappingProvider userMapping], @"aPortals":[MappingProvider portalMapping], @"aChats":[MappingProvider chatMapping]};
            entity = @"Message";
            array = [json objectForKey:@"aData"];
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                        ascending:mappingType == MAPPING_MESSAGES
                                                         selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"messageId IN %@", [json valueForKeyPath:@"aData.id"]];
            break;
            
        case MAPPING_PORTAL:
            mappingDictionary = @{@"":[MappingProvider portalMapping],@"aUsers":[MappingProvider userMapping], @"aSections":[MappingProvider graphicSectionMapping]};
            entity = @"Portal";
            predicate = [NSPredicate predicateWithFormat:@"portalId == %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_PORTALS:
            mappingDictionary = @{@"":[MappingProvider portalMapping]};
            entity = @"Portal";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"usersCount" ascending:NO selector:nil],
                            [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"portalId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_PRODUCT:
            mappingDictionary = @{@"":[MappingProvider productMapping]};
            entity = @"Product";
            predicate = [NSPredicate predicateWithFormat:@"productId == %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_PRODUCTS:
            mappingDictionary = @{@"":[MappingProvider productMapping]};
            entity = @"Product";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"productId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_CATEGORIES:
            mappingDictionary = @{@"":[MappingProvider categoryMapping]};
            entity = @"Categories";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"categoryId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_GOAL_METRICS:
            mappingDictionary = @{@"":[MappingProvider goalMetricsMapping]};
            entity = @"GoalMetrics";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"goalMetricsId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_GOAL_TYPE:
            mappingDictionary = @{@"":[MappingProvider goalTypeMapping]};
            entity = @"GoalType";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"goalTypeId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_REPORTING_INCREMENT:
            mappingDictionary = @{@"":[MappingProvider reportingIncrementMapping]};
            entity = @"ReportingIncrement";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"reportingIncrementId IN %@", [json valueForKey:@"id"]];
            break;
        case MAPPING_GOAL:
            mappingDictionary = @{@"":[MappingProvider goalMapping]};
            entity = @"Goal";
            predicate = [NSPredicate predicateWithFormat:@"goalId == %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_GOALS:
            mappingDictionary = @{@"aGoals":[MappingProvider goalMapping], @"aGoals.aLatestProgress":[MappingProvider progressMapping], @"aPortals":[MappingProvider portalMapping]};
            entity = @"Goal";
            array = json[@"aGoals"];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"goalId IN %@", [array valueForKey:@"id"]];
            break;
            
        case MAPPING_USER_TYPES:
            mappingDictionary = @{@"":[MappingProvider userTypeMapping]};
            entity = @"UserType";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"userTypeId" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"userTypeId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_INVITES:
            mappingDictionary = @{@"aInvites":[MappingProvider inviteMapping], @"aGoals":[MappingProvider goalMapping], @"aUsers":[MappingProvider userMapping], @"aPortals":[MappingProvider portalMapping]};
            entity = @"Invite";
            array = [json objectForKey:@"aInvites"];
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"inviteId" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"inviteId IN %@", [json valueForKeyPath:@"aInvites.id"]];
            break;
        
        case MAPPING_PROGRESS:
            mappingDictionary = @{@"":[MappingProvider progressMapping]};
            entity = @"Progress";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"goalId IN %@ && index IN %@", [json valueForKey:@"goals_id"], [json valueForKey:@"c"]];
            break;
            
        case MAPPING_FEED:
            mappingDictionary = @{@"aData":[MappingProvider feedMapping], @"aUsers":[MappingProvider userMapping]};
            entity = @"Feed";
            array = json[@"aData"];
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"feedId IN %@", [json valueForKeyPath:@"aData.id"]];
            break;
            
        case MAPPING_SKILLS:
            mappingDictionary = @{@"":[MappingProvider skillMapping]};
            entity = @"Skill";
            array = json;
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:nil]];
            if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"skillId IN %@", [json valueForKey:@"id"]];
            break;
            
        case MAPPING_CARD:
        case MAPPING_CARDS:
            mappingDictionary = @{@"":[MappingProvider cardMapping]};
            entity = @"Card";
            if (mappingType == MAPPING_CARD) {
                predicate = [NSPredicate predicateWithFormat:@"cardId == %@", [json valueForKey:@"id"]];
            } else {
                array = json;
                if (array.count > 0) predicate = [NSPredicate predicateWithFormat:@"cardId IN %@", [json valueForKey:@"id"]];
            }
            break;
            
        case MAPPING_STATIC_DATA:
            mappingDictionary = @{@"aCities":[MappingProvider cityMapping],
                                  @"aUserTypes":[MappingProvider userTypeMapping],
                                  @"aCategories":[MappingProvider categoryMapping],
                                  @"aGoalMetrics":[MappingProvider goalMetricsMapping],
                                  @"aGoalTypes":[MappingProvider goalTypeMapping],
                                  @"aReportingIncrements":[MappingProvider reportingIncrementMapping],
                                  @"aSkills":[MappingProvider skillMapping]};
            break;
    }
    
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:json mappingsDictionary:mappingDictionary];
    mapperOperation.mappingOperationDataSource = mappingDS;
    [mapperOperation execute:&error];
    //[store.persistentStoreManagedObjectContext save:&error];
    [store.persistentStoreManagedObjectContext saveToPersistentStore:&error];
    
    if (predicate == nil && (mappingType == MAPPING_USERS ||
                             mappingType == MAPPING_CITIES ||
                             mappingType == MAPPING_MESSAGES ||
                             mappingType == MAPPING_MESSAGES_INVERSE ||
                             mappingType == MAPPING_PORTALS ||
                             mappingType == MAPPING_CATEGORIES ||
                             mappingType == MAPPING_GOAL_METRICS ||
                             mappingType == MAPPING_REPORTING_INCREMENT ||
                             mappingType == MAPPING_GOAL_TYPE ||
                             mappingType == MAPPING_PRODUCTS ||
                             mappingType == MAPPING_GOALS ||
                             mappingType == MAPPING_USER_TYPES ||
                             mappingType == MAPPING_INVITES ||
                             mappingType == MAPPING_PROGRESS ||
                             mappingType == MAPPING_SKILLS ||
                             mappingType == MAPPING_FEED ||
                             mappingType == MAPPING_CARDS ||
                             mappingType == MAPPING_STATIC_DATA))
        return nil;
    
    return [self fetchData:entity withDescriptor:descriptors withPredicate:predicate withAttributes:nil];
}

- (void)mappingJSON:(id)json type:(MappingType)mappingType withCompletition:(void (^)(NSArray *))completionBlock {
    __block NSArray *items = [self mappingJSON:json type:mappingType];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        items = [self mappingJSON:json type:mappingType];
        
        if (completionBlock)
            completionBlock(items);
    });
}

- (NSArray *)fetchData:(NSString*)mo withDescriptor:(NSArray*)sortDescriptor withPredicate:(NSPredicate*)predicate withAttributes:(NSArray*)attributes {
    
    NSManagedObjectContext *moc = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setIncludesPendingChanges:YES];
    NSEntityDescription *entity = [NSEntityDescription entityForName:mo inManagedObjectContext:moc];
    [fetch setEntity:entity];
    if (attributes > 0) {
        [fetch setResultType:NSDictionaryResultType];
        [fetch setPropertiesToFetch:attributes];
    }
    // apply sort descriptors
    if (sortDescriptor) {
        [fetch setSortDescriptors:sortDescriptor];
    }
    
    // apply predicate if we have one
    if (predicate)
        [fetch setPredicate:predicate];
    
    // do fetch request
    NSError *error;
    
    NSArray *results = [moc executeFetchRequest:fetch error:&error];
    
    // check if you have results
    if (!results)
        return nil;
    
    return results;
}

+ (Goal *)getGoalWithId:(NSNumber *)goalId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(goalId == %@)", goalId];
    NSArray *items = [DATA fetchData:@"Goal" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (User *)getUserWithId:(NSNumber *)userId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userId == %@)", userId];
    NSArray *items = [DATA fetchData:@"User" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (City *)getCityWithId:(NSNumber *)cityId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(cityId == %@)", cityId];
    NSArray *items = [DATA fetchData:@"City" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (Categories *)getCategoryWithId:(NSNumber *)categoryId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryId == %@)", categoryId];
    NSArray *items = [DATA fetchData:@"Categories" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (Categories *)getGoalTypeWithId:(NSNumber *)goalTypeId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(goalTypeId == %@)", goalTypeId];
    NSArray *items = [DATA fetchData:@"GoalType" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (Categories *)getGoalMetricsWithId:(NSNumber *)goalMetricsId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(goalMetricsId == %@)", goalMetricsId];
    NSArray *items = [DATA fetchData:@"GoalMetrics" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (Portal *)getPortalWithId:(NSNumber *)portalId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(portalId == %@)", portalId];
    NSArray *items = [DATA fetchData:@"Portal" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}
+ (ReportingIncrement *)getReportingIncrementWithId:(NSNumber *)reportingIncrementId{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(reportingIncrementId == %@)", reportingIncrementId];
    NSArray *items = [DATA fetchData:@"ReportingIncrement" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    if (items.count > 0) {
        return [items firstObject];
    } else {
        return nil;
    }
}

+ (Skill *)getSkillWithId:(NSNumber *)skillId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(skillId == %@)", skillId];
    NSArray *items = [DATA fetchData:@"Skill" withDescriptor:nil withPredicate:predicate withAttributes:nil];
    return [items firstObject];
}

+ (id)getItem:(Class)itemClass withId:(NSNumber *)itemId {
    NSString *className = NSStringFromClass(itemClass);
    NSString *variable = [className stringByAppendingString:@"Id"];
    variable = [[[variable substringToIndex:1] lowercaseString] stringByAppendingString:[variable substringFromIndex:1]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", variable, itemId];
    NSArray *items = [DATA fetchData:className withDescriptor:nil withPredicate:predicate withAttributes:nil];
    return [items firstObject];
}

@end
