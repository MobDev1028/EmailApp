//
//  MailCoreServiceManager.m
//  SimpleEmail
//
//  Created by Zahid on 31/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MailCoreServiceManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "ModelAttachments.h"

@implementation MailCoreServiceManager

+ (MailCoreServiceManager*)sharedMailCoreServiceManager {
    static MailCoreServiceManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(void)copyIndexSet:(MCOIndexSet *)indexSetUid
         fromFolder:(NSString *)folderName
       withSessaion:(MCOIMAPSession *)session
           toFolder:(NSString *)toFolderName
    completionBlock:(completionBlock)completionBlock
            onError:(failureBlock)onError {
    
    /* or use move function */
    /* - (MCOIMAPMoveMessagesOperation *)moveMessagesOperationWithFolder:(NSString *)folder
     uids:(MCOIndexSet *)uids
     destFolder:(NSString *)destFolder NS_RETURNS_NOT_RETAINED; */
    
    MCOIMAPCopyMessagesOperation * op = [session copyMessagesOperationWithFolder:
                                         folderName
                                                                            uids:indexSetUid
                                                                      destFolder:toFolderName];
    [op start:^(NSError * error, NSDictionary * dic) {
        if(!error) {
            NSLog(@"Updated flags! with dictionary = %@", dic);
            completionBlock(dic);
        } else {
            onError(error);
            NSLog(@"Error updating flags:%@", error);
        }
        
    }];
}
/* MARK: SEEN/UNSEEN */
-(void)markMessage:(MCOIndexSet *)indexSet
        fromFolder:(NSString *)folderName
      withSessaion:(MCOIMAPSession *)session
       requestKind:(MCOIMAPStoreFlagsRequestKind)kind
          flagType:(MCOMessageFlag)type
   completionBlock:(void (^)())completionBlock
           onError:(void (^)(NSError* error))onError {
    
    MCOIMAPOperation *msgOperation = [session storeFlagsOperationWithFolder:folderName
                                                                       uids:indexSet
                                                                       kind:kind flags:type];
    
    [msgOperation start:^(NSError * error) {
        if (error == nil) {
            NSLog(@"Message Marked.............");
            
            completionBlock();
        }
        else {
            NSLog(@"error = %@", error.localizedDescription);
            onError(error);
        }
    }];
}


-(void)fetchMessageForIndexSet:(MCOIndexSet *)indexSet
                    fromFolder:(NSString *)folderName
                  withSessaion:(MCOIMAPSession *)session
                   requestKind:(MCOIMAPMessagesRequestKind)request
               completionBlock:(void (^)(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages))completionBlock
                       onError:(void (^)(NSError* error))onError {
    
    MCOIMAPFetchMessagesOperation * mco = [session fetchMessagesOperationWithFolder:folderName requestKind:request uids:indexSet];
    
    [mco start:^(NSError *error, NSArray *threadMessages, MCOIndexSet *vanishedMessages) {
        
        completionBlock(error, threadMessages, vanishedMessages);
    }];
}

-(void)searchExpressionOperationWithFolder:(NSString *)folderName
                              withSessaion:(MCOIMAPSession *)session
                                  threadId:(long)threadId
                           completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock
                                   onError:(void (^)(NSError* error))onError {
    
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:folderName expression: [MCOIMAPSearchExpression searchGmailThreadID:threadId]];
    
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        completionBlock(error, indexSet);
        
    }];
}
-(void)searchTrashMails:(MCOIMAPSession *)session userId:(NSString *)userId
        completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock {
    
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:kFOLDER_TRASH_MAILS expression: [MCOIMAPSearchExpression searchAll]];
    
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        completionBlock(error, indexSet);
    }];
}
-(void)searchUnreadMessages:(NSString *)folderName
               withSessaion:(MCOIMAPSession *)session
            completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock {
    
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:folderName expression: [MCOIMAPSearchExpression searchUnread]];
    
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        completionBlock(error, indexSet);
        if (error == nil) {
            NSLog(@"UNREAD MESSASGE FOUND!!!");
            NSLog(@"UNREAD COUNT IS: %d",indexSet.count);
        }
        else{
            NSLog(@"Error occured: %@",error.description);
        }
    }];
}
-(void)searchStringInMessages:(NSString *)folderName
                      session:(MCOIMAPSession *)session
                       string:(NSString *)string
              completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock {
    
    MCOIMAPSearchExpression* expression = [MCOIMAPSearchExpression searchContent:string];
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:folderName expression: expression];
    NSLog(@"String searched: %@: %@",string,folderName);
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        if (error == nil) {
            NSLog(@"String MESSASGE FOUND!!!");
            NSLog(@"String COUNT IS: %d",indexSet.count);
            NSLog(@"indexSet.description: %@",indexSet.description);
        }
        else{
            NSLog(@"Error occured: %@",error.description);
        }
        completionBlock(error, indexSet);
    }];
}
-(void)downloadAttachments:(NSManagedObject *)object session:(MCOIMAPSession *)session email:(NSString *)email {
    NSString * folderName = [object valueForKey:kMAIL_FOLDER];
    NSString * messageId = [object valueForKey:kEMAIL_ID];
    NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
    long userId = [[object valueForKey:kUSER_ID] integerValue];
    __block  MCOIMAPFetchContentOperation *operation = [session fetchMessageOperationWithFolder:folderName uid:[messageId intValue]];
    //MCOAttachment *attach = message.attachments.lastObject;
    //MCOIMAPFetchContentOperation *operation = [session fetchMessageAttachmentByUIDOperationWithFolder:folderName uid:[message uid] partID:attach.contentID encoding:MCOEncodingBase64];//part.encoding];
    [operation start:^(NSError *error, NSData *data) {
        if (error == nil) {
            MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
            if ([messageParser.attachments count] > 0) {
                /* Create unique file Name */
                NSString * fileName = [NSString stringWithFormat:@"%@%@",uniqueId, email];
                NSMutableArray * pathsArray = [[NSMutableArray alloc] init];
                NSLog(@"fileName %@",fileName);
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *saveDirectory = [paths objectAtIndex:0];
                NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:fileName];
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:attachmentPath];
                if (fileExists) {
                    NSLog(@"File already exists!");
                }
                else{
                    NSLog(@"Writing fileeee: %@",attachmentPath);
                    [data writeToFile:attachmentPath atomically:YES];
                }
                [pathsArray addObject:fileName];
                [CoreDataManager mapAttachmentDataWithModel:[[ModelAttachments alloc] initWithAttachments:pathsArray userId:userId emailUniqueId:[uniqueId longLongValue]] entity:kENTITY_ATTACHMENTS];
                NSDictionary *dictionary = [NSDictionary dictionaryWithObject:uniqueId forKey:kEMAIL_UNIQUE_ID];
                [[NSNotificationCenter defaultCenter] postNotificationName:kATTACHMENT_DOWNLOADED object:nil userInfo:dictionary];
            }
            [operation cancel];
        }
    }];
}
-(void)deleteIndexSet:(MCOIndexSet*)indexset imapSession:(MCOIMAPSession *)session userId:(NSString *)userId  completionBlock:(void (^)(NSError* error))completionBlock {
    MCOMessageFlag newflags = MCOMessageFlagDraft;
    
    newflags |= MCOMessageFlagDeleted;
    newflags |= !MCOMessageFlagFlagged;
    MCOIMAPOperation *changeFlags = [session  storeFlagsOperationWithFolder:kFOLDER_TRASH_MAILS  uids:indexset kind:MCOIMAPStoreFlagsRequestKindSet flags:newflags];
    [changeFlags start:^(NSError *error) {
        completionBlock(error);
    }];
}
-(void)expungeFolder:(MCOIMAPSession *)session userId:(NSString *)userId  completionBlock:(void (^)(NSError* error))completionBlock {
    MCOIMAPOperation *expungeOp = [session expungeOperation:kFOLDER_TRASH_MAILS];
    [expungeOp start:^(NSError *error) {
        completionBlock(error);
    }];
}
//-(void)syncMessages:(NSString *)folderName
//       withSessaion:(MCOIMAPSession *)session
//    completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock {
//
//    MCOIMAPFetchMessagesOperation * op = [session syncMessagesWithFolder:@"INBOX" requestKind:MCOIMAPMessagesRequestKindUID uids:indexSet modSeq:lastModSeq];
//
//    [op start:^(NSError * error, NSArray * messages, MCOIndexSet * vanishedMessages) {
//         NSLog(@"added or modified messages: %@", messages); NSLog(@"deleted messages: %@", vanishedMessages);
//     }];
//}
-(void)dealloc {
    NSLog(@"dealloc : MailCoreUtilityManager");
}


+(void)addStar {
    /*add star
     [imapSession storeFlagsOperationWithFolder:"INBOX"
     uids:[MCOIndexSet indexSetWithIndex:11]
     kind:MCOIMAPStoreFlagsRequestKindAdd
     flags:MCOMessageFlagFlagged];
     remove star
     [imapSession storeFlagsOperationWithFolder:"INBOX"
     uids:[MCOIndexSet indexSetWithIndex:11]
     MCOIMAPStoreFlagsRequestKindRemove
     flags:MCOMessageFlagFlagged];*/
}
@end

