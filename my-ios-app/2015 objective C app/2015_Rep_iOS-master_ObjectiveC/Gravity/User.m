//
//  User.m
//  Gravity
//
//  Created by Vlad Getman on 23.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "User.h"


@implementation User

@dynamic about;
@dynamic broadcast;
@dynamic email;
@dynamic firstName;
@dynamic lastName;
@dynamic fullName;
@dynamic phone;
@dynamic photo;
@dynamic photoSmall;
@dynamic userId;
@dynamic userTypeId;
@dynamic cityId;
@dynamic network;
@dynamic timestamp;
@dynamic skills;
@dynamic manualCity;
@dynamic otherSkill;

+ (void)getWithId:(NSNumber *)userId userBlock:(void (^)(User *user))block {
    User *user = [DataModel getUserWithId:userId];
    if (user) {
        block(user);
    } else {
        [DataMNG JSONTo:kServerUrl
         withDictionary:@{@"users_id":userId.stringValue}
                    log:NO
               function:@"api_user_profile"
        completionBlock:^(NSDictionary *json, NSError *error) {
            
            [DATA mappingJSON:json
                         type:MAPPING_USER
             withCompletition:^(NSArray *items) {
                 block([items firstObject]);
             }];
        }];
    }
}

@end
