//
//  UnreadFetchManager.h
//  SimpleEmail
//
//  Created by Zahid on 01/12/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@class UnreadFetchManager;
@protocol UnreadFetchManagerDelegate <NSObject>

- (void)unreadFetchManager:(UnreadFetchManager *)manager didReceiveEmails:(NSArray *)emails userId:(NSString *)userId;
- (void)unreadFetchManager:(UnreadFetchManager *)manager didReceiveError:(NSError *)error;
- (void)unreadFetchManager:(UnreadFetchManager *)manager noEmailsToFetchForId:(long)userId;
- (void)unreadFetchManager:(UnreadFetchManager *)manager unreadCountForUser:(long)userId unreadCount:(long)count;
@end

@interface UnreadFetchManager : NSObject
@property (assign, nonatomic) id <UnreadFetchManagerDelegate> delegate;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) MCOIMAPSession * imapSession;
@property (nonatomic, assign) int lastLoopItrate;
@property (nonatomic, strong) NSString * currentLoginMailAddress;
@property (nonatomic, strong) NSString * strFolderName;
@property (nonatomic, strong) NSArray *messages;
@property (assign) int folderType;
@property (assign) int fetchLimit;
@property (nonatomic, assign) BOOL isFetchCallMade;
- (void)createSessionForUser:(NSString *)userId;
- (void)fetchMoreEmails;
- (void)fetchAllUnread;
@end
