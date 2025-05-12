//
//  Message.h
//  iCollegeTree
//
//  Created by Vlad Getman on 20.06.14.
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * messageId;
@property (nonatomic, retain) NSNumber * userId1;
@property (nonatomic, retain) NSNumber * userId2;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * otherId;
@property (nonatomic, retain) NSNumber * messagesCount;
@property (nonatomic, retain) NSNumber * countNew;
@property (nonatomic, retain) NSNumber * portalId;
@property (nonatomic, retain) NSNumber * chatId;

@end
