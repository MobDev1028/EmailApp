//
//  WebServiceManager.h
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(id response);
typedef void (^FailureBlock)(NSString *resultMessage, int errorCode);
typedef void (^ProgressBlock)(NSProgress * progress);

@interface WebServiceManager : NSObject

+ (WebServiceManager*)sharedServiceManager;

- (void)getProfileForEmail:(NSString *)email completionBlock:(CompletionBlock)completionBlock
           onError:(FailureBlock)onError;
- (void)postWatchRequestForGMail:(NSString *)gmail accessToken:(NSString *)token params:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)registerDeviceTokenForRemoteNotification:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)sync:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)deleteSyncRecord:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)deleteUser:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)saveScheduledEmail:(NSMutableDictionary *)dictionary withAttchament:(BOOL)attachment completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)getScheduledEmail:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)editScheduledEmail:(NSMutableDictionary *)dictionary withAttchament:(BOOL)attachment completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
- (void)deleteScheduledEmail:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress;
@end
