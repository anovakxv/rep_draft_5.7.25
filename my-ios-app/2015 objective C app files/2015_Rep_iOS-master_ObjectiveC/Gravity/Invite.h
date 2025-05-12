//
//  Invite.h
//  Gravity
//
//  Created by Vlad Getman on 17.12.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Invite : NSManagedObject

@property (nonatomic, retain) NSNumber * inviteId;
@property (nonatomic, retain) NSNumber * goalId;
@property (nonatomic, retain) NSNumber * userId1;
@property (nonatomic, retain) NSNumber * userId2;
@property (nonatomic, retain) NSNumber * read1;
@property (nonatomic, retain) NSNumber * read2;
@property (nonatomic, retain) NSNumber * confirmed;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * inbox;

@end
