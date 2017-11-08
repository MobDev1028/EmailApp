//
//  OAuthManager.h
//  SimpleEmail
//
//  Created by Zahid on 16/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Google/SignIn.h>
#import <GTMAppAuth.h>

@class OAuthManager;

@protocol OAuthManagerDelegate<NSObject>
-(void)oAuthManager:(OAuthManager *)manager accountAddedsuccessfullyForEmail:(NSString *)email forIndex:(NSString *)index;
-(void)oAuthManager:(OAuthManager *)manager didReceiveError:(NSError *)error;
@end

@interface OAuthManager : NSObject<GIDSignInUIDelegate, GIDSignInDelegate, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate>
- (void) startOAuth2;
- (void) startOAuth;
- (void) signInGoogle;
- (void) signOut;


+ (OAuthManager*)sharedOAuthManager;
@property (nonatomic) BOOL isFirstLogin;
@property (nonatomic, assign) id<OAuthManagerDelegate> delegate;
@end
