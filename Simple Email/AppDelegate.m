//
//  AppDelegate.m
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "AppDelegate.h"
#import "Utilities.h"
#import "Constants.h"
#import "SignupViewController.h"
#import "IQKeyboardManager.h"
#import "SWRevealViewController.h"
#import "InboxViewController.h"
#import "SideMenuViewController.h"
#import "RegularInboxViewController.h"
#import "EmailListenerManager.h"
#import "SharedInstanceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "QuickResponseSyncManager.h"
#import "SendLaterSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SnoozePreferenceManager.h"
#import "WebServiceManager.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "MailThreadViewController.h"
#import "UtilityImapSessionManager.h"
#import "CoreDataManager.h"



@import Firebase;
@import FirebaseDatabase;
@import FirebaseMessaging;

@interface AppDelegate ()

@property (nonatomic, strong) NSTimer   *populateEmailsTimer;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FIRApp configure];
    [Utilities setDefaults];
    [self configureFirebaseListeners];
    [self saveDefaults];
    [self addReachabilityObserver];
    [SharedInstanceManager sharedInstance].isEmailDetailOpened = NO;
    
    // Remove All Emails From CoreData
    //[CoreDataManager deleteAllEmails];
    
    NSString * currentAccount = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    if ([Utilities isValidString:currentAccount]) {
        NSMutableArray * users = [CoreDataManager fetchAllUsers];
        if (users.count == 0) {
            [Utilities setUserDefaultWithValue:@"" andKey:kSELECTED_ACCOUNT];
            [self setRootViewForSignUp];
        }
        else {
            NSManagedObject * object = [users objectAtIndex:0];
            NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
            [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
            [self updateRootViewWithSideMenu];
        }
    }
    else {
        [self setRootViewForSignUp];
    }
    
    [[IQKeyboardManager sharedManager] setEnable:YES];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    [[IQKeyboardManager sharedManager] setShouldShowTextFieldPlaceholder:YES];
    [self registerRemoteNotification];
    
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if (notification){
        NSLog(@"notification = %@",notification.description );
    }
    //self.internetAlertShown = YES;
    [Utilities saveContacts];
    
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
//    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
//    [GIDSignIn sharedInstance].delegate = self;

    return YES;
}
-(void)setBadgeCount:(long)count {
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
}

// With "FirebaseAppDelegateProxyEnabled": NO
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *devicetokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    [Utilities setUserDefaultWithValue:devicetokenString andKey:kDEVICE_TOKEN];
    
    [[FIRInstanceID instanceID] setAPNSToken:deviceToken
                                        type:FIRInstanceIDAPNSTokenTypeProd];
}

- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error.description);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}

- (void)tokenRefreshNotification:(NSNotification *)notification {
    /*NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * object in users) {
        NSString * uid = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        // Call watch API for each user 
        [self addWatchRequestForUserId:uid];
    }
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    // TODO: If necessary send token to application server.
    */
}

-(void)registerRemoteNotification {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes =
        (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        UNAuthorizationOptions authOptions =
        UNAuthorizationOptionAlert
        | UNAuthorizationOptionSound
        | UNAuthorizationOptionBadge;
        
        [[UNUserNotificationCenter currentNotificationCenter]
         requestAuthorizationWithOptions:authOptions
         completionHandler:^(BOOL granted, NSError * _Nullable error) {
         }
         ];
        // For iOS 10 display notification (sent via APNS)
        [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
        // For iOS 10 data message (sent via FCM)
        [[FIRMessaging messaging] setRemoteMessageDelegate:self];
#endif
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

-(void)registerLocalNotification {
    //register local notifications
    if( SYSTEM_VERSION_LESS_THAN(@"10.0")) {
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }
    else {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if(!error) {
                [[UIApplication sharedApplication] registerForRemoteNotifications]; // required to get the app to do anything at all about push notifications
                NSLog( @"Push registration success." );
            }
            else {
                NSLog( @"Push registration FAILED" );
                NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
                NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
            }
        }];
    }
}


#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
/* this method will called when app is active an local + remote notification receive, iOS 10 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // Print message ID.
    [self syncSnoozeEmailToFirebase:nil UNNotification:notification openEmailDetail:NO];
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"push 1 = %@", userInfo);
}

// Receive data message on iOS 10 devices.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"push 2 =  %@", [remoteMessage appData]);
}
#endif
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    NSLog(@"push 3 = %@", userInfo);
    if ( application.applicationState == UIApplicationStateActive ) {
        // app was already in the foreground
    }
    else {
        // app was just brought from background to foreground
        [self openEmailDetailWithInfo:userInfo withDelay:1.0];
    }
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
//    return [[GIDSignIn sharedInstance] handleURL:url
//                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
//                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    if ([_currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        _currentAuthorizationFlow = nil;
        return YES;
    }
    return NO;
}

//- (void)signIn:(GIDSignIn *)signIn
//didSignInForUser:(GIDGoogleUser *)user
//     withError:(NSError *)error {
//    // Perform any operations on signed in user here.
//    NSString *userId = user.userID;                  // For client-side use only!
////    NSString *idToken = user.authentication.idToken; // Safe to send to the server
////    NSString *fullName = user.profile.name;
////    NSString *givenName = user.profile.givenName;
////    NSString *familyName = user.profile.familyName;
//    NSString *email = user.profile.email;
//    // ...
//}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    /* this is calling when user tap on banner for both local and remote notification when app is in background iOS 10 */
    NSLog(@"push 4 = User Info : %@",userInfo);
    NSString * uniqId = [userInfo objectForKey:kSNOOZED_FIREBASE_ID];
    if ([Utilities isValidString:uniqId]) {
        [self syncSnoozeEmailToFirebase:nil UNNotification:response.notification openEmailDetail:YES];
    }
    else {
        [self openEmailDetailWithInfo:userInfo withDelay:1.0];
    }
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    BOOL openView = NO;
    if ( application.applicationState == UIApplicationStateActive ) {
        // app was already in the foreground
    }
    else {
        // app was just brought from background to foreground
        openView = YES;
    }
    [self syncSnoozeEmailToFirebase:notification UNNotification:nil openEmailDetail:openView];
}
-(void)openEmailDetailWithInfo:(NSDictionary *)userInfo withDelay:(double)delay {
    /* add dealy so that view render first if app is opened first time */
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        /* code to be executed on the main queue after delay */
        BOOL isViewAdded = [SharedInstanceManager sharedInstance].isEmailDetailOpened;
        if (!isViewAdded) {
            MailThreadViewController * mailThreadViewController = [[MailThreadViewController alloc] initWithNibName:@"MailThreadViewController" bundle:nil];
            mailThreadViewController.pushDatadictionary = userInfo;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:mailThreadViewController];
            [self.viewController presentViewController:navigationController animated:YES completion:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter ] postNotificationName:kNEW_EMAIL_NOTIFICATION object:nil userInfo:userInfo];
        }
    });
}

-(void)syncSnoozeEmailToFirebase:(UILocalNotification *)notification UNNotification:(UNNotification*)UNNotification openEmailDetail:(BOOL)openDetail {
    NSDictionary * userInfo = nil;
    NSString * alterBody = nil;
    if (notification == nil) {
        userInfo = UNNotification.request.content.userInfo;
        alterBody = UNNotification.request.content.body;
    }
    else {
        userInfo = [notification userInfo];
        alterBody = [notification alertBody];
    }
    //NSString * alertTitle = nil;
    NSString * uniqId = [userInfo objectForKey:@"decimal_id"];
    NSString * userId = [userInfo objectForKey:kSELECTED_ACCOUNT];
    NSString * firebaseId = [userInfo objectForKey:kSNOOZED_FIREBASE_ID];
    NSLog(@"snoozed userInfo = %@", userInfo);
    if ([Utilities isValidString:uniqId]) {
        //alertTitle = @"Snooze Alert";
        if ([Utilities isValidString:firebaseId]) {
            [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:firebaseId];
        }
        if (openDetail) {
            [self openEmailDetailWithInfo:userInfo withDelay:0.5];
        }
        /*NSMutableArray * array = [CoreDataManager fetchSingleEmailForUniqueId:[uniqId longLongValue] andUserId:[userId longLongValue]];
         
         for (int i = 0; i<array.count; ++i) {
         NSManagedObject * obj = [array objectAtIndex:i];
         [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_SNOOZED];
         [obj setValue:[NSNumber numberWithBool:NO] forKey:kSNOOZED_ONLY_IF_NO_REPLY];
         [obj setValue:nil forKey:kSNOOZED_DATE];
         }
         [CoreDataManager updateData];
         
         [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_SNOOZE object:nil];*/
    }
}

- (void)addReachabilityObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
    self.hostReachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
    [self.hostReachability startNotifier];
    
}
- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    [self logReachability: reachability];
}
- (void)logReachability:(Reachability *)reachability {
    
    NSString *howReachableString = nil;
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.internetAlertShown = NO;
    });
    
    switch (reachability.currentReachabilityStatus) {
        case NotReachable: {
            
            if (!self.internetAlertShown) {
                self.internetAlertShown = YES;
                howReachableString = @"Please check your internet connection and try again.";
            }
            break;
        }
        case ReachableViaWWAN: {
            //howReachableString = @"reachable by cellular data";
            if (!self.internetAlertShown) {
                self.internetAlertShown = YES;
                [self startSessions];
            }
            break;
        }
        case ReachableViaWiFi: {
            if (!self.internetAlertShown) {
                self.internetAlertShown = YES;
                [self startSessions];
            }
            break;
        }
    }
    if (howReachableString != nil) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Internet error!" message:howReachableString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    }
}
-(void)startSessions {
    NSLog(@"startSessions");
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * object in users) {
        /* Remove all email listners */
        NSString * uid = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        [self removeEmailListnersForId:uid];
        
        /* remove all imap shahred instances */
        [self removeImapSessionsForId:uid];
        
        /* strat emailListner For All users */
        [self addEmailListnerForId:uid];
        
        /* Start additional imap session for utility
         works i.e delete, mark seen etc for each active
         account */
        [self createImapSessionsForUid:uid];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kINTERNET_AVAILABLE object:nil];
}
- (void)addWatchRequestForUserId:(NSString *)userId {
    if (userId != nil) {
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        
        NSString * keychain = [object valueForKey:kUSER_KEYCHANIN_ITEM_NAME];
        GTMOAuth2Authentication * auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychain
                                                                                               clientID:kCLIENT_ID                 clientSecret:nil];
        
        auth.refreshToken = [object valueForKey:kREFRESH_TOKEN];
        auth.userEmail = [object valueForKey:kUSER_EMAIL];
        auth.accessToken = [object valueForKey:kUSER_OAUTH_ACCESS_TOKEN];
        NSString * email = [object valueForKey:kUSER_EMAIL];
        NSDate * tokenExpireDate = (NSDate *)[object valueForKey:kEXPIRE_DATE];
        
        /* if token expirationDate is over
         get new accessToken using refreshToken*/
        if (![Utilities isDateInFuture:tokenExpireDate]) {
            auth.accessToken = nil;
            
            if ([auth refreshToken] == nil || [auth accessToken] == nil) { // refreshToken
                [auth authorizeRequest:nil
                     completionHandler:^(NSError *error) {
                         if (error) {
                             NSLog(@"auth error: %@", error);
                         }
                         else {
                             //it shouldn´t be nil
                             [object setValue:auth.expirationDate forKey:kEXPIRE_DATE];
                             [object setValue:auth.accessToken forKey:kUSER_OAUTH_ACCESS_TOKEN];
                             [CoreDataManager updateData];
                             [self callWatchApiWithToken:auth.accessToken email:email];
                             //NSLog(@"access token = %@", auth.accessToken);
                             NSString *refreshedToken = [[FIRInstanceID instanceID] token];
                             
                             [self sendFcmRegistrationToken:refreshedToken email:email refreshtoken:[auth refreshToken] accessToken:[auth accessToken]];
                         }
                     }];
            }
        }
        else {
            [self callWatchApiWithToken:auth.accessToken email:email];
            //NSLog(@"access token = %@", auth.accessToken);
            NSString *refreshedToken = [[FIRInstanceID instanceID] token];
            
            [self sendFcmRegistrationToken:refreshedToken email:email refreshtoken:[auth refreshToken] accessToken:[auth accessToken]];
        }
    }
}
-(void)callWatchApiWithToken:(NSString *)accessToken email:(NSString *)email {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    //NSArray * array = [[NSArray alloc] initWithObjects:@"INBOX", nil];
    //[dictionary setObject:array forKey:@"labelIds"];
    [dictionary setObject:@"projects/simpleemailsample/topics/simplemail-topic" forKey:@"topicName"];
    [[WebServiceManager sharedServiceManager] postWatchRequestForGMail:email accessToken:accessToken params:dictionary completionBlock:^(id response) {
        if (response != nil) {
        }
    } onError:^( NSString *resultMessage , int erorrCode)
     {
         //UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         //[av show];
     }onProgress:^(NSProgress * progress) {
         
     }];
}
- (void)sendFcmRegistrationToken:(NSString *)token email:(NSString *)email refreshtoken:(NSString *)refreshToken accessToken:(NSString *)accessToken {
    NSString* uniqueIdentifier = [Utilities getDeviceIdentifier]; // IOS 6+
    NSLog(@"Add token UUID:: %@", uniqueIdentifier);
    //NSString * deviceUid = [Utilities getUserDefaultWithValueForKey:kDEVICE_TOKEN];
    //deviceUid = @"AIzaSyA5qvECMTHJlWZs4WER1BEq7AKCLpC63yE";
    if (![Utilities isValidString:uniqueIdentifier] || ![Utilities isValidString:email] || ![Utilities isValidString:token]) {
        return;
    }
    
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:kSECRET forKey:@"secret"];
    [dictionary setObject:@"iPhone" forKey:@"device_type"];
    [dictionary setObject:token forKey:@"app_token"];
    [dictionary setObject:refreshToken forKey:@"refresh_token"];
    [dictionary setObject:accessToken forKey:@"access_token"];
    [dictionary setObject:uniqueIdentifier forKey:@"device_udid"];
    [dictionary setObject:email forKey:@"user_email"];
    [[WebServiceManager sharedServiceManager] registerDeviceTokenForRemoteNotification:dictionary completionBlock:^(id response) {
        if (response != nil) {
            id obj = [Utilities dataToDictionary:response];
            NSString * unreadCount = [obj valueForKey:@"deviceUnreadCount"];
            [self setBadgeCount:[unreadCount integerValue]];
        }
    } onError:^( NSString *resultMessage , int erorrCode)
     {
         //UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         //[av show];
     }onProgress:^(NSProgress * progress) {
         
     }];
    
}

-(void)setRootViewForSignUp {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:[[SignupViewController alloc] initWithNibName:@"SignupViewController" bundle:nil]];
    
    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];
}
-(void)updateRootViewWithSideMenu {
    RegularInboxViewController *frontViewController = [[RegularInboxViewController alloc] init];
    frontViewController.fetchMultipleAccount = YES;
    UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    frontViewController.renderView = YES;
    SideMenuViewController *rearViewController = [[SideMenuViewController alloc] init];
    [rearViewController setPresentedRow:1 andSection:0];
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                    initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    mainRevealController.delegate = self;
    self.viewController = mainRevealController;
    self.window.rootViewController = self.viewController;
    [self customizeNavigationBar:frontNavigationController];
    [self.window makeKeyAndVisible];
}

-(void)customizeNavigationBar:(UINavigationController *)navigationController {
    UIColor * navBarColor = [UIColor colorWithRed:43.0f/255.0f green:52.0f/255.0f blue:66.0f/255.0f alpha:1.0f];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // iOS 6.1 or earlier
        navigationController.navigationBar.tintColor = navBarColor;
    } else {
        // iOS 7.0 or later
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [UIColor colorWithWhite:.0f alpha:1.f];
        shadow.shadowOffset = CGSizeMake(0, -1);
        
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor whiteColor]
                                                               ,
                                                               
                                                               NSFontAttributeName: [UIFont fontWithName:@"SFUIText-Semibold" size:17]
                                                               }];
        
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        navigationController.navigationBar.barTintColor = navBarColor;
        navigationController.navigationBar.translucent = NO;
    }
}

-(void)configureFirebaseListeners {
    [FIRDatabase database].persistenceEnabled = YES;
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * object in users) {
        [Utilities startFirebaseForUserId:[NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]] email:[object valueForKey:kUSER_EMAIL]];
    }
}

-(void)saveDefaults {
    NSString * isDefaultSnoozeAdded = [Utilities getUserDefaultWithValueForKey:@"isDefaultAdded"];
    if (![Utilities isValidString:isDefaultSnoozeAdded]) {
        [Utilities setUserDefaultWithValue:@"isDefaultAdded" andKey:@"isDefaultAdded"];
        [Utilities preloadSnoozePreferencesForEmail:@"" andUserId:@"" saveLocally:YES];
        [Utilities preloadSendLaterPreferencesForEmail:@"" andUserId:@"" saveLocally:YES];
    }
}

- (void) addEmail:(ModelEmail *) email forEntity:(NSString *) entity{
 
    if(self.emails == nil) {
        self.emails = [[NSMutableArray alloc] init];
    }
    
    [self.emails addObject:@{@"entity": entity, @"email" : email}];
    
    if(self.emails.count >= 48) {
        
        [self dispatchEmailsPopulation];
    }
    else{
         NSLog(@"############ Collecting Emails : %lu ############", (unsigned long)self.emails.count);
    }
    
    if (self.populateEmailsTimer != nil) {
        
        [self.populateEmailsTimer invalidate];
        self.populateEmailsTimer = nil;
    }
    
    self.populateEmailsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(dispatchEmailsPopulation) userInfo:nil repeats:NO];
}

- (void) dispatchEmailsPopulation {

    for (int i = 0 ; i < self.emails.count; ++i) {
        NSLog(@"############ Populating Emails : %d ############", i);
        
        NSDictionary *dictionary = [self.emails objectAtIndex:i];
        ModelEmail *emailData = [dictionary objectForKey:@"email"];
        NSString *strEntity = [dictionary objectForKey:@"entity"];
        [CoreDataManager mapEmailDataWithModel:emailData forUserId:emailData.userId entity:strEntity];
    }
    
    [self.emails removeAllObjects];
    
    if (self.populateEmailsTimer != nil) {
    
        [self.populateEmailsTimer invalidate];
        self.populateEmailsTimer = nil;
    }
}

#pragma - mark SWRevealViewControllerDelegate
- (NSString*)stringFromFrontViewPosition:(FrontViewPosition)position {
    NSString *str = nil;
    if ( position == FrontViewPositionLeft ) str = @"FrontViewPositionLeft";
    if ( position == FrontViewPositionRight ) str = @"FrontViewPositionRight";
    if ( position == FrontViewPositionRightMost ) str = @"FrontViewPositionRightMost";
    if ( position == FrontViewPositionRightMostRemoved ) str = @"FrontViewPositionRightMostRemoved";
    return str;
}
- (SWRevealViewController *)getRootView {
    return self.viewController;
}
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position {
    //NSLog( @"%@: %@", NSStringFromSelector(_cmd), [self stringFromFrontViewPosition:position]);
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    //NSLog( @"%@: %@", NSStringFromSelector(_cmd), [self stringFromFrontViewPosition:position]);
}

- (void)revealController:(SWRevealViewController *)revealController willRevealRearViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController didRevealRearViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController willHideRearViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController didHideRearViewController:(UIViewController *)rearViewController {
    // NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController willShowFrontViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController didShowFrontViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController willHideFrontViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(SWRevealViewController *)revealController didHideFrontViewController:(UIViewController *)rearViewController {
    //NSLog( @"%@", NSStringFromSelector(_cmd));
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [[FIRMessaging messaging] disconnect];
    
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * object in users) {
        /* Remove all email listners */
        NSString * uid = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        [self removeEmailListnersForId:uid];
        
        /* remove all imap shahred instances */
        [self removeImapSessionsForId:uid];
    }
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}
-(void)removeEmailListnersForId:(NSString *)uid {
    /* Remove all email listners */
        NSMutableDictionary * listnersDictionary = [[SharedInstanceManager sharedInstance] sharedEmailListners];
        EmailListenerManager * manager = [listnersDictionary objectForKey:uid];
        if (manager != nil) {
            [manager stopListner];
            [listnersDictionary removeObjectForKey:uid];
            manager = nil;
        }
}
- (void)addEmailListnerForId:(NSString *)uid {
        NSMutableDictionary * listnersDictionary = [[SharedInstanceManager sharedInstance] sharedEmailListners];
        EmailListenerManager * manager = [listnersDictionary objectForKey:uid];
        if (manager == nil) {
            EmailListenerManager * listner = [[EmailListenerManager alloc] initWithUser:[uid integerValue]];
            [listnersDictionary setObject:listner forKey:uid];
        }
}
-(void)removeImapSessionsForId:(NSString *)uid {
    /* remove all imap shahred instances */
    NSMutableDictionary * imapDictionary = [[SharedInstanceManager sharedInstance] imapSharedSessions];
    UtilityImapSessionManager * utilityImapSessionManager = [imapDictionary objectForKey:uid];
    if (utilityImapSessionManager != nil) {
        utilityImapSessionManager.imapSession = nil;
        [utilityImapSessionManager.imapSession cancelAllOperations];
        [imapDictionary removeObjectForKey:uid];
        utilityImapSessionManager = nil;
    }

    NSMutableDictionary * imapSyncDictionary = [[SharedInstanceManager sharedInstance] imapSyncSessions];
    UtilityImapSessionManager * utilityImapSyncSessionManager = [imapSyncDictionary objectForKey:uid];
    if (utilityImapSyncSessionManager != nil) {
        utilityImapSyncSessionManager.imapSession = nil;
        [utilityImapSyncSessionManager.imapSession cancelAllOperations];
        [imapSyncDictionary removeObjectForKey:uid];
        utilityImapSyncSessionManager = nil;
    }
}
- (void)createImapSessionsForUid:(NSString *)uid {
    NSMutableDictionary * imapDictionary = [[SharedInstanceManager sharedInstance] imapSharedSessions];
    MCOIMAPSession * imapSession = [imapDictionary objectForKey:uid];
    if (imapSession == nil) {
        UtilityImapSessionManager * utilityImapSessionManager = [[UtilityImapSessionManager alloc] init];
        [utilityImapSessionManager createSessionForUser:uid type:1];
        [[SharedInstanceManager sharedInstance].imapSharedSessions setObject:utilityImapSessionManager forKey:uid];
    }
    
    NSMutableDictionary * imapSyncDictionary = [[SharedInstanceManager sharedInstance] imapSyncSessions];
    MCOIMAPSession * imapSyncSession = [imapSyncDictionary objectForKey:uid];
    if (imapSyncSession == nil) {
        UtilityImapSessionManager * utilityImapSessionManager = [[UtilityImapSessionManager alloc] init];
        [utilityImapSessionManager createSessionForUser:uid type:2];
        [[SharedInstanceManager sharedInstance].imapSyncSessions setObject:utilityImapSessionManager forKey:uid];
    }
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [SharedInstanceManager sharedInstance];
    
    [self connectToFcm];
    
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * object in users) {
        
        NSString * uid = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        /* strat emailListner For All users */
        [self addEmailListnerForId:uid];
        
        /* Start additional imap session for utility
         works i.e delete, mark seen etc for each active
         account */
        [self createImapSessionsForUid:uid];
    }
    
    /* add dely so that firebase get initialised */
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        /* code to be executed on the main queue after delay */
        
        NSMutableArray * users = [CoreDataManager fetchAllUsers];
        for (NSManagedObject * object in users) {
            NSString * uid = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
            
            /* Call watch API for each user */
            [self addWatchRequestForUserId:uid];
            
            /* update expire snooze on firebase */
            NSMutableArray * snoozedEmails = [CoreDataManager fetchSnoozedEmailsForUserId:[uid longLongValue]];
            for (NSManagedObject * email in snoozedEmails) {
                NSDate * snoozedDate = [email valueForKey:kSNOOZED_DATE];
                if (![Utilities isDateInFuture:snoozedDate]) { // notification has been fired
                    NSString * firebaseId = [email valueForKey:kSNOOZED_FIREBASE_ID];
                    if ([Utilities isValidString:firebaseId]) {
                        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:uid performAction:kActionDelete firebaseId:firebaseId];
                    }
                }
            }
        }
    });
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)privateQManagedObject2 {
    NSThread *thisThread = [NSThread currentThread];
    if (thisThread == [NSThread mainThread])
    {
        //For the Main thread just return default context iVar
        return [self managedObjectContext];
    }
    else
    {
        NSManagedObjectContext *threadManagedObjectContext = [[thisThread threadDictionary] objectForKey:@"MOC_KEY"];
        if (threadManagedObjectContext == nil)
        {
            threadManagedObjectContext = [[NSManagedObjectContext alloc] init];
            
            [threadManagedObjectContext setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
            [[thisThread threadDictionary] setObject:threadManagedObjectContext forKey:@"MOC_KEY"];
        }
        return threadManagedObjectContext;
    }
}
// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SimpleEmail.sqlite"];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        
        /* Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}





@end
