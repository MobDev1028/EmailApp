//
//  UtilityImapSessionManager.m
//  SimpleEmail
//
//  Created by Zahid on 15/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "UtilityImapSessionManager.h"
#import "MCOIMAPSessionManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "MailCoreServiceManager.h"
#import "SharedInstanceManager.h"

@implementation UtilityImapSessionManager {
    MCOIMAPSessionManager * imapSessionManager;
}

- (id) init {
    self = [super init];
    if (self != nil) {
    }
    return self;
}

- (void)createSessionForUser:(NSString *)userId type:(int)type {
    self.user = userId;
    self.sessionType = type;
    imapSessionManager = [[MCOIMAPSessionManager alloc] init];
    imapSessionManager.delegate = self;
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.user longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    [imapSessionManager createImapSessionWithUserData:object];
}

#pragma - mark MCOIMAPSessionManagerDelegate
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)impSession {
    self.imapSession = impSession;
    manager.delegate = nil;
}

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    manager.delegate = nil;
}
-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
    NSLog(@"dealloc : UtilityImapSessionManager");
}
@end
