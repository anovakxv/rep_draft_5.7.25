//
//  Support.h
//  Flaregun
//
//  Created by Vlad Getman on 10/28/13.
//  Copyright (c) 2013 halcyoninnovation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MBProgressHUD.h>

@interface Support : NSObject {
    NSTimer *timer;
}

+(id)sharedDelegate;

@property (nonatomic) CLLocation *lastLocation;

-(void)logout;

-(void)showError:(NSString*)errorText;
-(void)showAlert:(NSString*)title body:(NSString*)body;
- (void)showLoading:(BOOL)show;
+ (MBProgressHUD *)showDoneWithText:(NSString *)text;

+ (void)mapSearch:(NSString *)searchString withCompletition:(void (^)(NSArray *places))completionBlock;

+ (void)backgroundQueue:(void (^)())queue;
+ (void)mainQueue:(void (^)())queue;

- (void)startUpdatingLocation;
- (void)endUpdatingLocation;
- (CLLocation *)getLocation;
- (void)getUpdatedLocation:(void (^)(CLLocation *location))locationBlock;

@end
