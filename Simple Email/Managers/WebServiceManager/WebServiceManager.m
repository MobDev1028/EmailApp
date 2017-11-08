//
//  WebServiceManager.m
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "WebServiceManager.h"
#import "AFHTTPSessionManager.h"
#import "Constants.h"
#import "Utilities.h"

@interface WebServiceManager ()

@property (nonatomic, strong) AFHTTPSessionManager * manager;

@end

@implementation WebServiceManager
+ (WebServiceManager*)sharedServiceManager
{
    static WebServiceManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    if ( self = [super init] )
    {
        self.manager                    = [[AFHTTPSessionManager alloc] init];
        self.manager.requestSerializer  = [AFHTTPRequestSerializer serializer];
        self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [self.manager.requestSerializer setTimeoutInterval:60];
        
        //[self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"your_username" password:@"your_password"];
        [self.manager.securityPolicy setValidatesDomainName:NO];
        [self.manager.securityPolicy setAllowInvalidCertificates:YES];
    }
    
    return self;
}
-(void)GET:(NSString *)strURL onSuccess:(CompletionBlock)completionBlock onError:(FailureBlock)onError
{
    //[params setObject:kAPI_KEY_VALUE forKey:kAPI_KEY];
    
    //NSLog(@"/************************** Simple Mail START **************************/");
    //NSLog(@"/# API URL    : %@  /#", strURL);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [manager GET:strURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if (responseObject!=nil)
        {
            //NSLog(@"/# RESPONSE : %@  /#", responseObject);
            completionBlock(responseObject);
        }
        else {
            onError(@"Cannot fetch data.", 400);
        }
        //NSLog(@"/************************** Simple Mail END **************************/");
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        //NSLog(@"Error: %ld", (long)error.code);
        onError([NSString stringWithFormat:@"making the call failed: %@", error.localizedDescription], (int)error.code);
    }];
}

-(void)POST:(NSString *)strURL params:(NSMutableDictionary *)params containAttachment:(BOOL)isAttachmentAvailable accessToken:(NSString *)accessToken onSuccess:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    if ([Utilities isValidString:accessToken]) {
        //NSLog(@"/************************** Simple Mail START **************************/");
        //NSLog(@"/# API URL    : %@  /#", strURL);
        //NSLog(@"access token = %@", accessToken);
        //NSLog(@"params = %@", params);
        NSError * error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:strURL parameters:nil error:nil];
        req.timeoutInterval = 60;
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        NSString * authorization = [NSString stringWithFormat:@"Bearer %@",accessToken];
        [req setValue:authorization forHTTPHeaderField:@"Authorization"];
        [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (!error) {
                //NSLog(@"Reply JSON: %@", responseObject);
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    //blah blah
                }
            } else {
                NSLog(@"Error: %@, %@, %@", error, response, responseObject);
            }
        }] resume];
    }
    else if (isAttachmentAvailable) {
        NSArray * images = [params objectForKey:@"images"];
        [params removeObjectForKey:@"images"];

        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:strURL parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {

            for(int i = 0; i < images.count; ++i) {
                NSData * imageData = (NSData *) [images objectAtIndex:i];
                [formData appendPartWithFileData:imageData name:@"attachment" fileName:[NSString stringWithFormat:@"attachment_%d",i+1] mimeType:@"image/jpeg"];
            }
        } error:nil];

        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        NSURLSessionUploadTask *uploadTask;
        uploadTask = [manager
                      uploadTaskWithStreamedRequest:request
                      progress:^(NSProgress * _Nonnull uploadProgress) {
                          // This is not called back on the main queue.
                          // You are responsible for dispatching to the main queue for UI updates
                          dispatch_async(dispatch_get_main_queue(), ^{
                              //Update the progress view
                              onProgress(uploadProgress);
                          });
                      }
                      completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                          if (error) {
                              NSLog(@"Error: %@", error);
                              onError(error.localizedDescription, (int)error.code);
                          } else {
                              NSLog(@"%@ %@", response, responseObject);
                              completionBlock(response);
                          }
                      }];
        [uploadTask resume];
    }
    else {
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager manager] init];
        [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        manager.requestSerializer  = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager.requestSerializer setTimeoutInterval:60];
        [manager.securityPolicy setValidatesDomainName:NO];
        [manager.securityPolicy setAllowInvalidCertificates:YES];
        //NSLog(@"/************************** Simple Mail START **************************/");
        NSLog(@"/# API URL    : %@  /#", strURL);
        
        [manager POST:strURL parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            if (responseObject!=nil)
            {
                if (params.count>8) {
                    NSLog(@"params: %@",params);
                    id data = [Utilities dataToDictionary:responseObject];
                    NSLog(@"/# POST RESPONSE : %@  /#", data);
                }
                completionBlock(responseObject);
            }
            else {
                onError(@"Cannot fetch data.", 400);
            }
            
            //NSLog(@"/************************** Simple Mail END **************************/");
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"*************************************");
            NSLog(@"Error: %@", error.description);
            onError([NSString stringWithFormat:@"making the call failed: %@", error.localizedDescription], (int)error.code);
            NSLog(@"*************************************");
        }];
    }
}

- (void)getProfileForEmail:(NSString *)email completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError {
    [self GET:[NSString stringWithFormat:@"%@%@?alt=json", kPROFILE_API_BASE,email]  onSuccess:completionBlock onError:onError];
}

- (void)postWatchRequestForGMail:(NSString *)gmail accessToken:(NSString *)token params:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"https://www.googleapis.com/gmail/v1/users/me/watch?key=%@",kGOOGLE_API_KEY];
    [self POST:url params:dictionary containAttachment:NO accessToken:token onSuccess:completionBlock onError:onError onProgress:onProgress];
}

- (void)registerDeviceTokenForRemoteNotification:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"%@Users/save_token",kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:@"" onSuccess:completionBlock onError:onError onProgress:onProgress];
}

- (void)sync:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"%@Emails/get_email_updates",kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:nil onSuccess:completionBlock onError:onError onProgress:onProgress];
}

- (void)saveScheduledEmail:(NSMutableDictionary *)dictionary withAttchament:(BOOL)attachment completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"%@Emails/save_scheduled_email",kBASE_URL];
    [self POST:url params:dictionary containAttachment:attachment accessToken:@"" onSuccess:completionBlock onError:onError onProgress:onProgress];
    return;
}

- (void)getScheduledEmail:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString *url = [NSString stringWithFormat:@"%@Emails/get_scheduled_email", kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:@"" onSuccess:completionBlock onError:onError onProgress:onProgress];
    return;
}

- (void)editScheduledEmail:(NSMutableDictionary *)dictionary withAttchament:(BOOL)attachment completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString *url = [NSString stringWithFormat:@"%@Emails/update_scheduled_email", kBASE_URL];
    [self POST:url params:dictionary containAttachment:attachment accessToken:@"" onSuccess:completionBlock onError:onError onProgress:onProgress];
    return;
}

- (void)deleteScheduledEmail:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString *url = [NSString stringWithFormat:@"%@Emails/delete_scheduled_email", kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:@"" onSuccess:completionBlock onError:onError onProgress:onProgress];
    return;
}

- (void)deleteSyncRecord:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"%@Emails/delete_emails",kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:nil onSuccess:completionBlock onError:onError onProgress:onProgress];
}

- (void)deleteUser:(NSMutableDictionary *)dictionary completionBlock:(CompletionBlock)completionBlock onError:(FailureBlock)onError onProgress:(ProgressBlock)onProgress {
    NSString * url = [NSString stringWithFormat:@"%@Users/delete_device",kBASE_URL];
    [self POST:url params:dictionary containAttachment:NO accessToken:nil onSuccess:completionBlock onError:onError onProgress:onProgress];
}

@end
