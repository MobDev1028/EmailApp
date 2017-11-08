//
//  MCOIMAPSessionManager.m
//  SimpleEmail
//
//  Created by Zahid on 12/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MCOIMAPSessionManager.h"
#import "Utilities.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "Constants.h"
#import "GTMSessionFetcher.h"

@implementation MCOIMAPSessionManager {
}

-(void)createImapSessionWithUserData:(NSManagedObject *)userObject {
    GTMOAuth2Authentication * auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:[userObject valueForKey:kUSER_KEYCHANIN_ITEM_NAME]
                                                                                           clientID:kCLIENT_ID                 clientSecret:nil];
    
    //    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    //    NSManagedObject * object = [userArray lastObject];
    //
    //
    //    GTMOAuth2Authentication * authentication = [[GTMOAuth2Authentication alloc] init];
    //    authentication.refreshToken = @"";
    
    if (userObject) {
        auth.refreshToken = [userObject valueForKey:kREFRESH_TOKEN];
        auth.userEmail = [userObject valueForKey:kUSER_EMAIL];
        auth.accessToken = [userObject valueForKey:kUSER_OAUTH_ACCESS_TOKEN];
    }
    NSDate * tokenExpireDate = (NSDate *)[userObject valueForKey:kEXPIRE_DATE];
    
    /* if token expirationDate is over
     get new accessToken using refreshToken*/
    if (![Utilities isDateInFuture:tokenExpireDate]) {
        auth.accessToken = nil;
        
        if ([auth refreshToken] == nil || [auth accessToken] == nil) { // refreshToken
            [auth authorizeRequest:nil
                 completionHandler:^(NSError *error) {
                     if (error) {
                         NSLog(@"auth error: %@", error);
                         [self.delegate MCOIMAPSessionManager:self didReceiveError:error];
                     }
                     else {
                         //it shouldn´t be nil
                         [userObject setValue:auth.expirationDate forKey:kEXPIRE_DATE];
                         [userObject setValue:auth.accessToken forKey:kUSER_OAUTH_ACCESS_TOKEN];
                         [CoreDataManager updateData];
                         [self loadWithAuth:auth];
                     }
                 }];
        }
    }
    else {
        [auth beginTokenFetchWithDelegate:self
                        didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
    }
}

- (void)auth:(GTMOAuth2Authentication *)auth
finishedRefreshWithFetcher:(GTMSessionFetcher *)fetcher
       error:(NSError *)error {
    [self loadWithAuth:auth];
}

- (void)loadWithAuth:(GTMOAuth2Authentication *)auth {
    [self loadSessionWithUsername:[auth userEmail] password:nil hostname:kHOST_NAME_KEY oauth2Token:[auth accessToken]];
}
- (void)loadSessionWithUsername:(NSString *)username
                       password:(NSString *)password
                       hostname:(NSString *)hostname
                    oauth2Token:(NSString *)oauth2Token {
    
    MCOIMAPSession *imapSession = [[MCOIMAPSession alloc] init];
    imapSession.hostname = hostname;
    imapSession.port = kIMAP_PORT;
    imapSession.username = username;
    imapSession.password = password;
    if (oauth2Token != nil) {
        imapSession.OAuth2Token = oauth2Token;
        imapSession.authType = MCOAuthTypeXOAuth2;
    }
    imapSession.allowsFolderConcurrentAccessEnabled = YES;
    
    imapSession.connectionType = MCOConnectionTypeTLS;
    MCOIMAPSessionManager * __weak weakSelf = self;
    imapSession.connectionLogger = ^(void * connectionID, MCOConnectionLogType type, NSData * data) {
        @synchronized(weakSelf) {
            if (type != MCOConnectionLogTypeSentPrivate) {
                //NSLog(@"event logged:%p %li withData: %@", connectionID, (long)type, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
        }
    };
    if (imapSession != nil) {
        [self.delegate MCOIMAPSessionManager:self sessionCreatedSuccessfullyWithObject:imapSession];
        
        [self.strongDelegate MCOIMAPSessionManager:self sessionCreatedWithObject:imapSession];
    }
}

-(void)dealloc {
    NSLog(@"dealloc - MCOIMAPSessionManager");
}
@end
