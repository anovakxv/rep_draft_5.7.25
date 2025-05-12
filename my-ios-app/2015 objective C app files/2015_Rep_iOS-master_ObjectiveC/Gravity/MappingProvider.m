//
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import "MappingProvider.h"
#import "DataModel.h"

@implementation MappingProvider

+(RKMapping*)userMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                @"userId",
                                                  @"email":             @"email",
                                                  @"fname":             @"firstName",
                                                  @"lname":             @"lastName",
                                                  @"flname":            @"fullName",
                                                  @"about":             @"about",
                                                  @"broadcast":         @"broadcast",
                                                  @"phone":             @"phone",
                                                  @"users_types_id":    @"userTypeId",
                                                  @"cities_id":         @"cityId",
                                                  @"in_my_network":     @"network",
                                                  @"last_login":        @"timestamp",
                                                  @"aSkills":           @"skills",
                                                  @"manual_city":       @"manualCity",
                                                  @"other_skill":       @"otherSkill",
                                                  @"_c_profile_picture_original_url":   @"photo",
                                                  @"_c_profile_picture_thumb_86x86_url":   @"photoSmall"
                                                }];
    
    mapping.identificationAttributes = @[@"userId"];
    
    return mapping;
}

+(RKMapping*)portalMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Portal"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                    @"portalId",
                                                  @"users_id":              @"userId",
                                                  @"cities_id":             @"cityId",
                                                  @"manual_city":           @"manualCity",
                                                  @"categories_id":         @"categoryId",
                                                  @"name":                  @"name",
                                                  @"subtitle":              @"subtitle",
                                                  @"about":                 @"about",
                                                  @"timestamp":             @"timestamp",
                                                  @"aTexts":                @"texts",
                                                  @"aUsers":                @"users",
                                                  @"_c_file_max_640x640_url":@"photo",
                                                  @"aPortalUsers.users_id": @"leads",
                                                  @"share_timestamp":   @"shareTimestamp",
                                                  @"_c_users_count":        @"usersCount"
                                                  }];
    mapping.identificationAttributes = @[@"portalId"];
    
    RKRelationshipMapping *sections = [RKRelationshipMapping relationshipMappingFromKeyPath:@"aSections" toKeyPath:@"sections" withMapping:[self graphicSectionMapping]];
    [mapping addPropertyMapping:sections];
    
    return mapping;
}

+(RKMapping*)productMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Product"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                    @"productId",
                                                  @"users_id":              @"userId",
                                                  @"portals_id":            @"portalId",
                                                  @"name":                  @"name",
                                                  @"subtitle":              @"subtitle",
                                                  @"timestamp":             @"timestamp",
                                                  @"aFiles":                @"photos",
                                                  @"_c_file_max_640x640_url":@"photo",
                                                  @"description":           @"about",
                                                  @"price":                 @"price"
                                                  }];
    
    mapping.identificationAttributes = @[@"productId"];
    
    return mapping;
}

+(RKMapping*)messageMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Message"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                @"messageId",
                                                  @"users_id1":         @"userId1",
                                                  @"users_id2":         @"userId2",
                                                  @"text":              @"text",
                                                  @"read":              @"read",
                                                  @"timestamp":         @"timestamp",
                                                  @"the_other":         @"otherId",
                                                  @"messages_count":    @"messagesCount",
                                                  @"messages_count_new":@"countNew",
                                                  @"portals_id":        @"portalId",
                                                  @"chats_id":      @"chatId"}];
    
    mapping.identificationAttributes = @[@"messageId"];
    
    return mapping;
}

+(RKMapping*)chatMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Chat"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"chatId",
                                                  @"title":     @"title",
                                                  @"timestamp": @"timestamp",
                                                  @"users_id":  @"userId"
                                                  }];
    
    mapping.identificationAttributes = @[@"chatId"];
    
    return mapping;
}

+(RKMapping*)cityMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"City"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"cityId",
                                                  @"title":     @"name",
                                                  @"visible":   @"visible"
                                                  }];
    
    mapping.identificationAttributes = @[@"cityId"];
    
    return mapping;
}

+(RKMapping*)categoryMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Categories"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"categoryId",
                                                  @"title":     @"name",
                                                  @"visible":   @"visible"
                                                  }];
    
    mapping.identificationAttributes = @[@"categoryId"];
    
    return mapping;
}

+(RKMapping*)goalTypeMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"GoalType"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"goalTypeId",
                                                  @"title":     @"name",
                                                  @"visible":   @"visible"
                                                  }];
    
    mapping.identificationAttributes = @[@"goalTypeId"];
    
    return mapping;
}

+(RKMapping*)goalMetricsMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"GoalMetrics"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":            @"goalMetricsId",
                                                  @"title":         @"name",
                                                  @"goal_types_id": @"goalTypeId",
                                                  @"visible":       @"visible"
                                                  }];
    
    mapping.identificationAttributes = @[@"goalMetricsId"];
    
    return mapping;
}

+(RKMapping*)reportingIncrementMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"ReportingIncrement"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"reportingIncrementId",
                                                  @"title":     @"name",
                                                  @"visible":   @"visible"
                                                  }];
    
    mapping.identificationAttributes = @[@"reportingIncrementId"];
    
    return mapping;
}

+(RKMapping*)goalMapping{
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Goal"
                                                   inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                @"goalId",
                                                  @"description":       @"about",
                                                  @"lead_id":           @"leadId",
                                                  @"goal_metrics_id":   @"metricId",
                                                  @"quota":             @"quota",
                                                  @"progress":          @"progress",
                                                  @"filled_quota":      @"value",
                                                  @"rep_commission":    @"repCommission",
                                                  @"timestamp":         @"timestamp",
                                                  @"goal_types_id":     @"typeId",
                                                  @"users_id":          @"userId",
                                                  @"portals_id":        @"portalId",
                                                  @"reporting_increments_id": @"reportingIncrementsId",
                                                  @"manage_permission": @"managePermission",
                                                  @"team_member":   @"teamMember"
                                                  }];
    
    mapping.identificationAttributes = @[@"goalId"];
    
    RKRelationshipMapping *relationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"aLatestProgress" toKeyPath:@"latestProgress" withMapping:[self progressMapping]];
    [mapping addPropertyMapping:relationship];
    
    return mapping;
}

+(RKMapping*)userTypeMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"UserType" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"userTypeId",
                                                  @"title":     @"title",
                                                  @"visible":   @"visible",
                                                  @"timestamp": @"timestamp"
                                                  }];
    
    mapping.identificationAttributes = @[@"userTypeId"];
    
    return mapping;
}

+(RKMapping*)inviteMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Invite" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":            @"inviteId",
                                                  @"users_id1":     @"userId1",
                                                  @"users_id2":     @"userId2",
                                                  @"goals_id":      @"goalId",
                                                  @"read1":         @"read1",
                                                  @"read2":         @"read2",
                                                  @"confirmed":     @"confirmed",
                                                  @"inbox":         @"inbox",
                                                  @"timestamp":     @"timestamp"
                                                  }];
    
    mapping.identificationAttributes = @[@"inviteId"];
    
    return mapping;
}

+(RKMapping*)progressMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Progress"
                                                   inManagedObjectStore:[[DataModel sharedDataModel] objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"goals_id":      @"goalId",
                                                  @"value":         @"value",
                                                  @"date":          @"date",
                                                  @"date_str":      @"dateStr",
                                                  @"c":             @"index",
                                                  @"progress_total_percent":      @"progress"
                                                  }];
    
    mapping.identificationAttributes = @[@"goalId", @"index"];
    
    return mapping;
}

+(RKMapping*)feedMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Feed" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":            @"feedId",
                                                  @"users_id":      @"userId",
                                                  @"goals_id":      @"goalId",
                                                  @"added_value":   @"value",
                                                  @"note":          @"notes",
                                                  @"timestamp":     @"timestamp",
                                                  @"aAttachments":  @"attachments"
                                                  }];
    
    mapping.identificationAttributes = @[@"feedId"];
    
    return mapping;
}

+(RKMapping*)skillMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Skill" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"skillId",
                                                  @"title":     @"title",
                                                  @"parent":    @"parentId",
                                                  @"timestamp": @"timestamp"
                                                  }];
    
    mapping.identificationAttributes = @[@"skillId"];
    
    return mapping;
}

+(RKMapping*)graphicSectionMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"GraphicSection" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":        @"sectionId",
                                                  @"title":     @"title",
                                                  @"portals_id":@"portalId",
                                                  @"timestamp": @"timestamp",
                                                  @"aFiles":    @"files"
                                                  }];
    
    mapping.identificationAttributes = @[@"sectionId"];
    
    return mapping;
}

+ (RKMapping*)cardMapping {
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Card" inManagedObjectStore:[DATA objectStore]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id":                @"cardId",
                                                  @"user_id":           @"userId",
                                                  @"name":              @"name",
                                                  @"card_number":       @"cardNumber",
                                                  @"expiration_month":  @"expirationMonth",
                                                  @"expiration_year":   @"expirationYear",
                                                  @"zip":               @"zip",
                                                  @"timestamp":         @"timestamp",
                                                  @"default":           @"defaultCard"
                                                  }];
    
    mapping.identificationAttributes = @[@"cardId"];
    
    return mapping;
}

@end
