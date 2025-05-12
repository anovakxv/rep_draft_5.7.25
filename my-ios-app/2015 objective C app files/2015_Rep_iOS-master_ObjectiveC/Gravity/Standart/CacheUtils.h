//
//  CacheUtils.h
//  RedDawnMedia
//
//  Created by Halcyoni on 3/31/12.
//  Copyright (c) 2012 SODTechnologies Pvt Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheUtils : NSObject

+ (void) saveToCacheData:(NSData *)data forUrl:(NSString *)url params:(NSDictionary *)params;
+ (NSData *) cachedDataForUrl:(NSString *)url params:(NSDictionary *)params;

@end
