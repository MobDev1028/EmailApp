//
//  ThreadFetchManager.m
//  SimpleEmail
//
//  Created by Zahid on 04/10/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ThreadFetchManager.h"
#import "MCOIMAPSessionManager.h"
#import "Utilities.h"
#import "Constants.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"

@implementation ThreadFetchManager {
    FavoriteEmailSyncManager * favoriteEmailSyncManager;
    SnoozeEmailSyncManager *  snoozeEmailSyncManager;
    NSMutableDictionary * dataDictionary;
    MCOIMAPSessionManager * imapSessionManager;
}
-(id)init {
    return [self initWithUserId:nil snoozeSync:nil favoriteSync:nil];
}

-(id)initWithUserId:(NSString *)uid snoozeSync:(SnoozeEmailSyncManager *)snoozeSync favoriteSync:(FavoriteEmailSyncManager *)favoriteSync {
    self = [super init];
    if (self != nil) {
        self.uid = uid;
        if (self.threadIdArray == nil) {
            self.threadIdArray = [[NSMutableArray alloc] init];
        }
        self.isOperationIdle = NO;
        imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        imapSessionManager.strongDelegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[uid longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        [imapSessionManager createImapSessionWithUserData:object];
        favoriteEmailSyncManager = favoriteSync;
        snoozeEmailSyncManager = snoozeSync;
    }
    return self;
}
-(void)startOperation {
    if (!self.isOperationIdle) {
        return;
    }
    [self startFetching];
}
-(void)startFetching {
    NSString * folderName = nil;
    NSString * threadId = nil;
    NSString * email = nil;
    
    
    if (self.threadIdArray.count>0) {
        dataDictionary = [self.threadIdArray lastObject];
        folderName = kFOLDER_ALL_MAILS;//[dictionary objectForKey:kMAIL_FOLDER];
        threadId = [dataDictionary objectForKey:kEMAIL_THREAD_ID];
        email = [dataDictionary objectForKey:kUSER_EMAIL];
    }
    else {
        self.isOperationIdle = YES;
        return;
    }
    
    MCOIMAPSearchOperation* searchOperation = [self.imapSession searchExpressionOperationWithFolder:folderName expression: [MCOIMAPSearchExpression searchGmailThreadID:[threadId longLongValue]]];
    
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        if (error == nil) {
            if (indexSet.count>0) { /* it is thread*/
                [self fetchThreadForMailThreadId:[threadId longLongValue] withRequestKind:[Utilities getImapRequestKind] message:nil index:0 uids:indexSet email:email];
            }
        }
        else {
            NSLog(@"error = %@", error.localizedDescription);
        }
    }];
}

-(void)fetchThreadForMailThreadId:(uint64_t)threadId withRequestKind:(MCOIMAPMessagesRequestKind)request message:(MCOIMAPMessage *)message index:(int)startIndex uids:(MCOIndexSet*)uids email:(NSString *)email {
    
    [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:uids fromFolder:kFOLDER_ALL_MAILS withSessaion:self.imapSession requestKind:request completionBlock:^(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages) {
        if (error == nil) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:YES];
            
            NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:threadMessages];
            NSArray * sortMessages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
            
            BOOL isConversationFlag = [Utilities isThreadContainConversation:sortMessages forCurrentLoginMail:email];
            
            for (int i = 0; i <sortMessages.count ; ++i) {
                MCOIMAPMessage* threadMessage = [sortMessages objectAtIndex:i];
                
                long unreadCount = 0;
                if ( threadMessage.flags == 0 ) {/* unread flag check*/
                    unreadCount = 1;
                }
                BOOL isSentFlag = NO;
                BOOL isInboxFlag = NO;
                
                //if (self.folderType == kFolderAllMail || self.folderType == kFolderInboxMail || self.folderType == kFolderSentMail) {
                /* this check is for making a combined conversation copy
                 for inbox as well as sent box */
                NSString * senderMail = threadMessage.header.sender.mailbox;
                if ([senderMail isEqualToString:email]) {
                    /* this email in conversation is from sent box because
                     sender email is equal to current login email */
                    
                    isSentFlag = YES;
                }
                else {
                    isInboxFlag = YES;
                }
                // }
                if (i == sortMessages.count-1) {
                    /* save latest message in thread with no flag */
                    [Utilities saveEmailModelForMessage:threadMessage unreadCount:unreadCount isThreadEmail:NO mailFolderName:kFOLDER_ALL_MAILS isSent:isSentFlag isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:YES isConversation:isConversationFlag isInbox:isInboxFlag userId:self.uid isFakeDraft:NO enitity:kENTITY_EMAIL];
                }
                else {
                    [Utilities saveEmailModelForMessage:threadMessage unreadCount:unreadCount isThreadEmail:YES mailFolderName:kFOLDER_ALL_MAILS isSent:isSentFlag isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:YES isConversation:isConversationFlag isInbox:isInboxFlag userId:self.uid isFakeDraft:NO enitity:kENTITY_EMAIL];
                }
                
            }
        }
        if (snoozeEmailSyncManager != nil) {
            [snoozeEmailSyncManager changeSnoozeDatabaseWithDictionary:dataDictionary saveType:[[dataDictionary objectForKey:@"saveType"] intValue]];
        }
        else if (favoriteEmailSyncManager != nil) {
            [favoriteEmailSyncManager changeFavoriteDatabaseWithDictionary:dataDictionary mark:[[dataDictionary objectForKey:@"mark"] boolValue]];
        }
        [self.threadIdArray removeLastObject];
        
        imapSessionManager.strongDelegate = nil;
        imapSessionManager = nil;
        
    }onError:^(NSError* error) {
        
    }];
}

-(void)postNotificationForFavorite {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_FAVORITE object:nil];
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedWithObject:(MCOIMAPSession *)imapSession {
    self.isOperationIdle = NO;
    self.imapSession = imapSession;
    [self startFetching];
}

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
}

-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    NSLog(@"ThreadFetchManager - dealloc");
}
@end
