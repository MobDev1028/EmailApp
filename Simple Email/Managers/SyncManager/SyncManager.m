//
//  SyncManager.m
//  SimpleEmail
//
//  Created by Zahid on 16/12/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SyncManager.h"
#import "WebServiceManager.h"
#import "Utilities.h"
#import "Constants.h"
#import "CoreDataManager.h"
#import "MailCoreServiceManager.h"
#import "MCOIMAPSessionManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "AppDelegate.h"

@implementation SyncManager {
    NSMutableArray * users;
    MCOIMAPSessionManager * imapSessionManager;
    int responseCount;
    BOOL isErrorOccur;
}
- (id) init {
    self = [super init];
    if (self != nil) {
        self.invalidateTimer = NO;
    }
    return self;
}
-(void)checkForDeleteCall {
    if (responseCount<=0 && !isErrorOccur) {
        [self deleteData:self.dictionaryToDelete folder:self.folder];
    }
    else if (isErrorOccur){
        [self makeFetchCal:self.folder delay:3.0];
    }
}
-(void)syncEmailForFolder:(NSString *)folder {
    //NSLog(@"SYNC CALL for folder: %@", folder);
    self.folder = folder;
    responseCount = 0;
    isErrorOccur = NO;
    NSMutableArray * accountsArray = [[NSMutableArray alloc] init];
    users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * user in users) {
        NSString * email = [user valueForKey:kUSER_EMAIL];
        [accountsArray addObject:email];
    }
    NSString* uniqueIdentifier = [Utilities getDeviceIdentifier]; // IOS 6+
    if (![Utilities isValidString:uniqueIdentifier] || accountsArray.count == 0) { /* call api again after 5 seconds */
        [self makeFetchCal:folder delay:5.0];
        return;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:accountsArray options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:uniqueIdentifier forKey:@"device_udid"];
    [params setObject:kSECRET forKey:@"secret"];
    [params setObject:json forKey:@"user_accounts"];
    [params setObject:folder forKey:@"email_folder"];
    
    [[WebServiceManager sharedServiceManager] sync:params completionBlock:^(id response) {
        id data = [Utilities dataToDictionary:response];
        [self parseData:data params:params folder:folder];
    }onError:^(NSString * errorMessage, int errorCode) {
        [self makeFetchCal:folder delay:5.0];
    }onProgress:^(NSProgress * progress) {
    }];
}

-(void)parseData:(id)data params:(NSMutableDictionary *)params folder:(NSString *)folder {
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSString * requestTime = nil;
        NSDictionary * dictionaryData = (NSDictionary *)data;
        NSString * unreadCount = [dictionaryData valueForKey:@"deviceUnreadCount"];
        dictionaryData = [dictionaryData valueForKey:@"response"];
        requestTime = [dictionaryData valueForKey:@"requestTime"];
        [params setObject:requestTime forKey:@"requestTime"];
        dictionaryData = [dictionaryData valueForKey:@"data"];
        AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate setBadgeCount:[unreadCount integerValue]];
        self.dictionaryToDelete = params;
        for (NSManagedObject * user in users) {
            NSString * email = [user valueForKey:kUSER_EMAIL];
            NSArray * emailData = [dictionaryData objectForKey:email];
            
            for (NSDictionary * dic in emailData) {
                if ([folder isEqualToString:kFOLDER_INBOX] || [folder isEqualToString:@"SENT"]) {
                    NSLog(@"%@",folder);
                    NSLog(@"data : %@",dic);
                    [self syncInbox:dic user:user folder:folder];
                }
                else if ([folder isEqualToString:@"TRASH"]) {
                    NSLog(@"%@",folder);
                    NSLog(@"data : %@",dic);
                    [self syncTrash:dic user:user];
                }
                else if ([folder isEqualToString:@"DRAFT"]) {
                    NSLog(@"%@",folder);
                    NSLog(@"data : %@",dic);
                    [self syncDraft:dic user:user];
                }
                else if ([folder isEqualToString:@"ARCHIVE"]) {
                    NSLog(@"%@",folder);
                    NSLog(@"data : %@",dic);
                    [self syncArchive:dic user:user];
                }
            }
        }
        /*call delete api */
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //            [self deleteData:params folder:folder];
        //NSLog(@"CALL:1 folder = %@", self.folder);
        [self checkForDeleteCall];
        //});
    }
}

-(void)deleteData:(NSMutableDictionary *)dictionary folder:(NSString *)folder {
    if (![Utilities isInternetActive]) {
        return;
    }
    [[WebServiceManager sharedServiceManager] deleteSyncRecord:dictionary completionBlock:^(id response) {
        //id data = [Utilities dataToDictionary:response];
        //NSLog(@"folder = %@", folder);
        //NSLog(@"dictionary = %@", dictionary);
        //NSLog(@"/# POST RESPONSE : %@  /#", data);
        [self makeFetchCal:folder delay:0.5];
    }onError:^(NSString * errorMessgae, int errorCode) {
        [self deleteData:dictionary folder:folder];
    }onProgress:^(NSProgress * progress) {
    }];
}

-(void)makeFetchCal:(NSString *)folder delay:(double)delay {
    if (![Utilities isInternetActive]) {
        delay = 15;
    }
    if (self.invalidateTimer == NO) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self syncEmailForFolder:folder];
        });
    }
}
-(void)deleteAttachament:(long)userId threadId:(uint64_t)threadId {
    NSMutableArray * attachments = [CoreDataManager getAttachment:userId emailUid:threadId entity:kENTITY_ATTACHMENTS];
    for (NSManagedObject *attachment in attachments) {
        NSMutableArray * attachmentPaths = (NSMutableArray *)[Utilities getUnArchivedArrayForObject:[attachment valueForKey:kATTACHMENT_PATHS]];
        [Utilities removeFilesFromPaths:attachmentPaths];
        [CoreDataManager deleteObject:attachment];
    }
}
-(void)syncInbox:(NSDictionary *)daictionary user:(NSManagedObject *)userObject folder:(NSString *)folder {
    //    sync Inbox
    //    /* how delete logic work in INBOX */
    //    check if email id exist in the db with inbox bool
    //    if exist, mark read and unread, or delete according to flag came from server
    //    if exist and delete flag is false then we will check if email folder flag has been changed or not
    //
    
    long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:usrId];
    int isDeleted = [[daictionary objectForKey:@"deleted"] intValue];
    int isRead = [[daictionary objectForKey:@"is_read"] intValue];
    uint64_t threadId = [[daictionary objectForKey:@"thread_id_dec"] longLongValue];
    uint64_t emailId = [[daictionary objectForKey:@"email_id_dec"] longLongValue];
    
    NSMutableArray * email = [CoreDataManager fetchSingleEmailForUniqueIdForInbox:emailId andUserId:usrId];
    if (email.count>0) { /* update flags if unique id exist */
        for (NSManagedObject * object in email) {
            int oldCount = [[object valueForKey:kUNREAD_COUNT] intValue];
            if (oldCount == isRead) {
                if (isRead == 0) {
                    [object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
                }
                else {
                    [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
                }
            }
            if (isDeleted == 1) { /* delete email from Core Data and make new top email */
                long threadCount = [CoreDataManager isThreadExist:threadId forUserId:usrId];
                if (threadCount>0) {
                    if (threadCount == 1) { /* delete from firebase only if single email*/
                        
                        if(![Utilities emailHasBeenSnoozedRecently:object]){
                            [self syncDeleteActionToFirebaseWithObject:object userId:strUserId];
                        }
                    }
                }
                BOOL isTopEmail = [[object valueForKey:kIS_THREAD_TOP_EMAIL] boolValue];
                if (isTopEmail == NO) {
                    NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:threadId andUserId:usrId isTopEmail:YES isTrash:NO entity:[object entity].name];
                    if (array.count>0) {
                        NSManagedObject *obj = [array lastObject];
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_THREAD_TOP_EMAIL];
                    }
                }
                NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
                [self deleteAttachament:usrId threadId:[uniqueId longLongValue]];

                [CoreDataManager deleteObject:object];
            }
            else {
                BOOL fetchEmail = NO;
                /* Here we will check that email has changed folder or not */
                NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
                for (NSManagedObject * obj in inboxEmails) {
                    NSString * existingFolder = [obj valueForKey:kMAIL_FOLDER];
                    BOOL isTrashFlag = [[obj  valueForKey:kIS_TRASH_EMAIL] boolValue];
                    BOOL isArchiveFlag = [[obj  valueForKey:kIS_ARCHIVE] boolValue];
                    if ([existingFolder isEqualToString:kFOLDER_TRASH_MAILS] || isTrashFlag || isArchiveFlag) {
                        [CoreDataManager deleteObject:obj];
                        fetchEmail = YES;
                    }
                }
                if (fetchEmail) {
                    NSLog(@"EMAIL NOT FOUND AND FLAG HAS BEEN CHANGED");
                    NSString * email = [userObject valueForKey:kUSER_EMAIL];
                    NSString * foldr = kFOLDER_INBOX;
                    if ([folder isEqualToString:@"SENT"]) {
                        foldr = kFOLDER_SENT_MAILS;
                    }
                    MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
                    responseCount++;
                    [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:foldr gmailMessageId:emailId folderType:kFolderAllMail];
                }
            }
        }
        
        /* below code is here to notify core data, and it will update row of change data */
        NSMutableArray * completeThread = [CoreDataManager fetchThreadForId:threadId userId:usrId];
        if (completeThread.count>0) {
            for (NSManagedObject * object in completeThread) {
                BOOL update = [[object valueForKey:@"updateData"] boolValue];
                [object setValue:[NSNumber numberWithBool:!update] forKey:@"updateData"];
            }
        }
        [CoreDataManager updateData];
        [Utilities updateThreadStatus:threadId userId:usrId];
        [self postNotificationForId:strUserId];
    }
    else { /* fetch from server */
        if (isDeleted == 0) { /* only fetch from server if delete flag is false */
            NSLog(@"EMAIL NOT FOUND");
            /* below 3 lines will delete inbox copy first, then fetch from server */
            NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
            for (NSManagedObject * obj in inboxEmails) {
                [CoreDataManager deleteObject:obj];
            }
            
            NSString * email = [userObject valueForKey:kUSER_EMAIL];
            NSString * foldr = kFOLDER_INBOX;
            if ([folder isEqualToString:@"SENT"]) {
                foldr = kFOLDER_SENT_MAILS;
            }
            MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
            responseCount++;
            [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:foldr gmailMessageId:emailId folderType:kFolderAllMail];
        }
    }
}

-(void)syncTrash:(NSDictionary *)daictionary user:(NSManagedObject *)userObject {
    //    sync Trash
    //    /* how delete logic work in TRASH */
    
    //    delete = x
    //    if (x = true) { // this means email permanently delete
    //        if(email exist) {
    //            /* delete from db */
    //            /* update top email flag */
    //        }
    //        else {
    //            /* do nothing */
    //        }
    //    }
    //    else { // this means email moved to trash from inbox or sent etc
    //        if(email exist) {
    //            /* do nothing */
    //        }
    //        else {
    //            /* fetch from imap */
    //            /* from inbox folder */
    //        }
    //    }
    
    long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:usrId];
    int isDeleted = [[daictionary objectForKey:@"deleted"] intValue];
    int isRead = [[daictionary objectForKey:@"is_read"] intValue];
    uint64_t threadId = [[daictionary objectForKey:@"thread_id_dec"] longLongValue];
    uint64_t emailId = [[daictionary objectForKey:@"email_id_dec"] longLongValue];
    
    NSMutableArray * email = [CoreDataManager fetchSingleEmailForUniqueIdInTrash:emailId andUserId:usrId];
    
    if (email.count>0) { /* update flags if unique id exist */
        for (NSManagedObject * object in email) {
            int oldCount = [[object valueForKey:kUNREAD_COUNT] intValue];
            if (oldCount == isRead) {
                if (isRead == 0) {
                    [object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
                }
                else {
                    [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
                }
            }
            if (isDeleted == 1) { /* this means email permanently delete */
                BOOL isTopEmail = [[object valueForKey:kIS_THREAD_TOP_EMAIL] boolValue];
                if (isTopEmail == NO) {
                    NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:threadId andUserId:usrId isTopEmail:YES isTrash:YES entity:[object entity].name];
                    if (array.count>0) {
                        NSManagedObject *obj = [array lastObject];
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_THREAD_TOP_EMAIL];
                    }
                }
                NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
                [self deleteAttachament:usrId threadId:[uniqueId longLongValue]];
                [CoreDataManager deleteObject:object];
            }
            //            else {
            //                BOOL fetchEmail = NO;
            //
            //                /* below 3 lines will delete inbox copy first, then fetch from server */
            //                NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
            //                for (NSManagedObject * obj in inboxEmails) {
            //
            //                    NSString * existingFolder = [obj valueForKey:kMAIL_FOLDER];
            //                    BOOL isTrashFlag = [[obj  valueForKey:kIS_TRASH_EMAIL] boolValue];
            //                    BOOL isArchiveFlag = [[obj  valueForKey:kIS_ARCHIVE] boolValue];
            //                    BOOL isSentFlag = [[obj  valueForKey:kIS_SENT_EMAIL] boolValue];
            //                    BOOL isInboxFlag = [[obj  valueForKey:kIS_Inbox_EMAIL] boolValue];
            //
            //                    if ([existingFolder isEqualToString:kFOLDER_INBOX] || !isTrashFlag || isArchiveFlag || isInboxFlag|| isSentFlag) {
            //                        [CoreDataManager deleteObject:obj];
            //                        fetchEmail = YES;
            //                    }
            //                }
            //                if (fetchEmail) {
            //                    NSLog(@"EMAIL NOT FOUND");
            //                    NSString * email = [userObject valueForKey:kUSER_EMAIL];
            //                    MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
            //                    responseCount++;
            //                    [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:kFOLDER_ALL_MAILS gmailMessageId:emailId folderType:kFolderArchiveMail];
            //                }
            //            }
        }
        
        NSMutableArray * completeThread = [CoreDataManager fetchThreadForId:threadId userId:usrId];
        if (completeThread.count>0) {
            for (NSManagedObject * object in completeThread) {
                BOOL update = [[object valueForKey:@"updateData"] boolValue];
                [object setValue:[NSNumber numberWithBool:!update] forKey:@"updateData"];
            }
        }
        [CoreDataManager updateData];
        [Utilities updateThreadStatus:threadId userId:usrId];
        [self postNotificationForId:strUserId];
    }
    else { /* fetch from server */
        NSLog(@"EMAIL NOT FOUND");
        if (isDeleted == 0) { /* this means email moved to trash from inbox or sent etc */
            
            /* below 3 lines will delete inbox copy first, then fetch from server */
            NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
            for (NSManagedObject * object in inboxEmails) {
                [CoreDataManager deleteObject:object];
            }
            
            NSString * email = [userObject valueForKey:kUSER_EMAIL];
            MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
            responseCount++;
            [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:kFOLDER_TRASH_MAILS gmailMessageId:emailId folderType:kFolderTrashMail];
        }
    }
}

-(void)syncDraft:(NSDictionary *)daictionary user:(NSManagedObject *)object {
    //    sync Draft
    //    /* how delete logic work in Draft */
    //    delete = x
    //    if (x = true) {
    //        if(email exist) {
    //            /* delete from db */
    //        }
    //        else {
    //            /* do nothing */
    //        }
    //    }
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:usrId];
    int isDeleted = [[daictionary objectForKey:@"deleted"] intValue];
    int isRead = [[daictionary objectForKey:@"is_read"] intValue];
    //uint64_t threadId = [[daictionary objectForKey:@"thread_id_dec"] longLongValue];
    uint64_t emailId = [[daictionary objectForKey:@"email_id_dec"] longLongValue];
    
    NSMutableArray * email = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
    
    if (email.count>0) { /* update flags if unique id exist */
        for (NSManagedObject * object in email) {
            int oldCount = [[object valueForKey:kUNREAD_COUNT] intValue];
            if (oldCount == isRead) {
                if (isRead == 0) {
                    [object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
                }
                else {
                    [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
                }
            }
            if (isDeleted == 1) { /* delete email from Core Data */
                NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
                [self deleteAttachament:usrId threadId:[uniqueId longLongValue]];
                [CoreDataManager deleteObject:object];
            }
        }
        [CoreDataManager updateData];
        [self postNotificationForId:strUserId];
    }
    else { /* fetch from server */
        NSLog(@"EMAIL NOT FOUND");
        if (isDeleted == 0) { /* this means new draft added */
            NSString * email = [object valueForKey:kUSER_EMAIL];
            MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
            responseCount++;
            [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:kFOLDER_DRAFT_MAILS gmailMessageId:emailId folderType:kFolderDraftMail];
        }
    }
}
-(void)syncArchive:(NSDictionary *)daictionary user:(NSManagedObject *)userObject {
    //    sync Archvie
    //    /* how delete logic work in Draft */
    //    delete = x
    //    if (x = true) {
    //        if(email exist) {
    //            /* delete from db */
    //        }
    //        else {
    //            /* do nothing */
    //        }
    //    }
    long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:usrId];
    int isDeleted = [[daictionary objectForKey:@"deleted"] intValue];
    int isRead = [[daictionary objectForKey:@"is_read"] intValue];
    uint64_t threadId = [[daictionary objectForKey:@"thread_id_dec"] longLongValue];
    uint64_t emailId = [[daictionary objectForKey:@"email_id_dec"] longLongValue];
    
    NSMutableArray * email = [CoreDataManager fetchSingleEmailForUniqueIdInArchive:emailId andUserId:usrId];
    
    if (email.count>0) { /* update flags if unique id exist */
        for (NSManagedObject * object in email) {
            int oldCount = [[object valueForKey:kUNREAD_COUNT] intValue];
            if (oldCount == isRead) {
                if (isRead == 0) {
                    [object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
                }
                else {
                    [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
                }
            }
            if (isDeleted == 1) { /* delete email from Core Data */
                NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
                [self deleteAttachament:usrId threadId:[uniqueId longLongValue]];
                [CoreDataManager deleteObject:object];
                /* marking email read/unread give delete notification. comment until fixed from server side */
            }
//            else {
//                BOOL fetchEmail = NO;
//                /* below 3 lines will delete inbox copy first, then fetch from server */
//                NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
//                for (NSManagedObject * obj in inboxEmails) {
//                    
//                    NSString * existingFolder = [obj valueForKey:kMAIL_FOLDER];
//                    BOOL isTrashFlag = [[obj  valueForKey:kIS_TRASH_EMAIL] boolValue];
//                    BOOL isArchiveFlag = [[obj  valueForKey:kIS_ARCHIVE] boolValue];
//                    BOOL isInboxFlag = [[obj  valueForKey:kIS_Inbox_EMAIL] boolValue];
//                    
//                    if ([existingFolder isEqualToString:kFOLDER_INBOX] || isTrashFlag || !isArchiveFlag || isInboxFlag) {
//                        [CoreDataManager deleteObject:obj];
//                        fetchEmail = YES;
//                    }
//                }
//                if (fetchEmail) {
//                    NSLog(@"EMAIL NOT FOUND");
//                    NSString * email = [userObject valueForKey:kUSER_EMAIL];
//                    MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
//                    responseCount++;
//                    [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:kFOLDER_ALL_MAILS gmailMessageId:emailId folderType:kFolderArchiveMail];
//                }
//            }
        }
        [CoreDataManager updateData];
        [Utilities updateThreadStatus:threadId userId:usrId];
        [self postNotificationForId:strUserId];
    }
    else { /* fetch from server */
        NSLog(@"EMAIL NOT FOUND");
        if (isDeleted == 0) { /* this means new archive added */
            /* below 3 lines will delete inbox copy first, then fetch from server */
            NSMutableArray * inboxEmails = [CoreDataManager fetchSingleEmailForUniqueId:emailId andUserId:usrId];
            for (NSManagedObject * obj in inboxEmails) {
                [CoreDataManager deleteObject:obj];
            }
            
            NSString * email = [userObject valueForKey:kUSER_EMAIL];
            MCOIMAPSession * session = [Utilities getSyncSessionForUID:[Utilities getStringFromLong:usrId]];
            responseCount++;
            [self fetchEmailFromServerWithSession:session userId:usrId currentEmail:email folder:kFOLDER_ALL_MAILS gmailMessageId:emailId folderType:kFolderArchiveMail];
        }
    }
}

-(void)fetchEmailFromServerWithSession:(MCOIMAPSession *)session userId:(long)userId currentEmail:(NSString *)email folder:(NSString *)folder gmailMessageId:(uint64_t)gmailMessageId folderType:(int)type {
    /*isErrorOccur = NO;
    responseCount = 0;
    [self checkForDeleteCall];
    return;*/
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:folder expression:[MCOIMAPSearchExpression searchGmailMessageID:gmailMessageId]];
    
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        NSLog(@"index set = %@",indexSet.description);
        if (error == nil) {
            if (indexSet.count>0) {
                [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:indexSet fromFolder:folder withSessaion:session requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
                    responseCount--;
                    if (error == nil) {
                        if (messages.count>0) {
                            BOOL isTrash = NO;
                            BOOL isDraft = NO;
                            BOOL isArchive = NO;
                            if (type == kFolderTrashMail) {
                                isTrash = YES;
                            }
                            if (type == kFolderDraftMail) {
                                isDraft = YES;
                            }
                            if (type == kFolderArchiveMail) {
                                isArchive = YES;
                            }
                            
                            MCOIMAPMessage *msg = [messages lastObject];
                            if ([CoreDataManager isThreadIdExist:[msg gmailThreadID] forUserId:userId forFolder:type entity:kENTITY_EMAIL]>0) {
                                
                                NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[msg gmailThreadID] andUserId:userId isTopEmail:NO isTrash:isTrash entity:kENTITY_EMAIL];
                                int unreadCount = 0;
                                if (msg.flags == 0) {
                                    unreadCount = 1;
                                }
                                BOOL isThreadTop = NO;
                                BOOL isInbox = NO;
                                BOOL isSent = NO;
                                BOOL isConvo = NO;
                                if (array.count>0) { /* update old top thread */
                                    NSManagedObject * obj = [array objectAtIndex:0];
                                    
                                    BOOL isDate1Later = [Utilities isDate:msg.header.date isLatestThanDate:(NSDate *)[obj valueForKey:kEMAIL_DATE]];
                                    if (isDate1Later) {
                                        
                                        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_THREAD_TOP_EMAIL];
                                    }
                                    else {
                                        isThreadTop = YES;
                                    }
                                    
                                    [CoreDataManager updateData];
                                }
                                
                                if (!isDraft && !isTrash) { /* block is for making thread i.e sent and inbox */
                                    NSArray * typeArray = [Utilities getMessageTypes:msg userId:userId currentEmail:email];
                                    isInbox = [[typeArray objectAtIndex:0] boolValue];
                                    isSent = [[typeArray objectAtIndex:1] boolValue];
                                    isConvo = [[typeArray objectAtIndex:2] boolValue];
                                }
                                
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:isThreadTop mailFolderName:folder isSent:isSent isTrash:isTrash isArchive:isArchive isDarft:isDraft draftFetchedFromServer:NO isConversation:isConvo isInbox:isInbox userId:[Utilities getStringFromLong:userId] isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [Utilities markSnoozedAndFavorite:msg userId:userId isInboxMail:YES];
                            }
                            else { /* single email */
                                int unreadCount = 0;
                                if ( msg.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                BOOL isSent = NO;
                                BOOL isInbox = NO;
                                if ([folder isEqualToString:kFOLDER_SENT_MAILS]) {
                                    isSent = YES;
                                }
                                else if([folder isEqualToString:kFOLDER_INBOX]) {
                                    isInbox = YES;
                                }
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:NO mailFolderName:folder isSent:isSent isTrash:isTrash isArchive:isArchive isDarft:isDraft draftFetchedFromServer:NO isConversation:NO isInbox:isInbox userId:[Utilities getStringFromLong:userId] isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [Utilities markSnoozedAndFavorite:msg userId:userId isInboxMail:YES];
                            }
                        }
                        else {
                            isErrorOccur = YES;
                        }
                        [self postNotificationForId:[Utilities getStringFromLong:userId]];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
                    }
                    else {
                        isErrorOccur = YES;
                    }
                    [self checkForDeleteCall];
                }onError:^(NSError* error) {
                }];
            }
            else {
                /*isErrorOccur = YES; this property was yes, but when we fetch some email snd delete it before  gettting notified by our server it will cause loop because index count will be zero */
                isErrorOccur = NO;
                responseCount--;
                [self checkForDeleteCall];
            }
        }
        else {
            responseCount--;
            isErrorOccur = YES;
            [self checkForDeleteCall];
        }
    }];
}
-(void)postNotificationForId:(NSString *)uid {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:uid forKey:kUSER_ID];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_NEW_EMAIL object:nil userInfo:userInfo];
}

-(void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object userId:(NSString *)userId {
    NSString * firebaseFavoriteId = [object valueForKey:kFAVORITE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseFavoriteId]) {
        [Utilities syncToFirebase:nil syncType:[FavoriteEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kFAVORITE_FIREBASE_ID]];
    }
    
    NSString * firebaseSnoozedId = [object valueForKey:kSNOOZED_FIREBASE_ID];
    if ([Utilities isValidString:firebaseSnoozedId]) {
        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kSNOOZED_FIREBASE_ID]];
    }
}

-(void)dealloc {
    NSLog(@"dealloc - SyncManager");
}
@end
