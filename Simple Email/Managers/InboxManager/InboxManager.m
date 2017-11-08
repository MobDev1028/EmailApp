//
//  InboxManager.m
//  SimpleEmail
//
//  Created by Zahid on 02/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "InboxManager.h"

#import "Utilities.h"
#import "Constants.h"
#import "ModelUser.h"
#import "ModelEmail.h"
#import "CoreDataManager.h"
#import "MCOIMAPSessionManager.h"
#import "MailCoreServiceManager.h"
#import "ModelEmailInfo.h"


@implementation InboxManager {
    MCOIMAPSessionManager * imapSessionManager;
    int totalMessages;
    int fetchedCount;
    MCOIndexSet * searchIndexSet;
}

-(void)startFetchingMessagesForFolder:(NSString *)folderName andType:(int)type {
    self.strFolderName = folderName;
    self.folderType = type;
    
    if (self.imapSession == nil) {
        // create Session
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.delegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        [imapSessionManager createImapSessionWithUserData:object];
    }
    else {
        self.messages = nil;
        self.totalNumberOfInboxMessages = -1;
        self.isLoading = NO;
        //__block  MCOIMAPOperation *noopOperation = [self.imapSession noopOperation];
        
        //[noopOperation start:^(NSError *error) {
        //  if (error == nil) {
        //      [self loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        
        self.imapCheckOp = [self.imapSession checkAccountOperation];
        [self.imapCheckOp start:^(NSError *error) {
            if (error == nil) {
                if (self.fetchMessages) {
                    if (self.isSearchingExpression) {
                    }
                    else {
                        [self loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
                    }
                }
            } else {
                NSLog(@"error loading account: %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate inboxManager:self didReceiveError:error];
                });
            }
            self.imapCheckOp = nil;
        }];
        //}
        //else {
        //     NSLog(@"error loading account: %@", error);
        //     [self.delegate inboxManager:self didReceiveError:error];
        // }
        //   noopOperation = nil;
        //}];
    }
}
-(void)inboxSearchString:(NSString *)str {
    [[MailCoreServiceManager sharedMailCoreServiceManager] searchStringInMessages:self.strFolderName session:self.imapSession string:str completionBlock:^(NSError * error, MCOIndexSet * indexSet) {
        if (error == nil) {
            totalMessages = indexSet.count;
            searchIndexSet = indexSet;
            fetchedCount = 0;
            [self fetchNextModuleOfSearchedEmails];
        }
    }];
}
-(void)fetchNextModuleOfSearchedEmails {
    [self calculateRangesWithTotal:totalMessages nMessages:15 totalMessageIndb:fetchedCount indexSet:searchIndexSet];
}
-(void)calculateRangesWithTotal:(int)total nMessages:(NSUInteger)nMessages totalMessageIndb:(long)totalMessageInDB indexSet:(MCOIndexSet *)indexSet {
    MCOIMAPMessagesRequestKind requestKind = [Utilities getImapRequestKind];
    if (indexSet == nil) {
        //NSLog(@"total = %d", info.messageCount);
        //BOOL totalNumberOfMessagesDidChange = self.totalNumberOfInboxMessages != [info messageCount];
        self.totalNumberOfInboxMessages = total;
        //NSUInteger numberOfMessagesToLoad = MIN(self.totalNumberOfInboxMessages, nMessages);
        long numberOfMessagesToLoad = totalMessageInDB + nMessages;
        //NSLog(@"self.totalNumberOfMessagesInDB + nMessages = %lu",(unsigned long)numberOfMessagesToLoad);
        if (numberOfMessagesToLoad > self.totalNumberOfInboxMessages) {
            numberOfMessagesToLoad = self.totalNumberOfInboxMessages - totalMessageInDB;
        }
        else {
            numberOfMessagesToLoad = nMessages;
        }
        //  NSLog(@"number of message to load = %lu", (unsigned long)numberOfMessagesToLoad);
        if (numberOfMessagesToLoad < 1)
        {
            ///   NSLog(@"All messages are already loaded");
            self.isLoading = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate inboxManager:self noEmailsToFetchForId:0];
            });
            return;
        }
        
        MCORange fetchRange;
        
        // If total number of messages did not change since last fetch,
        // assume nothing was deleted since our last fetch and just
        // fetch what we don't have
        // if (!totalNumberOfMessagesDidChange && self.messages.count)
        if (totalMessageInDB>0) {
            //numberOfMessagesToLoad -= self.messages.count;
            
            fetchRange = MCORangeMake(self.totalNumberOfInboxMessages -
                                      totalMessageInDB -
                                      (numberOfMessagesToLoad - 1),
                                      (numberOfMessagesToLoad - 1));
        }
        
        // Else just fetch the last N messages
        else {
            fetchRange =
            MCORangeMake(self.totalNumberOfInboxMessages -
                         (numberOfMessagesToLoad - 1),
                         (numberOfMessagesToLoad - 1));
        }
        indexSet = [MCOIndexSet indexSetWithRange:fetchRange];
    }
    else {
        /* Calculate INDEX SET */
        MCOIndexSet * newIndexSet = [[MCOIndexSet alloc] init];
        __block int indexCount = 0;
        if (total>nMessages) {
            [indexSet enumerateIndexes:^(uint64_t index) {
                indexCount++;
                if (indexCount>=totalMessageInDB && newIndexSet.count<nMessages) {
                    [newIndexSet addIndex:index];
                }
            }];
            indexSet = nil;
            indexSet = newIndexSet;
        }
    }
    NSLog(@"index: %@",indexSet.description);
    self.imapMessagesFetchOp = [self.imapSession fetchMessagesByNumberOperationWithFolder:self.strFolderName
                                                                              requestKind:requestKind
                                                                                  numbers:
                                indexSet];

    __weak InboxManager *weakSelf = self;
    [self.imapMessagesFetchOp start:
     ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
         NSLog(@"message found: %lu",(unsigned long)messages.count);
         if (error == nil) {
             InboxManager *strongSelf = weakSelf;
             self.isLoading = NO;
             
             NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
             strongSelf.messages = nil;
             NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
             [combinedMessages addObjectsFromArray:strongSelf.messages];
             strongSelf.messages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
             self.isCountUpdated = NO;
             [self makeThreadForMessageIndex:0 withRequestKind:requestKind];
         }
         else {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.delegate inboxManager:self didReceiveError:error];
             });
         }
     }];
}
- (void)loadLastNMessages:(NSUInteger)nMessages {
    self.stopSaving = NO;
    if (self.parsedMessages == nil) {
        self.parsedMessages = [[NSMutableArray alloc] init];
    }
    else {
        [self.parsedMessages removeAllObjects];
    }
    
    if (self.imapSession == nil) {
        [self startFetchingMessagesForFolder:self.strFolderName andType:self.folderType];
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.isLoading = YES;
            
            MCOIMAPFolderInfoOperation *folderInfo = [self.imapSession folderInfoOperation:self.strFolderName];
            
            [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info)
             {
                 if (error == nil) {
                     [self calculateRangesWithTotal:[info messageCount] nMessages:nMessages totalMessageIndb:self.totalNumberOfMessagesInDB indexSet:nil];
                     /*//NSLog(@"total = %d", info.messageCount);
                      //BOOL totalNumberOfMessagesDidChange = self.totalNumberOfInboxMessages != [info messageCount];
                      self.totalNumberOfInboxMessages = [info messageCount];
                      //NSUInteger numberOfMessagesToLoad = MIN(self.totalNumberOfInboxMessages, nMessages);
                      long numberOfMessagesToLoad = self.totalNumberOfMessagesInDB + nMessages;
                      //NSLog(@"self.totalNumberOfMessagesInDB + nMessages = %lu",(unsigned long)numberOfMessagesToLoad);
                      if (numberOfMessagesToLoad > self.totalNumberOfInboxMessages) {
                      numberOfMessagesToLoad = self.totalNumberOfInboxMessages - self.totalNumberOfMessagesInDB;
                      }
                      else {
                      numberOfMessagesToLoad = nMessages;
                      }
                      //  NSLog(@"number of message to load = %lu", (unsigned long)numberOfMessagesToLoad);
                      if (numberOfMessagesToLoad < 1)
                      {
                      ///   NSLog(@"All messages are already loaded");
                      self.isLoading = NO;
                      dispatch_async(dispatch_get_main_queue(), ^{
                      [self.delegate inboxManager:self noEmailsToFetchForId:0];
                      });
                      return;
                      }
                      
                      MCORange fetchRange;
                      
                      // If total number of messages did not change since last fetch,
                      // assume nothing was deleted since our last fetch and just
                      // fetch what we don't have
                      // if (!totalNumberOfMessagesDidChange && self.messages.count)
                      if (self.totalNumberOfMessagesInDB>0) {
                      //numberOfMessagesToLoad -= self.messages.count;
                      
                      fetchRange = MCORangeMake(self.totalNumberOfInboxMessages -
                      self.totalNumberOfMessagesInDB -
                      (numberOfMessagesToLoad - 1),
                      (numberOfMessagesToLoad - 1));
                      }
                      
                      // Else just fetch the last N messages
                      else {
                      fetchRange =
                      MCORangeMake(self.totalNumberOfInboxMessages -
                      (numberOfMessagesToLoad - 1),
                      (numberOfMessagesToLoad - 1));
                      }
                      
                      //NSLog(@"fetchRange: length = %llu, location = %llu, ", fetchRange.length, fetchRange.location);
                      self.imapMessagesFetchOp = [self.imapSession fetchMessagesByNumberOperationWithFolder:self.strFolderName
                      requestKind:requestKind
                      numbers:
                      [MCOIndexSet indexSetWithRange:fetchRange]];
                      //[self.imapMessagesFetchOp setProgress:^(unsigned int progress) {
                      //NSLog(@"Progress: %u of %lu", progress, (unsigned long)numberOfMessagesToLoad);
                      //}];
                      __weak InboxManager *weakSelf = self;
                      [self.imapMessagesFetchOp start:
                      ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                      
                      if (error == nil) {
                      InboxManager *strongSelf = weakSelf;
                      self.isLoading = NO;
                      
                      NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                      strongSelf.messages = nil;
                      NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                      [combinedMessages addObjectsFromArray:strongSelf.messages];
                      
                      strongSelf.messages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                      self.isCountUpdated = NO;
                      //
                      //  for (int i = 0; i< strongSelf.messages.count; ++i) {
                      //                                  MCOIMAPMessage * msg = [strongSelf.messages objectAtIndex:i];
                      //                                  NSLog(@"subject = %@",msg.header.subject);
                      //                              }
                      [self makeThreadForMessageIndex:0 withRequestKind:requestKind];
                      }
                      else {
                      dispatch_async(dispatch_get_main_queue(), ^{
                      [self.delegate inboxManager:self didReceiveError:error];
                      });
                      }
                      }];*/
                 }
                 else {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.delegate inboxManager:self didReceiveError:error];
                     });
                 }
             }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //Update UI
            });
        });
    }
}

-(void)makeThreadForMessageIndex:(int)startIndex withRequestKind:(MCOIMAPMessagesRequestKind)request {
    
    if (self.folderType == kFolderInboxMail || self.folderType == kFolderSentMail) {
        /* change folder type because thread can only
         be fetched from [Gmail]/All Mail */
        self.strFolderName = kFOLDER_ALL_MAILS;
    }
    if (startIndex<self.messages.count) {
        
        MCOIMAPMessage *message = self.messages[startIndex];
        if (self.folderType == kFolderArchiveMail) {
            if (message.flags == MCOMessageFlagDeleted) {
                // NSLog(@"archived: message header = %@", message.header.subject);
            }
            else {
                [self makeThreadForMessageIndex:startIndex+1 withRequestKind:request];
                return;
            }
        }
        uint64_t threadId = message.gmailThreadID;
        //NSLog(@"single message thread = %llu",threadId);
        NSInteger threadCountIndb = [CoreDataManager isThreadIdExist:threadId forUserId:[self.userId longLongValue] forFolder:self.folderType entity:self.entityName];
        /*/NSLog(@"****************** start *********************");
         NSLog(@"single message thread");
         NSLog(@"thread id = %llu",threadId);
         NSLog(@"subject = %@",message.header.subject);
         NSLog(@"count in db = %ld",(long)threadCountIndb);
         NSLog(@"gmailMessageID = %ld",(long)message.gmailMessageID);
         NSLog(@"MessageuID = %ld",(long)message.uid);
         NSLog(@"******************** end *******************");*/
        if (threadCountIndb<1) { // if thread_id is not in db, execute code,
            MCOIMAPSearchOperation* searchOperation = [self.imapSession searchExpressionOperationWithFolder:self.strFolderName expression: [MCOIMAPSearchExpression searchGmailThreadID:threadId]];
            
            [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
                
                if (error == nil) {
                    
                    /* save email info in Core Data */
                    //  BOOL isInfoExist = [CoreDataManager isEmailInfoExist:[self.userId longLongValue] emailUid:message.gmailMessageID];
                    //  if (!isInfoExist) {
                    //      [self saveEmailInfo:message];
                    //  }
                    
                    if (indexSet.count>1) { // it is thread
                        [self fetchThreadForMailThreadId:threadId withRequestKind:request message:message index:startIndex uids:indexSet];
                    }
                    else { // single email
                        if ([CoreDataManager isUniqueIdExist:message.gmailMessageID forUserId:[self.userId longLongValue] entity:self.entityName]>0) {
                        }
                        else {
                            long unreadCount = 0;
                            if (message.flags == 0) {
                                unreadCount = 1;
                            }
                            if (self.folderType == kFolderSentMail) {
                                self.strFolderName = kFOLDER_SENT_MAILS;
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
                            
                        }
                        [self makeThreadForMessageIndex:startIndex+1 withRequestKind:request];
                    }
                }
                else {
                    [self makeThreadForMessageIndex:startIndex+1 withRequestKind:request];
                }
            }];
        }
        else {
            [self makeThreadForMessageIndex:startIndex+1 withRequestKind:request];
        }
    }
    else {
        if (self.isCountUpdated == NO && !self.isSearchingExpression) {
            if (self.folderType == kFolderInboxMail) {
                [Utilities updateInboxLastFetchCount:self.messages.count userId:self.userId];
            }
            else if (self.folderType == kFolderTrashMail) {
                [Utilities updateTrashLastFetchCount:self.messages.count ForUser:self.userId];
            }
            else if (self.folderType == kFolderArchiveMail) {
                [Utilities updateArchiveLastFetchCount:self.messages.count ForUser:self.userId];
            }
            else if (self.folderType == kFolderSentMail) {
                [Utilities updateSentLastFetchCount:self.messages.count forUser:self.userId];
            }
            else if (self.folderType == kFolderDraftMail) {
                [Utilities updateDarftLastFetchCount:self.messages.count ForUser:self.userId];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //Update UI
            //[self updateCoreData];
            [self.delegate inboxManager:self didReceiveEmails:self.messages];
        });
    }
}

-(void)fetchThreadForMailThreadId:(uint64_t)threadId withRequestKind:(MCOIMAPMessagesRequestKind)request message:(MCOIMAPMessage *)message index:(int)startIndex uids:(MCOIndexSet*)uids {
    
    [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:uids fromFolder:self.strFolderName withSessaion:self.imapSession requestKind:request completionBlock:^(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages) {
        
        if (error == nil) {
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:YES];
            
            NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:threadMessages];
            NSArray * sortMessages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
            
            BOOL isConversationFlag = [Utilities isThreadContainConversation:sortMessages forCurrentLoginMail:self.currentLoginMailAddress];
            /*NSLog(@"****************** thread start *********************");*/
            for (int i = 0; i <sortMessages.count ; ++i) {
                MCOIMAPMessage* threadMessage = [sortMessages objectAtIndex:i];
                
                long unreadCount = 0;
                if ( threadMessage.flags == 0 ) {/* unread flag check*/
                    unreadCount = 1;
                }
                BOOL isSentFlag = NO;
                BOOL isInboxFlag = NO;
                
                /*NSLog(@"****************** start *********************");
                 NSLog(@"thread message");
                 NSLog(@"thread id = %llu",threadMessage.gmailThreadID);
                 NSLog(@"subject = %@",threadMessage.header.subject);
                 NSLog(@"gmailMessageID = %ld",(long)threadMessage.gmailMessageID);
                 NSLog(@"MessageuID = %ld",(long)threadMessage.uid);
                 NSLog(@"folder = %@",self.strFolderName);
                 NSLog(@"******************** end *******************");*/
                
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
                        //                        /* save email info in Core Data */
                        //                        BOOL isInfoExist = [CoreDataManager isEmailInfoExist:[self.userId longLongValue] emailUid:threadMessage.gmailMessageID];
                        //                        /* fetch email from server with Inbox
                        //                         Folder and save it locally */
                        //                        if (!isInfoExist) {
                        //                            [self fetchInboxEmailForId:threadMessage.gmailMessageID];
                        //                        }
                        isInboxFlag = YES;
                    }
                }
                
                if (i == sortMessages.count-1) {
                    /* save latest message in thread with no flag */
                    [self saveEmailWithUnreadCount:unreadCount andMessage:threadMessage isThreadTopEmail:NO isConversation:isConversationFlag isSent:isSentFlag isInboxMail:isInboxFlag];
                }
                else {
                   [self saveEmailWithUnreadCount:unreadCount andMessage:threadMessage isThreadTopEmail:YES isConversation:isConversationFlag isSent:isSentFlag isInboxMail:isInboxFlag];
                }
            }
            /*NSLog(@"******************** thread end *******************");*/
        }
        
        //  NSLog(@"********************************** END THREAD MAIL *************************************************");
        [self makeThreadForMessageIndex:startIndex+1 withRequestKind:request];
        
    }onError:^(NSError* error) {
        
    }];
}
-(ModelEmail *)saveEmailWithUnreadCount:(long)count andMessage:(MCOIMAPMessage *)message isThreadTopEmail:(BOOL)isThreadTop isConversation:(BOOL)conversation isSent:(BOOL)sent isInboxMail:(BOOL)isInbox {
    if (self.stopSaving) {
        return nil;
    }
    
    BOOL isTrashMail = NO;
    
    BOOL isDraftMail = NO;
    BOOL isArchiveMail = NO;
    
    if (self.folderType == kFolderAllMail) {
        
    }
    else if (self.folderType == kFolderInboxMail) {
        if (isThreadTop == NO) {
            self.isCountUpdated = YES;
            if (!self.isSearchingExpression) {
                [Utilities updateInboxLastFetchCount:1 userId:self.userId];
            }
            else {
                fetchedCount++;
            }
        }
    }
    else if (self.folderType == kFolderTrashMail) {
        if (isThreadTop == NO) {
            self.isCountUpdated = YES;
            if (!self.isSearchingExpression) {
                [Utilities updateTrashLastFetchCount:1 ForUser:self.userId];
            }
            else {
                fetchedCount++;
            }
        }
        isTrashMail = YES;
    }
    else if (self.folderType == kFolderSentMail) {
        if (isThreadTop == NO) {
            self.isCountUpdated = YES;
            if (!self.isSearchingExpression) {
                [Utilities updateSentLastFetchCount:1 forUser:self.userId];
            }
            else {
                fetchedCount++;
            }
        }
    }
    else if (self.folderType == kFolderDraftMail) {
        self.isCountUpdated = YES;
        isDraftMail = YES;
        if (!self.isSearchingExpression) {
            [Utilities updateDarftLastFetchCount:1 ForUser:self.userId];
        }
        else {
            fetchedCount++;
        }
    }
    else if (self.folderType == kFolderArchiveMail) {
        self.isCountUpdated = YES;
        isArchiveMail = YES;
        if (!self.isSearchingExpression) {
            [Utilities updateArchiveLastFetchCount:1 ForUser:self.userId];
        }
        else {
            fetchedCount++;
        }
    }
    
    NSString * entityName = kENTITY_EMAIL;
    if (self.isSearchingExpression) {
        entityName = kENTITY_SEARCH_EMAIL;
    }
    return [Utilities saveEmailModelForMessage:message unreadCount:count isThreadEmail:isThreadTop mailFolderName:self.strFolderName isSent:sent isTrash:isTrashMail isArchive:isArchiveMail isDarft:isDraftMail draftFetchedFromServer:YES isConversation:conversation isInbox:isInbox userId:self.userId isFakeDraft:NO enitity:entityName];
}

-(void)updateCoreData {
    NSMutableArray * allMessages = [self.parsedMessages copy];
    [self.parsedMessages removeAllObjects];
    NSLog(@"COUNT Start = %lu", (unsigned long)allMessages.count);
    for (int i = 0; i<allMessages.count; ++i) {
        NSMutableArray * array = [allMessages objectAtIndex:i];
        MCOIMAPMessage * message = [array objectAtIndex:0];
        long count = [[array objectAtIndex:1] integerValue];
        BOOL isThreadTop = [[array objectAtIndex:2] boolValue];
        NSString * folderName = [array objectAtIndex:3];
        BOOL sent = [[array objectAtIndex:4] boolValue];
        BOOL isTrashMail = [[array objectAtIndex:5] boolValue];
        BOOL isArchiveMail = [[array objectAtIndex:6] boolValue];
        BOOL isDraftMail = [[array objectAtIndex:7] boolValue];
        BOOL conversation = [[array objectAtIndex:8] boolValue];
        BOOL isInbox = [[array objectAtIndex:9] boolValue];
        [Utilities saveEmailModelForMessage:message unreadCount:count isThreadEmail:isThreadTop mailFolderName:folderName isSent:sent isTrash:isTrashMail isArchive:isArchiveMail isDarft:isDraftMail draftFetchedFromServer:YES isConversation:conversation isInbox:isInbox userId:self.userId isFakeDraft:NO enitity:kENTITY_EMAIL];
    }
    NSLog(@"COUNT END = %lu", (unsigned long)allMessages.count);
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    self.messages = nil;
    self.totalNumberOfInboxMessages = -1;
    self.isLoading = NO;
    //    MCOIMAPOperation *noopOperation = [self.imapSession noopOperation];
    
    //    [noopOperation start:^(NSError *error) {
    //        if (error == nil) {
    //            [self loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
    //        }
    //        else {
    //            NSLog(@"error loading account: %@", error);
    //            [self.delegate inboxManager:self didReceiveError:error];
    //        }}];
    self.imapCheckOp = [self.imapSession checkAccountOperation];
    [self.imapCheckOp start:^(NSError *error) {
        
        if (error == nil) {
            if (self.fetchMessages) {
                if (self.isSearchingExpression) {
                }
                else {
                    [self loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
                }
            }
        } else {
            NSLog(@"error loading account: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate inboxManager:self didReceiveError:error];
            });
        }
        self.imapCheckOp = nil;
    }];
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
}
-(void)saveEmailInfo:(MCOIMAPMessage *)message {
    ModelEmailInfo * info = [[ModelEmailInfo alloc] initWithMessage:message userId:self.userId folderName:kFOLDER_INBOX];
    [CoreDataManager mapEmailInfo:info];
}
-(void)fetchInboxEmailForId:(uint64_t)mId {
    [Utilities fetchEmailForUniqueId:mId session:self.imapSession userId:self.userId markArchive:NO threadId:0 entity:kENTITY_EMAIL];
}
-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
    NSLog(@"dealloc - InboxManager");
}
@end
