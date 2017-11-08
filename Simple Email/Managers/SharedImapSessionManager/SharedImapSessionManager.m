//
//  SharedImapSessionManager.m
//  SimpleEmail
//
//  Created by Zahid on 26/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SharedImapSessionManager.h"
#import "MCOIMAPSessionManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "MailCoreServiceManager.h"
#import "SharedInstanceManager.h"

@implementation SharedImapSessionManager
@synthesize user;
+ (SharedImapSessionManager*)sharedSession {
    static SharedImapSessionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        
    });
    return sharedManager;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        
       /* MCOIMAPSessionManager * imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        imapSessionManager.delegate = self;
        NSString * usr = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
        
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[usr longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        [imapSessionManager createImapSessionWithUserData:object];*/
        
    }
    return self;
}
-(void)createSessionForUser:(NSString *)userId {
    self.user = userId;
    MCOIMAPSessionManager * imapSessionManager = [[MCOIMAPSessionManager alloc] init];
    imapSessionManager.delegate = self;
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.user longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    [imapSessionManager createImapSessionWithUserData:object];
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)impSession {
}

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
}
@end
