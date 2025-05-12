//
//  Support.m
//  Flaregun
//
//  Created by Vlad Getman on 10/28/13.
//  Copyright (c) 2013 halcyoninnovation. All rights reserved.
//

#import "Support.h"
#import "DataManager.h"
#import "LUKeychainAccess.h"
#import "AppDelegate.h"
#import <INTULocationManager.h>

@implementation Support


+(id)sharedDelegate {
    static Support *__sharedDataModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedDataModel = [[Support alloc] init];
    });
    return __sharedDataModel;
}

+ (void)backgroundQueue:(void (^)())queue {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), queue);
}

+ (void)mainQueue:(void (^)())queue {
    dispatch_async(dispatch_get_main_queue(), queue);
}


-(void)logout {
    
    APP.user = nil;
    
    [Keychain deleteAll];
    
    [[DataManager sharedDataManager] JSONTo:kServerUrl
                             withDictionary:@{}
                                        log:NO
                                   function:@"api_logout_user"
                            completionBlock:nil];
    
}

+ (void)mapSearch:(NSString *)searchString withCompletition:(void (^)(NSArray *places))completionBlock {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    
    request.naturalLanguageQuery = searchString;
    
    MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error)
    {
        if (error != nil)
        {
            completionBlock(nil);
        }
        else
        {
            NSArray *places = [response mapItems];
            NSMutableArray *mutablePlaces = [[NSMutableArray alloc] init];
            for (MKMapItem *mapItem in places) {
                if ([[mapItem.placemark countryCode] isEqual:@"US"] && [mapItem.placemark.addressDictionary objectForKey:@"Street"]) {
                    [mutablePlaces addObject:mapItem];
                }
            }
            places = mutablePlaces;
            completionBlock(places);
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    };
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    
    [localSearch startWithCompletionHandler:completionHandler];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)showError:(NSString*)errorText {
    
    if ([errorText isKindOfClass:[NSDictionary class]] || [errorText isKindOfClass:[NSArray class]]) {
        errorText = [errorText description];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorText delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)showAlert:(NSString*)title body:(NSString*)body {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)showLoading:(BOOL)show {
    if (show) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP.window animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        //hud.userInteractionEnabled = YES;
        hud.labelText = @"Loading";
    } else {
        [MBProgressHUD hideAllHUDsForView:APP.window animated:YES];
    }
}

+ (MBProgressHUD *)showDoneWithText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP.window animated:YES];
    //hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.detailsLabelText = text;
    [hud show:YES];
    [hud hide:YES afterDelay:2];
    [hud removeFromSuperViewOnHide];
    return hud;
}

#pragma mark - location

- (void)startUpdatingLocation {
    [self updateLocation];
    timer = [NSTimer timerWithTimeInterval:60
                                    target:self
                                  selector:@selector(updateLocation)
                                  userInfo:nil
                                   repeats:YES];
}

- (void)updateLocation {
    [self getUpdatedLocation:^(CLLocation *location) {
        NSDictionary *params = @{@"lat":@(location.coordinate.latitude).stringValue, @"lng":@(location.coordinate.longitude).stringValue};
        [DataMNG JSONTo:kServerUrl
         withDictionary:params
                    log:NO
               function:@"api_edit_user"
        completionBlock:nil];
    }];
}

- (void)endUpdatingLocation {
    if (timer)
        [timer invalidate];
    timer = nil;
}

-(CLLocation *)getLocation{
    /*if(self.lastLocation == nil || self.lastLocation.coordinate.latitude == 0 || self.lastLocation.coordinate.longitude == 0){
     CLLocation *myLocation = [[CLLocation alloc] initWithLatitude:54.563512
     longitude:1.054587];
     return myLocation;
     }*/
    return self.lastLocation;
}

- (void)getUpdatedLocation:(void (^)(CLLocation *location))locationBlock {
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                       timeout:0.0
                          delayUntilAuthorized:YES  // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             if (status == INTULocationStatusSuccess) {
                                                 
                                                 self.lastLocation = currentLocation;
                                             }
                                             if (locationBlock)
                                                 locationBlock(self.lastLocation);
                                         }];
}

@end
