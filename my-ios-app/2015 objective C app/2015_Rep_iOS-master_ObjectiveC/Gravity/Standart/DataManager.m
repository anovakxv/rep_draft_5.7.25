//
//  DataManager.m
//  CityDrinker
//
//  Created by Halcyoni on 11/30/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DataManager.h"
//#import "JSON.h"
#import "MediaData.h"
#define kKeyShowActivityIndicator @"ShowActivityIndicator"
#define kKeyDataRequest @"DataRequest"
#define kKeyUserInfo @"UserInfo"
#define kKeyParams @"Params"
#define kKeyCache @"Cache"
#import "CacheUtils.h"
#import "MediaData.h"
#import "AFRKHTTPClient.h"
#import "AFRKHTTPRequestOperation.h"

@implementation DataManager

static DataManager *_sharedDataManager = nil;  


- (id)init {
    self = [super init];
    if (self) {
		_queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

+ (DataManager*) sharedDataManager {
	if (_sharedDataManager == nil) {
		_sharedDataManager = [[DataManager alloc] init];
    }
    return _sharedDataManager;
}

#pragma mark -
#pragma mark Convert Dictionary to String

- (NSString*) createRequestString:(NSDictionary*) requestDictionary {
	NSString *requestString, *key, *keyValue;
	
	requestString = @"";
	for (key in requestDictionary) {
		keyValue = [requestDictionary objectForKey:key];
		requestString = [requestString stringByAppendingFormat:@"%@=%@&", key, keyValue];
	}
	
	return requestString;
}

- (void) showActivityIndicator:(BOOL)show {
	NSDictionary *notificationObject = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:show], DataManagerActivityIndicatorNotification,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataManagerActivityIndicatorNotification object:self userInfo:notificationObject];
}

- (void) addActivity {
	if (activityCount == 0) {
		[self showActivityIndicator:YES];
	}
	activityCount ++;
}
- (void) addNetworkActivity {
	if (networkActivityCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
	networkActivityCount ++;
}

- (void) removeActivity {
	activityCount --;
	if (activityCount == 0) {
		[self showActivityIndicator:NO];
	}
}

- (void) removeNetworkActivity {
	networkActivityCount --;
	if (networkActivityCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}
/*
+ (void)convertVideoToLowQualityWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL successHandler:(void (^)())successHandler failureHandler:(void (^)(NSError *))failureHandler {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            successHandler();
        } else {
            NSError *exportError = exportSession.error;
            NSLog(@"AVAssetExportSessionStatusFailed: %@", exportError);
            
            //            NSError *error = [NSError errorWithDomain:@"video compression" code:777 userInfo:userInfo];
            failureHandler(exportError);
        }
    }];
}
*/
/*{
    uploading = YES;
    NSData* media = [NSData dataWithContentsOfFile: [mediafile valueForKey: @"path"] ];
    NSString *mimeType = [mediafile valueForKey: @"contentType"];
    NSString *url = [mediafile valueForKey: @"url"];
    NSString *type = [mediafile valueForKey: @"type"];
    NSString *filename = [mediafile valueForKey: @"contentName"];
    
    // NSLog(@"profile nsdata is %@", media);
    [SVProgressHUD show];
    
    NSString *username = [self fetchSingleUserDefault:@"username"];
    NSString *api_key = [self fetchSingleUserDefault:@"api_key"];
    
    if ((api_key == nil) || (username == nil)) {
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@?username=%@&api_key=%@", url, username, api_key];
    NSURL *baseUrl = [NSURL URLWithString:ccApiURL];
    
    AFRKHTTPClient *httpClient = [[AFRKHTTPClient alloc] initWithBaseURL:baseUrl];
    [httpClient registerHTTPOperationClass:[AFRKHTTPRequestOperation class]];
    //    [httpClient setDefaultHeader:@"Content-Type" value:@"image/png"];
    //    [httpClient setDefaultHeader:@"Accept" value:@"image/png"];
    [httpClient setParameterEncoding:AFRKFormURLParameterEncoding];
    
    NSDictionary *par = [NSDictionary dictionaryWithObjectsAndKeys:
                         api_key, @"api_key",
                         username, @"username",
                         nil];
    
    // BUILD THE REQUEST WITH THE IMAGE DATA (IF THERE IS ANY)
    NSMutableURLRequest *postRequest = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                             path:path
                                                                       parameters:par
                                                        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                            [formData
                                                             appendPartWithFileData:media
                                                             name:type
                                                             fileName:filename
                                                             mimeType:mimeType];
                                                        }];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"CONTENT_TYPE"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    // SPECIFY THE CONTENT TYPES ACCEPTED
    //    [AFRKHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"image/png", nil]];
    
    
    // INIT THE OPERATION
    AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:postRequest];
    
    
    // SHOW UPLOAD PROGRESS
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        
        CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
        NSString *msg;
        
        if (progress == 1.0)
            msg = @"Upload Complete!\nPlease Wait...";
        else
            msg = [NSString stringWithFormat:@"Uploading Image(s)\n%0.0f%%", (progress * 100)];
        
        [SVProgressHUD showProgress:progress status:msg];
    }];
    
    
    // BUILD THE OPERATION
    [operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
        
        [SVProgressHUD showSuccessWithStatus:@"\nIMAGE UPLOAD COMPLETE!"];
        
        NSData *json_data = [NSData dataWithData:responseObject];
        JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSDictionary *json = [decoder objectWithData:json_data];
        //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
        if (json != nil) {
            [self performSelectorOnMainThread:@selector(videoUploaded:) withObject:mediafile waitUntilDone:YES];
        }
        
        NSLog(@"\nIMAGE UPLOAD COMPLETE\n%@\n\n",json);
        //[self letsGoAction];
        uploading = NO;
        
        
    } failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
        
        NSHTTPURLResponse *response = [operation response];
        NSDictionary *headers = [response allHeaderFields];
        //NSData *json_data = [NSData dataWithData:[operation responseData]];
        //JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        // NSDictionary *json = [decoder objectWithData:json_data];
        
        NSLog(@"\n\nResponse:\n%@\n\nHeaders:\n%@\n\n",operation.responseString,headers);
        NSLog(@"\n\nUPLOAD IMAGE FAILED!!\n%@\n\n", error);
        
        //  [SVProgressHUD showErrorWithStatus:@"Unable to\nUpload Profile Pic\nAt This Time."];
        uploading = NO;
        
    }];
    
    // EXECUTE THE REGISTRATION OPERATION
    [operation start];

}
*/
#pragma mark -
#pragma mark Posting

- (void) JSONTo:(NSString *)urlString withDictionary:(NSDictionary *)postDictionary fileParams:(NSDictionary *)fileParams log:(BOOL)log function:(NSString *)function completionBlock:(void (^)(id, NSError *))completionBlock {
    [self JSONTo:urlString
  withDictionary:postDictionary
      fileParams:fileParams
             log:log
         forData:NO
          sender:nil
showActivityIndicator:YES
        function:function
           cache:NO
 completionBlock:completionBlock];
}

- (void) JSONTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary log:(BOOL)log function:(NSString *)function completionBlock:(void (^)(id, NSError *))completionBlock {
    [self JSONTo:urlString
  withDictionary:postDictionary
      fileParams:nil
             log:log
        function:function
 completionBlock:completionBlock];
}

- (void) JSONTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams log:(BOOL)log forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator function:(NSString *)function cache:(BOOL)cache completionBlock:(void (^)(id, NSError *))completionBlock {
    
    if ([fileParams count] > 0) {
        cache = NO;
    }
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithDictionary:postDictionary];
    for (NSString *key in post.allKeys) {
        if ([post[key] isKindOfClass:[NSString class]]) {
            post[key] = [post[key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    postDictionary = [NSDictionary dictionaryWithDictionary:post];

    NSURL *postURL;
	
    [self addNetworkActivity];
	if (showActivityIndicator) {
		[self addActivity];
	}

	postURL = [NSURL URLWithString:urlString];//[urlString stringByAppendingFormat:@"?%@",[self createRequestString:postDictionary]]];
	
    
    
    
    
    if (cache) {
        
        NSData *data = [CacheUtils cachedDataForUrl:[urlString stringByAppendingString:function] params:postDictionary];
        if (data != nil) {
            if (forData) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

//                JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//                NSDictionary *json = [decoder objectWithData:data];
                //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
                if (json != nil) {
                    completionBlock(json, nil);
                }
            } else {
                completionBlock(data, nil);
            }
        }
        
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:postDictionary options:kNilOptions error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
	NSLog(@"%@: %@", function, json);
    
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    
    [request setValue:json forKey:@"json" ];
    [request setValue:function forKey:@"function"];
    
    
    
    
    
    
    AFRKHTTPClient *httpClient = [[AFRKHTTPClient alloc] initWithBaseURL:postURL];
    [httpClient registerHTTPOperationClass:[AFRKHTTPRequestOperation class]];
    //    [httpClient setDefaultHeader:@"Content-Type" value:@"image/png"];
    //    [httpClient setDefaultHeader:@"Accept" value:@"image/png"];
    [httpClient setParameterEncoding:AFRKFormURLParameterEncoding];
        
    NSMutableURLRequest *postRequest;
    
    // BUILD THE REQUEST WITH THE IMAGE DATA (IF THERE IS ANY)
    if ([fileParams count] != 0) {
        postRequest = [httpClient multipartFormRequestWithMethod:@"POST"
                                                            path:@""
                                                      parameters:request
                                       constructingBodyWithBlock:^(id<AFRKMultipartFormData> formData) {
                                           for(id key in fileParams) {
                                               MediaData *value = [fileParams objectForKey:key];
                                               [formData
                                                appendPartWithFileData: value.data
                                                name: key
                                                fileName: value.name
                                                mimeType:value.contentType];
                                           }
                                       }];
    } else {
        postRequest = [httpClient requestWithMethod:@"POST"
                                                            path:@""
                                                      parameters:request];
    }
    
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"CONTENT_TYPE"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    // SPECIFY THE CONTENT TYPES ACCEPTED
    //    [AFRKHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"image/png", nil]];
    
    
    // INIT THE OPERATION
    AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:postRequest];
    
    
    // SHOW UPLOAD PROGRESS
/*    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        
        CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
        NSString *msg;
        
        if (progress == 1.0)
            msg = @"Upload Complete!\nPlease Wait...";
        else
            msg = [NSString stringWithFormat:@"Uploading Image(s)\n%0.0f%%", (progress * 100)];
        
//        [SVProgressHUD showProgress:progress status:msg];
    }];*/
    
    
    // BUILD THE OPERATION
    [operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
        
//        [SVProgressHUD showSuccessWithStatus:@"\nIMAGE UPLOAD COMPLETE!"];
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
        NSData *json_data = [NSData dataWithData:responseObject];
        if (cache) {
            [CacheUtils saveToCacheData:json_data forUrl:[urlString stringByAppendingString:function] params:postDictionary];
        }

        if (forData) {
            completionBlock(json_data, nil);
        } else {
//            JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:json_data options:kNilOptions error:nil];
//            NSDictionary *json = [decoder objectWithData:json_data];
            //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
            //if (json != nil) {
            if (completionBlock) {
                
                NSDictionary *jsonDict = [json objectForKey:@"result"];
                NSError *error;
                if ([json objectForKey:@"error"]) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:[json objectForKey:@"error"]};
                    error = [NSError errorWithDomain:kServerUrl
                                                code:-10000
                                            userInfo:userInfo];
                }
                if (log) {
                    
                    NSMutableString *logString = [[NSMutableString alloc] init];
                    [logString appendString:@"-------------------------\n"];
                    
                    if (jsonDict)
                        [logString appendFormat:@"json: %@\n", jsonDict];
                    if (error)
                        [logString appendFormat:@"error: %@\n", error.localizedDescription];
                    [logString appendString:@"---------------------------------------------------------------------------"];
                    NSLog(@"%@: %@", function, logString);
                }
                completionBlock(jsonDict, error);
            }
            //}
            if (json == nil) {
                NSString *s = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
                NSLog(@"Invalid json: %@", s);
            }

        }
     
    } failure:^(AFRKHTTPRequestOperation *operation, NSError *error) { 
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
       NSHTTPURLResponse *response = [operation response];
        NSDictionary *headers = [response allHeaderFields];
        //NSData *json_data = [NSData dataWithData:[operation responseData]];
        //JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        // NSDictionary *json = [decoder objectWithData:json_data];
        
        
        if (error.code == -1005 && iOSVersion >= 8.0) {
            NSLog(@"try again / bug ios 8");
            [self JSONTo:urlString
          withDictionary:postDictionary
              fileParams:fileParams
                     log:log
                 forData:forData
                  sender:sender
   showActivityIndicator:showActivityIndicator
                function:function
                   cache:cache
         completionBlock:completionBlock];
            return;
        } else {
            NSLog(@"\n\nReuest Failed.\n%@\n\nHeaders:\n%@\n\n",operation.responseString,headers);
        }
        if (completionBlock) {
            completionBlock(nil, error);
            if (log) {
                NSLog(@"error - %@", error.localizedDescription);
            }
        }
        
        //  [SVProgressHUD showErrorWithStatus:@"Unable to\nUpload Profile Pic\nAt This Time."]
        
    }];
    
    // EXECUTE THE REGISTRATION OPERATION
    [operation start];
    
}

- (void) getTo:(NSString*)urlString forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock {
        
    NSURL *postURL;
	
    [self addNetworkActivity];
	if (showActivityIndicator) {
		[self addActivity];
	}
    
	postURL = [NSURL URLWithString:urlString];//[urlString stringByAppendingFormat:@"?%@",[self createRequestString:postDictionary]]];
	
    
    
    
    
    if (cache) {
        
        NSData *data = [CacheUtils cachedDataForUrl:urlString params:nil];
        if (data != nil) {
            if (forData) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

//                JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//                NSDictionary *json = [decoder objectWithData:data];
                //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
                if (json != nil) {
                    completionBlock(json);
                }
            } else {
                completionBlock(data);
            }
        }
        
    }
    
        
    //#ifdef DEBUG
	NSLog(@"%@", urlString);
    //#endif
    
    AFRKHTTPClient *httpClient = [[AFRKHTTPClient alloc] initWithBaseURL:postURL];
    [httpClient registerHTTPOperationClass:[AFRKHTTPRequestOperation class]];
    //    [httpClient setDefaultHeader:@"Content-Type" value:@"image/png"];
    //    [httpClient setDefaultHeader:@"Accept" value:@"image/png"];
    [httpClient setParameterEncoding:AFRKFormURLParameterEncoding];
    
    NSMutableURLRequest *getRequest;
    
    // BUILD THE REQUEST WITH THE IMAGE DATA (IF THERE IS ANY)
    getRequest = [httpClient requestWithMethod:@"GET"
                                          path:@""
                                    parameters:nil];
    
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"CONTENT_TYPE"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    // SPECIFY THE CONTENT TYPES ACCEPTED
    //    [AFRKHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"image/png", nil]];
    
    
    // INIT THE OPERATION
    AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:getRequest];
    
    
    // SHOW UPLOAD PROGRESS
    /*    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
     
     NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
     
     CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
     NSString *msg;
     
     if (progress == 1.0)
     msg = @"Upload Complete!\nPlease Wait...";
     else
     msg = [NSString stringWithFormat:@"Uploading Image(s)\n%0.0f%%", (progress * 100)];
     
     //        [SVProgressHUD showProgress:progress status:msg];
     }];*/
    
    
    // BUILD THE OPERATION
    [operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
        
        //        [SVProgressHUD showSuccessWithStatus:@"\nIMAGE UPLOAD COMPLETE!"];
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
        NSData *json_data = [NSData dataWithData:responseObject];
        if (cache) {
            [CacheUtils saveToCacheData:json_data forUrl:urlString params:nil];
        }
        
        if (forData) {
            completionBlock(json_data);
        } else {
//            JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//            NSDictionary *json = [decoder objectWithData:json_data];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:json_data options:kNilOptions error:nil];
            //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
            //if (json != nil) {
                completionBlock(json);
            //}
            if (json == nil) {
                NSString *s = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
                NSLog(@"Invalid json: %@", s);
            }

        }
        
    } failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
        NSHTTPURLResponse *response = [operation response];
        NSDictionary *headers = [response allHeaderFields];
        //NSData *json_data = [NSData dataWithData:[operation responseData]];
        //JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        // NSDictionary *json = [decoder objectWithData:json_data];
        
        NSLog(@"\n\nReuest Failed.\n%@\n\nHeaders:\n%@\n\n",operation.responseString,headers);
        completionBlock(nil);
        
        //  [SVProgressHUD showErrorWithStatus:@"Unable to\nUpload Profile Pic\nAt This Time."]
        
    }];
    
    // EXECUTE THE REGISTRATION OPERATION
    [operation start];
        
}

- (void) postPutTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock post:(BOOL)post{
    if ([fileParams count] > 0) {
        cache = NO;
    }
    
    NSURL *postURL;
	
    [self addNetworkActivity];
	if (showActivityIndicator) {
		[self addActivity];
	}
    
	postURL = [NSURL URLWithString:urlString];//[urlString stringByAppendingFormat:@"?%@",[self createRequestString:postDictionary]]];
	
    
    
    
    
    if (cache) {
        
        NSData *data = [CacheUtils cachedDataForUrl:urlString params:postDictionary];
        if (data != nil) {
            if (forData) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//                JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//                NSDictionary *json = [decoder objectWithData:data];
                //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
                if (json != nil) {
                    completionBlock(json);
                }
            } else {
                completionBlock(data);
            }
        }
        
    }
    
    //#ifdef DEBUG
	NSLog(@"%@: %@", urlString, [postDictionary description]);
    //#endif
    
    
    
    
    
    AFRKHTTPClient *httpClient = [[AFRKHTTPClient alloc] initWithBaseURL:postURL];
    [httpClient registerHTTPOperationClass:[AFRKHTTPRequestOperation class]];
    //    [httpClient setDefaultHeader:@"Content-Type" value:@"image/png"];
    //    [httpClient setDefaultHeader:@"Accept" value:@"image/png"];
    [httpClient setParameterEncoding:AFRKFormURLParameterEncoding];
    
    NSMutableURLRequest *postRequest;
    
    // BUILD THE REQUEST WITH THE IMAGE DATA (IF THERE IS ANY)
    if ([fileParams count] != 0) {
        postRequest = [httpClient multipartFormRequestWithMethod:post?@"POST":@"PUT"
                                                            path:@""
                                                      parameters:postDictionary
                                       constructingBodyWithBlock:^(id<AFRKMultipartFormData> formData) {
                                           for(id key in fileParams) {
                                               MediaData *value = [fileParams objectForKey:key];
                                               [formData
                                                appendPartWithFileData: value.data
                                                name: key
                                                fileName: value.name
                                                mimeType:value.contentType];
                                           }
                                       }];
    } else {
        postRequest = [httpClient requestWithMethod:post?@"POST":@"PUT"
                                               path:@""
                                         parameters:postDictionary];
    }
    
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"CONTENT_TYPE"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    //    [postRequest setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    // SPECIFY THE CONTENT TYPES ACCEPTED
    //    [AFRKHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"image/png", nil]];
    
    
    // INIT THE OPERATION
    AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:postRequest];
    
    
    // SHOW UPLOAD PROGRESS
    /*    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
     
     NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
     
     CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
     NSString *msg;
     
     if (progress == 1.0)
     msg = @"Upload Complete!\nPlease Wait...";
     else
     msg = [NSString stringWithFormat:@"Uploading Image(s)\n%0.0f%%", (progress * 100)];
     
     //        [SVProgressHUD showProgress:progress status:msg];
     }];*/
    
    
    // BUILD THE OPERATION
    [operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
        
        //        [SVProgressHUD showSuccessWithStatus:@"\nIMAGE UPLOAD COMPLETE!"];
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
        NSData *json_data = [NSData dataWithData:responseObject];
        if (cache) {
            [CacheUtils saveToCacheData:json_data forUrl:urlString params:postDictionary];
        }
        if (forData) {
            completionBlock(json_data);
        } else {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:json_data options:kNilOptions error:nil];
//            JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//            NSDictionary *json = [decoder objectWithData:json_data];
            //]\        NSLog(@"%@", [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding]);
            //if (json != nil) {
            completionBlock(json);
            if (json == nil) {
                NSString *s = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
                NSLog(@"Invalid json: %@", s);
            }
            //}
        }
        
    } failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
        
        [self removeNetworkActivity];
        if (showActivityIndicator) {
            [self removeActivity];
        }
        NSHTTPURLResponse *response = [operation response];
        NSDictionary *headers = [response allHeaderFields];
        //NSData *json_data = [NSData dataWithData:[operation responseData]];
        //JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        // NSDictionary *json = [decoder objectWithData:json_data];
        
        NSLog(@"\n\nReuest Failed.\n%@\n\nHeaders:\n%@\n\n",operation.responseString,headers);
        completionBlock(nil);
        
        //  [SVProgressHUD showErrorWithStatus:@"Unable to\nUpload Profile Pic\nAt This Time."]
        
    }];
    
    // EXECUTE THE REGISTRATION OPERATION
    [operation start];    
}


- (void) postTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock {
    [self postPutTo:urlString withDictionary:postDictionary fileParams:fileParams forData:forData sender:sender showActivityIndicator:showActivityIndicator cache:cache completionBlock:completionBlock post:YES];
    
}

- (void) putTo:(NSString*)urlString withDictionary:(NSDictionary*)postDictionary fileParams:(NSDictionary*)fileParams forData:(BOOL)forData sender:(id)sender showActivityIndicator:(BOOL)showActivityIndicator cache:(BOOL)cache completionBlock:(void (^)(id))completionBlock {
    [self postPutTo:urlString withDictionary:postDictionary fileParams:fileParams forData:forData sender:sender showActivityIndicator:showActivityIndicator cache:cache completionBlock:completionBlock post:NO];
}

@end
