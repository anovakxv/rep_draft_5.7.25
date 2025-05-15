//
//  DataManager.m
//  CityDrinker
//
//  Created by Halcyoni on 11/30/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaData.h"

#define DataManagerNotification @"DataManagerNotification"
#define DataManagerActivityIndicatorNotification @"DataManagerActivityIndicatorNotification"

@interface DataManager : NSObject {
	NSOperationQueue *_queue;
	int activityCount;
    int networkActivityCount;
}

+ (DataManager*) sharedDataManager; 

/*- (void) postTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary forData:(BOOL)forData userInfo:(id)userInfo showActivityIndicator:(BOOL)showActivityIndicator;
*/
- (void) JSONTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams log:(BOOL)log forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator function:(NSString *)function cache:(BOOL)cache completionBlock:(void (^)(id, NSError *error))completionBlock;
- (void) JSONTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams log:(BOOL)log function:(NSString *)function completionBlock:(void (^)(id, NSError *error))completionBlock;
- (void) JSONTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary log:(BOOL)log function:(NSString *)function completionBlock:(void (^)(id, NSError *error))completionBlock;
- (void) addActivity;
- (void) removeActivity;
- (void) getTo:(NSString*)urlString forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock;
- (void) postTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock;
- (void) putTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock;

@end
