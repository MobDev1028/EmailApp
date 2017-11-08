//
//  EmailListenerManager.m
//  SimpleEmail
//
//  Created by Zahid on 08/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "EmailListenerManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "CoreDataManager.h"
#import "InboxManager.h"
#import "LocalNotificationManager.h"
#import "MCOIMAPSessionManager.h"
#import "MailCoreServiceManager.h"
#import "EmailUpdateManager.h"

#define CALL_TIME 2
@implementation EmailListenerManager {
    EmailUpdateManager * updateManager;
    MCOIMAPSessionManager * imapSessionManager;
    LocalNotificationManager * localNotificationManager;
}
//+ (EmailListenerManager*)sharedEmailListenerManager {
//    static EmailListenerManager *sharedEmailListenerManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sharedEmailListenerManager = [[self alloc] init];
//    });
//    return sharedEmailListenerManager;
//}
-(id)init {
    return [self initWithUser:0];
}
-(id)initWithUser:(long)uid {
    self = [super init];
    if (self != nil) {
        self.userId = uid;
        [self startEmailListnerTask];
    }
    return self;
}
#pragma - mark Private Methods
- (void)startEmailListnerTask {
    self.isListenerStopped = NO;
    if (self.imapSession == nil) {
        [self createImapSession];
    }
    else {
        //NSTimer *fiveSecondTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(performBackgroundTask) userInfo:nil repeats:YES];
        [self performBackgroundTask];
    }
}

- (void)performBackgroundTask {
    if (self.isListenerStopped) {
        return;
    }
    
    if ([Utilities isInternetActive] == NO) {
        return;
    }
    MCOIMAPMessagesRequestKind requestKind = [Utilities getImapRequestKind];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate * date = nil;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:self.userId];
        NSManagedObject * object = [userArray lastObject];
        if (object != nil) {
            date = [object valueForKey:kLATEST_EMAIL_DATE];
        }
        /*NSLog(@"EmailListenerManager date = %@, FOR USER: %@", date,[object valueForKey:kUSER_EMAIL]);*/
        if (date != nil) {
            self.isListening = YES;
            
            if (self.isListenerStopped) {
                return;
            }
            __block MCOIMAPSearchOperation* searchOperation = [self.imapSession searchExpressionOperationWithFolder:kFOLDER_INBOX expression: [MCOIMAPSearchExpression searchSinceReceivedDate:date]];
            
            if (self.isListenerStopped) {
                return;
            }
            
            if ([Utilities isInternetActive] == NO) {
                //[self startNewSession];
                return;
            }
            [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
                if (error == nil) {
                    
                    if (self.isListenerStopped) {
                        return;
                    }
                    MCOIMAPFetchMessagesOperation * mco = [self.imapSession fetchMessagesOperationWithFolder:kFOLDER_INBOX requestKind:requestKind uids:indexSet];
                    if ([Utilities isInternetActive] == NO) {
                        //[self startNewSession];
                        searchOperation = nil;
                        [searchOperation cancel];
                        return;
                    }
                    
                    if (self.isListenerStopped) {
                        return;
                    }
                    
                    [mco start:^(NSError *error, NSArray *fetchedMessages, MCOIndexSet *vanishedMessages) {
                        if (error == nil) {
                            //if (fetchedMessages.count == 0) {
                            [self startNewSession];
                            //}
                            
                            //if unique id exist in db than skip
                            //else
                            //check if its thread exist in db than
                            // get email from this thread with topThreadMail falg flase
                            // make it true
                            // save new email in thread with flag flase
                            
                            //else
                            // just save it master, it is a brand new email
                            
                            self.isNotificationRegister = NO;
                            for (MCOIMAPMessage *message in fetchedMessages) {
                                if (self.isListenerStopped) {
                                    return;
                                }
                                if ([CoreDataManager isUniqueIdExist:[message gmailMessageID] forUserId:self.userId entity:kENTITY_EMAIL]>0) {
                                }
                                else {
                                    
                                    if ([CoreDataManager isThreadIdExist:[message gmailThreadID] forUserId:self.userId forFolder:kFolderAllMail entity:kENTITY_EMAIL]>0) {
                                        NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[message gmailThreadID] andUserId:self.userId isTopEmail:NO isTrash:NO entity:kENTITY_EMAIL];
                                        
                                        int unreadCount = 0;
                                        if ( message.flags == 0 ) {
                                            unreadCount = 1;
                                        }
                                        NSArray * typeArray = [Utilities getMessageTypes:message userId:self.userId currentEmail:self.currentLoginMailAddress];
                                        BOOL isInbox = [[typeArray objectAtIndex:0] boolValue];
                                        BOOL isSent = [[typeArray objectAtIndex:1] boolValue];
                                        BOOL isConvo = [[typeArray objectAtIndex:2] boolValue];
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
                                        
                                        [object setValue:message.header.date forKey:kLATEST_EMAIL_DATE];
                                        [CoreDataManager updateData];
                                        NSString * strUid = [NSString stringWithFormat:@"%ld",self.userId];
                                        [Utilities saveEmailModelForMessage:message unreadCount:unreadCount isThreadEmail:isThreadTop mailFolderName:kFOLDER_INBOX isSent:isSent isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:isConvo isInbox:isInbox userId:strUid isFakeDraft:NO enitity:kENTITY_EMAIL];
                                        
                                        [Utilities markSnoozedAndFavorite:message userId:self.userId isInboxMail:YES];
                                        //MCOAddress * address = message.header.sender;
                                        
                                        /* register notification once */
                                        if (!self.isNotificationRegister) {
                                            self.isNotificationRegister = YES;
                                            if (localNotificationManager == nil) {
                                                //localNotificationManager = [[LocalNotificationManager alloc] init];
                                            }
                                            
                                            /*[localNotificationManager scheduleAlarmForDate:[NSDate date] withBody:[NSString stringWithFormat:@"New Message from: %@",address.mailbox ] isNewEmailNotification:YES forEmailId:@"" andUserId:nil firebaseId:nil onlyIfNoReply:NO];*/
                                        }
                                        
                                        NSLog(@"new thread email recieved");
                                        [self.delegate emailListenerManager:self didReceiveNewEmailWithId:self.userId];
                                        
                                        [self postNotification];
                                    }
                                    else { /* new single email */
                                        NSLog(@"new single email recieved");
                                        [self saveSingleMessage:message isNotificationRegister:self.isNotificationRegister];
                                    }
                                }
                            }
                        }
                        else {
                            if ([Utilities isInternetActive] == YES) {
                                [self startNewSession];
                                searchOperation = nil;
                                [searchOperation cancel];
                                return;
                            }
                        }
                    }];
                    
                    searchOperation = nil;
                    [searchOperation cancel];
                }
                else {
                    if ([Utilities isInternetActive] == YES) {
                        [self startNewSession];
                        searchOperation = nil;
                        [searchOperation cancel];
                        return;
                    }
                }
            }];
        }
        else {
            
            NSMutableArray * emailArray = [CoreDataManager fetchLatestTopEmailForUserId:self.userId];
            NSManagedObject * emailObject = nil;
            if (emailArray.count>0) {
                emailObject = [emailArray objectAtIndex:0];
            }
            if (object != nil && emailObject != nil) {
                NSDate * date = [emailObject valueForKey:kEMAIL_DATE];
                [object setValue:date forKey:kLATEST_EMAIL_DATE];
                [CoreDataManager updateData];
            }
            
            self.isListening = NO;
            [Utilities destroyImapSession:self.imapSession];
            self.imapSession = nil;
            [self.imapSession cancelAllOperations];
            [self createImapSession];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });
}
-(void)fetchSentMails {
    
    if (updateManager == nil) {
        updateManager = [[EmailUpdateManager alloc] init];
        
        updateManager.folderName = kFOLDER_SENT_MAILS;
        updateManager.currentLoginMailAddress = self.currentLoginMailAddress;
        updateManager.delegate = self;
        [updateManager createUpdateSessionWithId:[NSString stringWithFormat:@"%ld",self.userId]];
    }
}

-(void)saveSingleMessage:(MCOIMAPMessage *)message isNotificationRegister:(BOOL)isNotificationRegister {
    if (self.isListenerStopped) {
        return;
    }
    int unreadCount = 0;
    if ( message.flags == 0 ) {
        unreadCount = 1;
    }
    //MCOAddress * address = message.header.sender;
    if (!isNotificationRegister) {
        isNotificationRegister = YES;
        if (localNotificationManager == nil) {
            //localNotificationManager = [[LocalNotificationManager alloc] init];
        }
        /*[localNotificationManager scheduleAlarmForDate:[NSDate date] withBody:[NSString stringWithFormat:@"New Message from: %@",address.mailbox ] isNewEmailNotification:YES forEmailId:@"" andUserId:nil firebaseId:nil onlyIfNoReply:NO];*/
    }
    if (self.isListenerStopped) {
        return;
    }
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:self.userId];
    NSManagedObject * object = [userArray lastObject];
    if (object != nil) {
        [object setValue:message.header.date forKey:kLATEST_EMAIL_DATE];
        [CoreDataManager updateData];
    }
    NSString * strUid = [NSString stringWithFormat:@"%ld",self.userId];
    [Utilities saveEmailModelForMessage:message unreadCount:unreadCount isThreadEmail:NO mailFolderName:kFOLDER_INBOX isSent:NO isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:NO isInbox:YES userId:strUid isFakeDraft:NO enitity:kENTITY_EMAIL];
    
    [Utilities markSnoozedAndFavorite:message userId:self.userId isInboxMail:YES];
    [self.delegate emailListenerManager:self didReceiveNewEmailWithId:self.userId];
    [self postNotification];
}

-(void)postNotification {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[Utilities getStringFromLong:self.userId] forKey:kUSER_ID];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_NEW_EMAIL object:nil userInfo:userInfo];
}
-(void)createImapSession {
    if (imapSessionManager == nil) {
        imapSessionManager = [[MCOIMAPSessionManager alloc] init];
    }
    imapSessionManager.delegate = self;
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:self.userId];
    NSManagedObject * object = [userArray lastObject];
    
    [imapSessionManager createImapSessionWithUserData:object];
}

-(void)startNewSession {
    if (self.isListenerStopped) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [Utilities destroyImapSession:self.imapSession];
    self.imapSession = nil;
    [self.imapSession cancelAllOperations];
    [self performSelector:@selector(createImapSession) withObject:nil afterDelay:CALL_TIME];
}

-(void)stopListner {
    /* this code will stop listner */
    self.isListenerStopped = YES;
    self.isListening = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [Utilities destroyImapSession:self.imapSession];
    self.imapSession = nil;
    [self.imapSession cancelAllOperations];
}

#pragma - mark MCOIMAPSessionManagerDelegate
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    [self startEmailListnerTask];
}

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    //[self startNewSession];
}

#pragma mark - EmailUpdateManagerDelegate
- (void)emailUpdateManager:(EmailUpdateManager*)manager didReceiveNewEmailWithId:(long)userId {
    updateManager.delegate = nil;
    updateManager = nil;
    [self.delegate emailListenerManager:self didReceiveNewEmailWithId:self.userId];
}

-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
    updateManager.delegate = nil;
    updateManager = nil;
    NSLog(@"dealloc - EmailListenerManager");
}

@end
