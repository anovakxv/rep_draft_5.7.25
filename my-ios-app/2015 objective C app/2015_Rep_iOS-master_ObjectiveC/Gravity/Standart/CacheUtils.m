//
//  CacheUtils.m
//  RedDawnMedia
//
//  Created by Halcyoni on 3/31/12.
//  Copyright (c) 2012 SODTechnologies Pvt Ltd. All rights reserved.
//

#import "CacheUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation CacheUtils

NSString * md5Calc(NSString *input)
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}

+ (void) stringForArray: (NSArray *)params toString:(NSMutableString *)str{
    if (params != nil) {
        NSArray *sortedKeys = [params sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in sortedKeys) {
            id value = key;
            if ([value isKindOfClass:NSDictionary.class]) {
                [self stringForDictionary:value toString:str];
            } else if ([value isKindOfClass:NSArray.class]) {
                [self stringForArray:value toString:str];
            } else {
                if ([value isKindOfClass:NSNumber.class]) {
                    value = [(NSNumber *)value stringValue];
                }
                [str appendString: @"="];
                [str appendString: value];
            }
        }
    }
}

+ (void) stringForDictionary: (NSDictionary *)params toString:(NSMutableString *)str{
    if (params != nil) {
        NSArray *sortedKeys = [params.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in sortedKeys) {
            [str appendString:@"&"];
            [str appendString: key];
            id value = [params valueForKey: key];
            if ([value isKindOfClass:NSDictionary.class]) {
                [self stringForDictionary:value toString:str];
            } else if ([value isKindOfClass:NSArray.class]) {
                [self stringForArray:value toString:str];
            } else {
                if ([value isKindOfClass:NSNumber.class]) {
                    value = [(NSNumber *)value stringValue];
                }
                [str appendString: @"="];
                [str appendString: value];
            }
        }
    }
}


+ (NSString *) hashForUrl:(NSString *)url params: (NSDictionary *)params {
    NSMutableString *str = [NSMutableString stringWithString:url];
    if (params != nil) {
        [self stringForDictionary:params toString:str];
    }
    NSString *hash= md5Calc(str);
	return hash;
}

+ (void) saveToCacheData:(NSData *)data forUrl:(NSString *)url params:(NSDictionary *)params {
    
    NSString *cachePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSString *hash = [CacheUtils hashForUrl:url params:params];
    NSString *path = [NSString stringWithFormat: @"%@/%@/%@",[hash substringToIndex:1], [[hash substringFromIndex:1] substringToIndex:1], hash];
    path = [cachePath stringByAppendingPathComponent:path];
    NSString *dir = [path stringByDeletingLastPathComponent]; 
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"%@", path);
    [data writeToFile:path atomically: YES];    
}

+ (NSData *) cachedDataForUrl:(NSString *)url params:(NSDictionary *)params {
    
    NSString *cachePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSString *hash = [CacheUtils hashForUrl:url params:params];
    NSString *path = [NSString stringWithFormat: @"%@/%@/%@",[hash substringToIndex:1], [[hash substringFromIndex:1] substringToIndex:1], hash];
    path = [cachePath stringByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;

}
@end
