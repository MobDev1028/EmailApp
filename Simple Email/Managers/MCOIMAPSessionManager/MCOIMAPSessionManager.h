//
//  MCOIMAPSessionManager.h
//  SimpleEmail
//
//  Created by Zahid on 12/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "CoreDataManager.h"

@class MCOIMAPSessionManager;

@protocol MCOIMAPSessionManagerDelegate<NSObject>
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession;
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error;
@end
@protocol MCOIMAPSessionManagerStrongDelegate<NSObject>
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedWithObject:(MCOIMAPSession *)imapSession;
@end
@interface MCOIMAPSessionManager : NSObject
@property (nonatomic, assign) id<MCOIMAPSessionManagerDelegate> delegate;
@property (nonatomic, strong) id<MCOIMAPSessionManagerStrongDelegate> strongDelegate;
-(void)createImapSessionWithUserData:(NSManagedObject *)userObject;
@end
