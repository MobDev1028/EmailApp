//
//  AppDelegate.h
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Reachability.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "ModelEmail.h"

#import <Google/SignIn.h>
#import <AppAuth.h>

@class SWRevealViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * window;
@property (strong, nonatomic) UINavigationController * navigationController;
@property (strong, nonatomic) SWRevealViewController *viewController;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
//@property (readonly, strong, nonatomic) NSManagedObjectContext *privateQManagedObject2;
//@property (readonly, strong, nonatomic) NSManagedObjectContext *privateQManagedObject;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) dispatch_block_t expirationHandler;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) BOOL background;
@property (assign, nonatomic) BOOL internetAlertShown;
@property (assign, nonatomic) BOOL jobExpired;
@property (strong, nonatomic) NSMutableArray        *emails;

@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentAuthorizationFlow;

- (void)saveContext;
- (nonnull NSURL *)applicationDocumentsDirectory;
- (nonnull SWRevealViewController *)getRootView;
- (void)updateRootViewWithSideMenu;
- (void)setRootViewForSignUp;
- (void)customizeNavigationBar:(nonnull UINavigationController *)navigationController;
- (void)sendFcmRegistrationToken:(nonnull NSString *)token email:(nonnull NSString *)email refreshtoken:(nonnull NSString *)refreshToken accessToken:(nonnull NSString *)accessToken;
- (void)addWatchRequestForUserId:(nonnull NSString * )uid;
- (void)addEmailListnerForId:(nonnull NSString *)uid;
- (void)createImapSessionsForUid:(nonnull NSString *)uid;
- (void)removeImapSessionsForId:(nonnull NSString *)uid;
- (void)removeEmailListnersForId:(nonnull NSString *)uid;
- (nonnull NSManagedObjectContext *)privateQManagedObject2;
- (void)setBadgeCount:(long)count;
- (void) addEmail:(nonnull ModelEmail *) email forEntity:(nonnull NSString *) entity;

@end

