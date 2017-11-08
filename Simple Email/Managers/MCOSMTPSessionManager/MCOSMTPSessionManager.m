//
//  MCOSMTPSessionManager.m
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MCOSMTPSessionManager.h"
#import "Utilities.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "Constants.h"
#import <GTMAppAuth.h>

@implementation MCOSMTPSessionManager


-(void)createSmtpSessionForKeychainItemName:(NSString *)keychainItemName {
//    GTMOAuth2Authentication * auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainItemName
//                                                                                           clientID:kCLIENT_ID                 clientSecret:nil];
    
    GTMAppAuthFetcherAuthorization *auth = [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:keychainItemName];
    
    if ([[[auth authState] lastTokenResponse] refreshToken] == nil || [[[auth authState] lastTokenResponse] accessToken] == nil) { // refreshToken
        [auth authorizeRequest:nil
             completionHandler:^(NSError *error) {
                 if (error) {
                     NSLog(@"error: %@", error);
                     [self.delegate MCOSMTPSessionManager:nil didReceiveError:error];
                     
                 }
                 else {
                     // NSLog(@"accessToken: %@", auth.accessToken); //it shouldn´t be nil
                  [self loadMCOSMTPSessionWithAuth:auth];
                 }
             }];
    }
    else {
        //[self loadMCOSMTPSessionWithAuth:auth];
        [auth authorizeRequest:nil delegate:self didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
    }
}

- (void)auth:(GTMAppAuthFetcherAuthorization *)auth finishedRefreshWithFetcher:(GTMSessionFetcher *) fetcher
       error:(NSError *)error {
    if (error != nil) {
        
    }
    else {
        [self loadMCOSMTPSessionWithAuth:auth];
    }
}
-(void)loadMCOSMTPSessionWithAuth:(GTMAppAuthFetcherAuthorization *)auth {
        [self loadSessionWithUsername:[auth userEmail] password:nil hostname:kSMTP_HOST_NAME_KEY oauth2Token:[auth authState].lastTokenResponse.accessToken];
}

- (void)loadSessionWithUsername:(NSString *)username
                       password:(NSString *)password
                       hostname:(NSString *)hostname
                    oauth2Token:(NSString *)oauth2Token {
    
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = hostname;
    smtpSession.port = kSMTP_PORT;
    smtpSession.username = username;
    smtpSession.password = password;
    
    if (oauth2Token != nil) {
        smtpSession.OAuth2Token = oauth2Token;
        smtpSession.authType = MCOAuthTypeXOAuth2;
    }
    //smtpSession.authType = (MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin);
    smtpSession.connectionType = MCOConnectionTypeTLS;
    MCOSMTPSessionManager * __weak weakSelf = self;
    smtpSession.connectionLogger = ^(void * connectionID, MCOConnectionLogType type, NSData * data) {
        @synchronized(weakSelf) {
            if (type != MCOConnectionLogTypeSentPrivate) {
                 //NSLog(@"event logged:%p %li withData: %@", connectionID, (long)type, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
        }
    };
    [self.delegate MCOSMTPSessionManager:self sessionCreatedSuccessfullyWithObject:smtpSession];
    
    
}
-(void)dealloc {
    NSLog(@"dealloc : MCOSMTPSessionManager");
}
@end
