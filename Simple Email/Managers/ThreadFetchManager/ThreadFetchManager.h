//
//  ThreadFetchManager.h
//  SimpleEmail
//
//  Created by Zahid on 04/10/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@class FavoriteEmailSyncManager;
@class SnoozeEmailSyncManager;
@interface ThreadFetchManager : NSObject
-(id)initWithUserId:(NSString *)uid snoozeSync:(SnoozeEmailSyncManager *)snoozeSync favoriteSync:(FavoriteEmailSyncManager *)favoriteSync;
@property (nonatomic, strong) MCOIMAPSession * imapSession;
@property (nonatomic, strong) NSMutableArray * threadIdArray;
@property (nonatomic, strong) NSString * uid;
@property (assign) BOOL isOperationIdle;
-(void)startOperation;
@end
