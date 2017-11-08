//
//  UnreadFetchManager.m
//  SimpleEmail
//
//  Created by Zahid on 01/12/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "UnreadFetchManager.h"
#import "MCOIMAPSessionManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "MailCoreServiceManager.h"
#import "SharedInstanceManager.h"
#import "CoreDataManager.h"

@implementation UnreadFetchManager {
    MCOIMAPSessionManager * imapSessionManager;
    int messageFetchedInTotal;
}
- (id) init {
    self = [super init];
    if (self != nil) {
    }
    return self;
}
-(void)fetchAllUnread {
    __weak UnreadFetchManager *weakSelf = self;
    
    [[MailCoreServiceManager sharedMailCoreServiceManager] searchUnreadMessages:kFOLDER_INBOX withSessaion:self.imapSession completionBlock:^(NSError * error, MCOIndexSet * indexSet)  {
        if (error == nil) {
            NSLog(@"indexSet = %@",indexSet.description);
            //[indexSet enumerateIndexes:^(uint64_t ids) {
            //NSLog(@"ids = %llu", ids);
            //}];
            
            [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:indexSet fromFolder:kFOLDER_INBOX withSessaion:self.imapSession requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError * error, NSArray * messagesArray, MCOIndexSet * vanishedIndexes) {
                if (error == nil) {
                    
                    UnreadFetchManager *strongSelf = weakSelf;
                    
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                    strongSelf.messages = nil;
                    NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messagesArray];
                    [combinedMessages addObjectsFromArray:strongSelf.messages];
                    
                    strongSelf.messages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    [self.delegate unreadFetchManager:self unreadCountForUser:[self.user integerValue] unreadCount:indexSet.count];
                    [self fetchMoreEmails];
                }
            } onError:^(NSError * error) {
            }];
        }
    }];
}

-(void)fetchMessageForIndex:(int)startIndex {
    MCOIMAPMessagesRequestKind request = [Utilities getImapRequestKind];
    
    if (self.folderType == kFolderInboxMail) {
        /* change folder type because thread can only
         be fetched from [Gmail]/All Mail */
        self.strFolderName = kFOLDER_ALL_MAILS;
    }
    if (startIndex<self.messages.count) {
        
        MCOIMAPMessage *message = self.messages[startIndex];
        
        uint64_t threadId = message.gmailThreadID;
        NSInteger threadCountIndb = [CoreDataManager isThreadIdExist:threadId forUserId:[self.user longLongValue] forFolder:self.folderType entity:kENTITY_EMAIL];
        if (threadCountIndb<1) { // if thread_id is not in db, execute code,
            MCOIMAPSearchOperation* searchOperation = [self.imapSession searchExpressionOperationWithFolder:self.strFolderName expression: [MCOIMAPSearchExpression searchGmailThreadID:threadId]];
            
            [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
                if (error == nil) {
                    /* save email info in Core Data */
                    BOOL isInfoExist = [CoreDataManager isEmailInfoExist:[self.user longLongValue] emailUid:message.gmailMessageID];
                    if (!isInfoExist) {
                        [self saveEmailInfo:message];
                    }
                    
                    if (indexSet.count>1) { // it is thread
                        [self fetchThreadForThreadId:threadId withRequestKind:request message:message index:startIndex uids:indexSet];
                    }
                    else { // single email
                        if ([CoreDataManager isUniqueIdExist:message.gmailMessageID forUserId:[self.user longLongValue] entity:kENTITY_EMAIL]>0) {
                        }
                        else {
                            long unreadCount = 0;
                            if (message.flags == 0) {
                                unreadCount = 1;
                            }
                            
                            if (self.folderType == kFolderInboxMail) {
                                self.strFolderName = kFOLDER_INBOX;
                            }
                            BOOL isSent = NO;
                            BOOL isInbox = NO;
                            
                            if (self.folderType == kFolderSentMail) {
                                isSent = YES;
                            }
                            else if (self.folderType == kFolderAllMail || self.folderType == kFolderInboxMail) {
                                isInbox = YES;
                            }
                            [self saveEmailWithUnreadCount:unreadCount andMessage:message isThreadTopEmail:NO isConversation:NO isSent:isSent isInboxMail:isInbox];
                            
                            messageFetchedInTotal++;
                        }
                        [self fetchMoreEmails];
                    }
                }
                else {
                    [self fetchMoreEmails];
                }
            }];
        }
        else {
            [self fetchMoreEmails];
        }
    }
}

-(void)fetchThreadForThreadId:(uint64_t)threadId withRequestKind:(MCOIMAPMessagesRequestKind)request message:(MCOIMAPMessage *)message index:(int)startIndex uids:(MCOIndexSet*)uids {
    self.strFolderName = kFOLDER_ALL_MAILS;
    [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:uids fromFolder:self.strFolderName withSessaion:self.imapSession requestKind:request completionBlock:^(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages) {
        
        if (error == nil) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:YES];
            
            NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:threadMessages];
            NSArray * sortMessages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
            
            BOOL isConversationFlag = [Utilities isThreadContainConversation:sortMessages forCurrentLoginMail:self.currentLoginMailAddress];
            BOOL isMessageSaved = NO;
            for (int i = 0; i <sortMessages.count ; ++i) {
                MCOIMAPMessage* threadMessage = [sortMessages objectAtIndex:i];
                
                long unreadCount = 0;
                if ( threadMessage.flags == 0 ) {/* unread flag check*/
                    unreadCount = 1;
                }
                BOOL isSentFlag = NO;
                BOOL isInboxFlag = NO;
                
                if (self.folderType == kFolderAllMail || self.folderType == kFolderInboxMail || self.folderType == kFolderSentMail) {
                    /* this check is for making a combined conversation copy
                     for inbox as well as sent box */
                    NSString * senderMail = threadMessage.header.sender.mailbox;
                    if ([senderMail isEqualToString:self.currentLoginMailAddress]) {
                        /* this email in conversation is from sent box because
                         sender email is equal to current login email */
                        isSentFlag = YES;
                    }
                    else {
                        /* save email info in Core Data */
                        BOOL isInfoExist = [CoreDataManager isEmailInfoExist:[self.user longLongValue] emailUid:threadMessage.gmailMessageID];
                        /* fetch email from server with Inbox
                         Folder and save it locally */
                        if (!isInfoExist) {
                            [self fetchInboxEmailForId:threadMessage.gmailMessageID];
                        }
                        isInboxFlag = YES;
                    }
                }
                
                if (i == sortMessages.count-1) {
                    isMessageSaved = YES;
                    /* save latest message in thread with no flag */
                    [self saveEmailWithUnreadCount:unreadCount andMessage:threadMessage isThreadTopEmail:NO isConversation:isConversationFlag isSent:isSentFlag isInboxMail:isInboxFlag];
                }
                else {
                    isMessageSaved = YES;
                    [self saveEmailWithUnreadCount:unreadCount andMessage:threadMessage isThreadTopEmail:YES isConversation:isConversationFlag isSent:isSentFlag isInboxMail:isInboxFlag];
                }
            }
            if (isMessageSaved) {
                messageFetchedInTotal++;
            }
        }
        [self fetchMoreEmails];
    }onError:^(NSError* error) {
    }];
}

-(ModelEmail *)saveEmailWithUnreadCount:(long)count andMessage:(MCOIMAPMessage *)message isThreadTopEmail:(BOOL)isThreadTop isConversation:(BOOL)conversation isSent:(BOOL)sent isInboxMail:(BOOL)isInbox {
    BOOL isTrashMail = NO;
    
    BOOL isDraftMail = NO;
    BOOL isArchiveMail = NO;

    return [Utilities saveEmailModelForMessage:message unreadCount:count isThreadEmail:isThreadTop mailFolderName:self.strFolderName isSent:sent isTrash:isTrashMail isArchive:isArchiveMail isDarft:isDraftMail draftFetchedFromServer:YES isConversation:conversation isInbox:isInbox userId:self.user isFakeDraft:NO enitity:kENTITY_EMAIL];
}
-(void)saveEmailInfo:(MCOIMAPMessage *)message {
    ModelEmailInfo * info = [[ModelEmailInfo alloc] initWithMessage:message userId:self.user folderName:kFOLDER_INBOX];
    [CoreDataManager mapEmailInfo:info];
}
-(void)fetchInboxEmailForId:(uint64_t)mId {
    [Utilities fetchEmailForUniqueId:mId session:self.imapSession userId:self.user markArchive:NO threadId:0 entity:kENTITY_EMAIL];
}

- (void)createSessionForUser:(NSString *)userId {
    self.isFetchCallMade = NO;
    self.fetchLimit = 10;
    messageFetchedInTotal = 0;
    self.lastLoopItrate = 0;
    self.user = userId;
    if (imapSessionManager == nil) {
        imapSessionManager = [[MCOIMAPSessionManager alloc] init];
    }
    imapSessionManager.delegate = self;
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.user longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    [imapSessionManager createImapSessionWithUserData:object];
}
- (void)fetchMoreEmails {
    if (self.imapSession == nil || self.messages == nil || self.messages.count == 0) {
        self.isFetchCallMade = NO;
        messageFetchedInTotal = 0;
        [self.delegate unreadFetchManager:self noEmailsToFetchForId:[self.user longLongValue]];
        return;
    }
    if (self.messages.count-1 == self.lastLoopItrate) { /* all unread emails fetched */
        messageFetchedInTotal = 0;
        if (self.isFetchCallMade == NO) { /* this means no email fetched in this call, no need tp update tableview */
            [self.delegate unreadFetchManager:self noEmailsToFetchForId:[self.user longLongValue]];
            return;
        }
        [self.delegate unreadFetchManager:self didReceiveEmails:nil userId:self.user];
        self.isFetchCallMade = NO;
        return;
    }
    MCOIMAPMessage * msg = [self.messages objectAtIndex:self.lastLoopItrate];
    uint64_t gmailMessageId = msg.gmailMessageID;
    if (self.messages.count<self.fetchLimit) { /* emails from server is less then our fixed limit */
        self.fetchLimit = (int)self.messages.count;
    }
    if (self.fetchLimit == messageFetchedInTotal) { /* we reached our fetch limit */
        messageFetchedInTotal = 0;
        [self.delegate unreadFetchManager:self didReceiveEmails:nil userId:self.user];
        self.isFetchCallMade = NO;
        return;
    }
    self.isFetchCallMade = YES;
    long count = [CoreDataManager isGmailMessageIdExist:gmailMessageId forUserId:[self.user longLongValue]];
    if (count<=0) { /* gmail message id does not exist locally */
        [self fetchMessageForIndex:self.lastLoopItrate];
        self.lastLoopItrate++;
    }
    else {
        self.lastLoopItrate++;
        [self fetchMoreEmails];
    }
}
-(void)errorOcurred:(NSError *)error {
    self.isFetchCallMade = NO;
    [self.delegate unreadFetchManager:self didReceiveError:error];
}
#pragma - mark MCOIMAPSessionManagerDelegate
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)impSession {
    NSLog(@"SESSION CCREATED:");
    self.imapSession = impSession;
    [self fetchAllUnread];
    manager.delegate = nil;
}

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    manager.delegate = nil;
}
-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
    NSLog(@"DEALLOC : UnreadFetchManager");
}
@end
