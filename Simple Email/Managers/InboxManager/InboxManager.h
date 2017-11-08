//
//  InboxManager.h
//  SimpleEmail
//
//  Created by Zahid on 02/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "FXKeychain.h"
//#import "GTMOAuth2ViewControllerTouch.h"
@class InboxManager;
@protocol InboxManagerDelegate <NSObject>

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails;
- (void)inboxManager:(InboxManager *)manager didReceiveError:(NSError *)error;
- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId;
//- (void) didUpdateAccessTokenWithSession:(MCOIMAPSession *)imapSession;
@end

@interface InboxManager : NSObject
@property (nonatomic, strong) NSArray *messages;
@property (assign, nonatomic) id <InboxManagerDelegate> delegate;
@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;

@property (nonatomic, strong) NSString * strFolderName;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * currentLoginMailAddress;
@property (assign) int folderType;

@property (nonatomic) NSInteger totalNumberOfInboxMessages;
@property (nonatomic) NSInteger totalNumberOfMessagesInDB;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isCountUpdated;
@property (nonatomic) BOOL isFirstLogin;
@property (nonatomic) BOOL stopSaving;
@property (nonatomic) BOOL fetchMessages;
@property (nonatomic, strong) UIActivityIndicatorView *loadMoreActivityView;
@property (nonatomic, strong) MCOIMAPMessageRenderingOperation * messageRenderingOperation;
//- (void)fetchEmailsForKeychainItemName:(NSString *)keychainItemName;
- (void)loadLastNMessages:(NSUInteger)nMessages;
-(void)startFetchingMessagesForFolder:(NSString *)folderName andType:(int)type;
@property (nonatomic, strong) NSMutableArray * parsedMessages;
@property (nonatomic, strong) NSString * entityName;
@property (nonatomic) BOOL isSearchingExpression;
-(void)inboxSearchString:(NSString *)str;
-(void)fetchNextModuleOfSearchedEmails;
@end
