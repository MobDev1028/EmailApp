//
//  OAuthManager.m
//  SimpleEmail
//
//  Created by Zahid on 16/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "OAuthManager.h"
#import "Utilities.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@implementation OAuthManager
+ (OAuthManager*)sharedOAuthManager {
    static OAuthManager *sharedOAuthManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOAuthManager = [[self alloc] init];
    });
    return sharedOAuthManager;
}

- (id) init{
    if (self = [super init]) {
//        [GIDSignIn sharedInstance].clientID = @"1089114138804-sehhcnucoolfqs9i4vu03298ucai1f22.apps.googleusercontent.com";
        [GIDSignIn sharedInstance].clientID = kCLIENT_ID;

        [GIDSignIn sharedInstance].delegate = self;
        [GIDSignIn sharedInstance].uiDelegate = self;
        [GIDSignIn sharedInstance].scopes = [NSArray arrayWithObjects:@"https://www.googleapis.com/auth/userinfo.profile" ,@"https://www.googleapis.com/auth/userinfo.email", @"https://mail.google.com",@"https://www.google.com/m8/feeds/", nil];


    }
    return self;
}

- (void) signInGoogle{
    [[GIDSignIn sharedInstance] signIn];

}

- (void) signOut{
    [[GIDSignIn sharedInstance] signInSilently];
    
}
MBProgressHUD *hud;

- (void) startOAuth{
    OAuthManager * __weak weakSelf = self;
    NSString * keyChainName = [Utilities getNewKeychainItemName];

    static NSString *const kIssuer = @"https://accounts.google.com";
    static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.662252151929-nevnqvhaqs8fole6a5f9l5m81dm5nb91:/oauthredirect";

    NSURL *issuer = [NSURL URLWithString:kIssuer];
    NSURL *redirectURI = [NSURL URLWithString:kRedirectURI];

    NSArray *scopes = [NSArray arrayWithObjects:@"https://www.googleapis.com/auth/userinfo.profile" ,@"https://www.googleapis.com/auth/userinfo.email", @"https://mail.google.com",@"https://www.google.com/m8/feeds/", nil];

    // discovers endpoints
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
                                                        completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {
                                                            
        if (!configuration) {
            NSLog(@"Error retrieving discovery document: %@", [error localizedDescription]);
//                                                        [self setGtmAuthorization:nil];
            return;
        }
                                                            
//                                                            [self logMessage:@"Got configuration: %@", configuration];
                                                            
        // builds authentication request
        OIDAuthorizationRequest *request =
                    [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                                            clientId:kCLIENT_ID
                                                                            scopes:scopes
                                                                            redirectURL:redirectURI
                                                                            responseType:OIDResponseTypeCode
                                                                            additionalParameters:nil];
                                                            // performs authentication request
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                                                            
        appDelegate.currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request    presentingViewController:(UIViewController*)weakSelf.delegate                                                                                                           callback:^(OIDAuthState *_Nullable authState,                                                                                                                      NSError *_Nullable error) {
            if (authState) {                                                                                                                   GTMAppAuthFetcherAuthorization *authorization = [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
                if (error == nil) {
                    
                    [GTMAppAuthFetcherAuthorization saveAuthorization:authorization toKeychainForName:keyChainName];
                    
                    NSString * email = [authorization userEmail];
                    
                    NSMutableArray * users =  [CoreDataManager fetchAllUsers];
                    for (NSManagedObject * object in users) {
                        NSString * existingUserEmail = [object valueForKey:kUSER_EMAIL];
                        if([email isEqualToString:existingUserEmail]) {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"User account already exist. Please try another account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [av show];
                            [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
                            return;
                        }
                    }
                    
                    NSString * keyCount = [Utilities getUserDefaultWithValueForKey:kKEY_COUNT];
                    
                    if ([Utilities isValidString:keyCount]) { // incremnet key and save it
                        int COUNT = [keyCount intValue];
                        COUNT++;
                        [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",COUNT] andKey:kKEY_COUNT];
                        keyCount = [NSString stringWithFormat:@"%d",COUNT];
                    }
                    
                    else {
                        keyCount = @"1";
                        [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",1] andKey:kKEY_COUNT];
                    }
                    // call success delegate
                    [weakSelf.delegate oAuthManager:weakSelf accountAddedsuccessfullyForEmail:[authorization userEmail] forIndex:keyCount];
                    
                    // save OAuth token
                    [Utilities setUserDefaultWithValue:keyCount andKey:kSELECTED_ACCOUNT];
                    
                    ModelUser * user = [[ModelUser alloc] init];
                    
                    user.userEmail = email;
                    user.userId = [keyCount intValue];
                    user.userKeychainItemName = keyChainName;
                    user.userOAuthAccessToken = authState.lastTokenResponse.accessToken;
                    user.tokenExpireDate = authState.lastTokenResponse.accessTokenExpirationDate;
                    user.refreshToken = authState.lastTokenResponse.refreshToken;
                    
                    /* Start Firebase listener */
                    [Utilities startFirebaseForUserId:keyCount email:email];
                    
                    [CoreDataManager mapNewUserDataWithModel:user];
                    
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    
                    /* call watch and save token api for new account */
                    //                  [appDelegate addWatchRequestForUserId:keyCount];
                    
                    /* start email listener for new account */
                    [appDelegate addEmailListnerForId:keyCount];
                    
                    /* start imap session for new account */
                    [appDelegate createImapSessionsForUid:keyCount];

                }
            }
            else {
                NSLog(@"Erorr = %@", error.localizedDescription);
                [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
            }

        }];
   }];
}

- (void) startOAuth2 {
    GTMOAuth2ViewControllerTouch *vC;
    OAuthManager * __weak weakSelf = self;
    NSString * keyChainName = [Utilities getNewKeychainItemName];
    
    
    vC = [GTMOAuth2ViewControllerTouch
          controllerWithScope:@"https://mail.google.com/"
          clientID:kCLIENT_ID
          clientSecret:nil
          keychainItemName:keyChainName
          completionHandler:^(GTMOAuth2ViewControllerTouch *viewControllerTouch, GTMOAuth2Authentication *retrievedAuth, NSError *error) {
              
              if (error == nil) {
                  NSString * email = [retrievedAuth userEmail];
                  
                  /* Here we will check if user already exist
                   than show alert and return */
                  NSMutableArray * users =  [CoreDataManager fetchAllUsers];
                  for (NSManagedObject * object in users) {
                      NSString * existingUserEmail = [object valueForKey:kUSER_EMAIL];
                      if([email isEqualToString:existingUserEmail]) {
                          UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"User account already exist. Please try another account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                          [av show];
                          [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
                          return;
                      }
                  }
                  
                  NSString * keyCount = [Utilities getUserDefaultWithValueForKey:kKEY_COUNT];
                  
                  if ([Utilities isValidString:keyCount]) { // incremnet key and save it
                      int COUNT = [keyCount intValue];
                      COUNT++;
                      [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",COUNT] andKey:kKEY_COUNT];
                      keyCount = [NSString stringWithFormat:@"%d",COUNT];
                  }
                  
                  else {
                      keyCount = @"1";
                      [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",1] andKey:kKEY_COUNT];
                  }
                  // call success delegate
                  [weakSelf.delegate oAuthManager:weakSelf accountAddedsuccessfullyForEmail:[retrievedAuth userEmail] forIndex:keyCount];

                  // save OAuth token
                  [Utilities setUserDefaultWithValue:keyCount andKey:kSELECTED_ACCOUNT];
                  
                  ModelUser * user = [[ModelUser alloc] init];
                  
                  user.userEmail = email;
                  user.userId = [keyCount intValue];
                  user.userKeychainItemName = keyChainName;
                  user.userOAuthAccessToken = [retrievedAuth accessToken];
                  user.tokenExpireDate = [retrievedAuth expirationDate];
                  user.refreshToken = [retrievedAuth refreshToken];
                  
                  /* Start Firebase listener */
                  [Utilities startFirebaseForUserId:keyCount email:email];
                  
                  [CoreDataManager mapNewUserDataWithModel:user];
                  
                  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                  
                  /* call watch and save token api for new account */
//                  [appDelegate addWatchRequestForUserId:keyCount];
                  
                  /* start email listener for new account */
                  [appDelegate addEmailListnerForId:keyCount];
                  
                  /* start imap session for new account */
                  [appDelegate createImapSessionsForUid:keyCount];
              }
              else {
                  NSLog(@"Erorr = %@", error.localizedDescription);
                  [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
              }
          }];
    
    [vC setNetworkLossTimeoutInterval:30];
    
    if (self.isFirstLogin) {
        UINavigationController * nav = (UINavigationController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [nav pushViewController:vC animated:YES];
    }
    else {
        [Utilities pushViewController:vC animated:YES];
    }
    
    [self performSelector:@selector(hideRightNavBarButtonsFor:) withObject:vC afterDelay:0.25];
}

- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    //    [myActivityIndicator stopAnimating];
    NSLog(@"ggggggg");
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn
presentViewController:(UIViewController *)viewController {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LOCAL_NOTIFICATION_GOOGLE_SIGNUP_SHOW" object:viewController];
    
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn
dismissViewController:(UIViewController *)viewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LOCAL_NOTIFICATION_GOOGLE_SIGNUP_HIDE" object:viewController];

//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    //    if (error == nil)
    {
        OAuthManager * __weak weakSelf = self;
        
        NSString * keyChainName = [Utilities getNewKeychainItemName];

        NSString *userId = user.userID;                  // For client-side use only!
        NSString *email = user.profile.email;
        
        /* Here we will check if user already exist
         than show alert and return */
        NSMutableArray * users =  [CoreDataManager fetchAllUsers];
        for (NSManagedObject * object in users) {
            NSString * existingUserEmail = [object valueForKey:kUSER_EMAIL];
            if([email isEqualToString:existingUserEmail]) {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"User account already exist. Please try another account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
                [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
                return;
            }
        }
        
        NSString * keyCount = [Utilities getUserDefaultWithValueForKey:kKEY_COUNT];
        
        if ([Utilities isValidString:keyCount]) { // incremnet key and save it
            int COUNT = [keyCount intValue];
            COUNT++;
            [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",COUNT] andKey:kKEY_COUNT];
            keyCount = [NSString stringWithFormat:@"%d",COUNT];
        }
        
        else {
            keyCount = @"1";
            [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d",1] andKey:kKEY_COUNT];
        }
        // call success delegate
        [weakSelf.delegate oAuthManager:weakSelf accountAddedsuccessfullyForEmail:email forIndex:keyCount];
        
        // save OAuth token
        [Utilities setUserDefaultWithValue:keyCount andKey:kSELECTED_ACCOUNT];
        
        ModelUser * modelUser = [[ModelUser alloc] init];
        
        modelUser.userEmail = email;
        modelUser.userId = [keyCount intValue];
        modelUser.userKeychainItemName = keyChainName;
        modelUser.userOAuthAccessToken = user.authentication.accessToken;
        modelUser.tokenExpireDate = user.authentication.idTokenExpirationDate;
        modelUser.refreshToken = user.authentication.refreshToken;
        modelUser.userName = user.profile.name;
//        modelUser.userId = [user.userID intValue];
        /* Start Firebase listener */
        [Utilities startFirebaseForUserId:keyCount email:email];
        
        [CoreDataManager mapNewUserDataWithModel:modelUser];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        /* call watch and save token api for new account */
        [appDelegate addWatchRequestForUserId:keyCount];
        
        /* start email listener for new account */
        [appDelegate addEmailListnerForId:keyCount];
        
        /* start imap session for new account */
        [appDelegate createImapSessionsForUid:keyCount];
    }
    //    else {
    //        NSLog(@"Erorr = %@", error.localizedDescription);
    //        [weakSelf.delegate oAuthManager:weakSelf didReceiveError:error];
    //    }

}

- (void) hideRightNavBarButtonsFor:(GTMOAuth2ViewControllerTouch *) vc {
    [vc.backButton setHidden:YES];
    [vc.forwardButton setHidden:YES];
}

-(void)dealloc {
    NSLog(@"dealloc - OAuthManager");
}
@end
