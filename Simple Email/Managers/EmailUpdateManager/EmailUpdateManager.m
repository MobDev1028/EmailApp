//
//  EmailUpdateManager.m
//  SimpleEmail
//
//  Created by Zahid on 09/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "EmailUpdateManager.h"
#import "MCOIMAPSessionManager.h"
#import "Utilities.h"
#import "Constants.h"

@implementation EmailUpdateManager {
    MCOIMAPSessionManager * imapSessionManager;
}

- (id) init {
    self = [super init];
    if (self != nil) {
    }
    return self;
}
-(void)createUpdateSessionWithId:(NSString *)uid {
    self.userId = uid;
    if ([Utilities isValidString:self.userId]) {
        //self.isListening = YES;
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.delegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        [imapSessionManager createImapSessionWithUserData:object];
    }
    else {
        // self.isListening = NO;
    }
}

- (void)performFetchTask {
    
    MCOIMAPMessagesRequestKind requestKind = [Utilities getImapRequestKind];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString * value = nil;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[self.userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        if (object != nil) {
            if ([self.folderName isEqualToString:kFOLDER_DRAFT_MAILS]) {
                value = kLATEST_DRAFT_EMAIL_DATE;
            }
            else if ([self.folderName isEqualToString:kFOLDER_SENT_MAILS]) {
                value = kLATEST_SENT_EMAIL_DATE;
            }
            else {
                value = kLATEST_TRASH_EMAIL_DATE;
            }
            
            self.date = [object valueForKey:value];
        }
        NSLog(@"EmailUpdateManager %@ : date = %@",self.folderName, self.date);
        if (self.date != nil) {
            
            /* serch email since date */
            __block  MCOIMAPSearchOperation* searchOperation = [self.imapSession searchExpressionOperationWithFolder:self.folderName expression: [MCOIMAPSearchExpression searchSinceReceivedDate:self.date]];
            if ([Utilities isInternetActive] == NO) {
                return;
            }
            [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
                
                MCOIMAPFetchMessagesOperation * mco = [self.imapSession fetchMessagesOperationWithFolder:self.folderName requestKind:requestKind uids:indexSet];
                if ([Utilities isInternetActive] == NO) {
                    //searchOperation = nil;
                    //[searchOperation cancel];
                    return;
                }
                /* fetch searched messages */
                [mco start:^(NSError *error, NSArray *fetchedMessages, MCOIndexSet *vanishedMessages) {
                    
                    //if unique id exist in db than skip
                    //else
                    //check if its thread exist in db than
                    // get email from this thread with topThreadMail falg flase
                    // make it true
                    // save new email in thread with flag flase
                    
                    //else
                    // just save it master, it is a brand new email
                    long userId = [self.userId longLongValue];
                    for (MCOIMAPMessage *message in fetchedMessages) {
                        if ([CoreDataManager isUniqueIdExist:[message gmailMessageID] forUserId:userId entity:kENTITY_EMAIL]>0) {
                            /* if it is a trash email than
                             than fetch complete thread
                             and update trash flag to YES */
                            if ([self.folderName isEqualToString:kFOLDER_TRASH_MAILS]) {
                                // NSMutableArray * oldThread = [CoreDataManager fetchEmailsForThreadId:[message gmailThreadID] andUserId:userId folderType:[Utilities getFolderTypeForString:self.folderName] needOnlyIds:NO];
                            }
                        }
                        else {

                            BOOL isSent = NO;
                            BOOL isInbox = NO;
                            BOOL isTrash = NO;
                            BOOL isDraft = NO;
                            BOOL isConvo = NO;
                            
                            if ([CoreDataManager isThreadIdExist:[message gmailThreadID] forUserId:userId forFolder:[Utilities getFolderTypeForString:self.folderName] entity:kENTITY_EMAIL]>0 ) {
                                
                                NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[message gmailThreadID] andUserId:userId isTopEmail:NO isTrash:NO entity:kENTITY_EMAIL];
                                //NSMutableArray * oldThread = [CoreDataManager fetchEmailsForThreadId:[message gmailThreadID] andUserId:userId folderType:[Utilities getFolderTypeForString:self.folderName] needOnlyIds:NO];
                                if ([self.folderName isEqualToString:kFOLDER_DRAFT_MAILS]) {
                                    isDraft = YES;
                                }
                                else {
                                    if ([self.folderName isEqualToString:kFOLDER_TRASH_MAILS]) {
                                        isTrash = YES;
                                    }
                                    
                                    NSArray * typeArray = [Utilities getMessageTypes:message userId:userId currentEmail:self.currentLoginMailAddress];
                                    isInbox = [[typeArray objectAtIndex:0] boolValue];
                                    isSent = [[typeArray objectAtIndex:1] boolValue];
                                    isConvo = [[typeArray objectAtIndex:2] boolValue];
                                    // below code shell be removed if above 4 lines are working fine in testing
                                    /*  BOOL isContainSent = NO;
                                     BOOL isContainInbox = NO;
                                     
                                     if ([message.header.sender.mailbox isEqualToString:self.currentLoginMailAddress]) {
                                     isContainSent = YES;
                                     isSent = YES;
                                     }
                                     else {
                                     isInbox = YES;
                                     isContainInbox = YES;
                                     }
                                     
                                     for (NSManagedObject *object in oldThread) {
                                     
                                     if (!isContainSent || !isContainInbox) { // already convo
                                     if ([[object valueForKey:kIS_CONVERSATION] boolValue]) {
                                     isContainInbox = YES;
                                     isContainSent = YES;
                                     isConvo = YES;
                                     break;
                                     
                                     }
                                     else {
                                     if (isContainInbox) {
                                     if ([[object valueForKey:kIS_SENT_EMAIL] boolValue]) {
                                     isContainSent = YES;
                                     }
                                     }
                                     else if (isContainSent){
                                     if([[object valueForKey:kIS_Inbox_EMAIL] boolValue]) {
                                     isContainInbox = YES;
                                     }
                                     }
                                     }
                                     }
                                     }
                                     
                                     if (isContainInbox && isContainSent) {
                                     isConvo = YES;
                                     }*/
                                }
                                
                                int unreadCount = 0;
                                if ( message.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                
                                BOOL isThreadTop = NO;
                                
                                if (array.count>0) { /* update old top thread */
                                    
                                    NSManagedObject * obj = [array objectAtIndex:0];
                                    BOOL isDate1Later = [Utilities isDate:message.header.date isLatestThanDate:(NSDate *)[obj valueForKey:kEMAIL_DATE]];
                                    if (isDate1Later) {
                                        
                                        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_THREAD_TOP_EMAIL];
                                    }
                                    else {
                                        isThreadTop = YES;
                                    }
                                    
                                    [CoreDataManager updateData];
                                }
                                [object setValue:nil forKey:value];
                                [CoreDataManager updateData];
                                [Utilities saveEmailModelForMessage:message unreadCount:unreadCount isThreadEmail:isThreadTop mailFolderName:self.folderName isSent:isSent isTrash:isTrash isArchive:NO isDarft:isDraft draftFetchedFromServer:YES isConversation:isConvo isInbox:isInbox userId:self.userId isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [self markEmail:message uid:userId];
                                NSLog(@"EmailUpdateManager - new thread email recieved");
                                [self.delegate emailUpdateManager:self didReceiveNewEmailWithId:userId];
                            }
                            else { // new single email
                                
                                int unreadCount = 0;
                                if ( message.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                
                                if ([self.folderName isEqualToString:kFOLDER_DRAFT_MAILS]) {
                                    isDraft = YES;
                                }
                                else if ([self.folderName isEqualToString:kFOLDER_TRASH_MAILS]) {
                                    isTrash = YES;
                                }
                                else if ([self.folderName isEqualToString:kFOLDER_INBOX]) {
                                    isInbox = YES;
                                    
                                }
                                else if ([self.folderName isEqualToString:kFOLDER_SENT_MAILS]) {
                                    
                                    isSent = YES;
                                }
                                [object setValue:nil forKey:value];
                                [CoreDataManager updateData];
                                [Utilities saveEmailModelForMessage:message unreadCount:unreadCount isThreadEmail:NO mailFolderName:self.folderName isSent:isSent isTrash:isTrash isArchive:NO isDarft:isDraft draftFetchedFromServer:YES isConversation:isConvo isInbox:isInbox userId:nil isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [self markEmail:message uid:userId];
                                NSLog(@"EmailUpdateManager - new single email recieved");
                                [self.delegate emailUpdateManager:self didReceiveNewEmailWithId:userId];
                            }
                        }
                    }
                }];
                
                searchOperation = nil;
                [searchOperation cancel];
            }];
        }
        else {
            NSString * values = nil;
            NSMutableArray * emailArray = nil;
            if ([self.folderName isEqualToString:kFOLDER_DRAFT_MAILS]) {
                values = kLATEST_DRAFT_EMAIL_DATE;
                emailArray = [CoreDataManager fetchLatestDraftEmailForUserId:[self.userId longLongValue]];
            }
            else if ([self.folderName isEqualToString:kFOLDER_SENT_MAILS]) {
                emailArray = [CoreDataManager fetchLatestSentEmailForUserId:[self.userId longLongValue]];
                values = kLATEST_SENT_EMAIL_DATE;
            }
            else {
                emailArray = [CoreDataManager fetchLatestTrashEmailForUserId:[self.userId longLongValue]];
                values = kLATEST_TRASH_EMAIL_DATE;
            }
            
            NSManagedObject * emailObject = nil;
            if (emailArray.count>0) {
                emailObject = [emailArray objectAtIndex:0];
            }
            if (object != nil && emailObject != nil) {
                NSDate * date = [emailObject valueForKey:kEMAIL_DATE];
                [object setValue:date forKey:values];
                [CoreDataManager updateData];
                
                [Utilities destroyImapSession:self.imapSession];
                self.imapSession = nil;
                [self.imapSession cancelAllOperations];
                [self createUpdateSessionWithId:self.userId];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });
}
-(void)markEmail:(MCOIMAPMessage *)message uid:(long)userId {
    if ([self.folderName isEqualToString:kFOLDER_INBOX] || [self.folderName isEqualToString:kFOLDER_SENT_MAILS]) {
        [Utilities markSnoozedAndFavorite:message userId:userId isInboxMail:NO];
    }
}

#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    [self performFetchTask];
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    // [self startNewSession];
}

-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
    NSLog(@"dealloc - EmailUpdateManager");
}
@end
