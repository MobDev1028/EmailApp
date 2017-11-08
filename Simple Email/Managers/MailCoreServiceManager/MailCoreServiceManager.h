//
//  MailCoreServiceManager.h
//  SimpleEmail
//
//  Created by Zahid on 31/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "CoreDataManager.h"
@interface MailCoreServiceManager : NSObject
+ (MailCoreServiceManager*)sharedMailCoreServiceManager;
typedef void (^completionBlock)(id response);
typedef void (^failureBlock)(NSError* error);

-(void)copyIndexSet:(MCOIndexSet *)indexSetUid
         fromFolder:(NSString *)fromFolderName
       withSessaion:(MCOIMAPSession *)session
           toFolder:(NSString *)toFolderName
    completionBlock:(completionBlock)completionBlock
            onError:(failureBlock)onError;

-(void)fetchMessageForIndexSet:(MCOIndexSet *)indexSet
                    fromFolder:(NSString *)folderName

                  withSessaion:(MCOIMAPSession *)session
                   requestKind:(MCOIMAPMessagesRequestKind)request
               completionBlock:(void (^)(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages))completionBlock
                       onError:(void (^)(NSError* error))onError;


-(void)searchExpressionOperationWithFolder:(NSString *)folderName
                              withSessaion:(MCOIMAPSession *)session
                                  threadId:(long)threadId
                           completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock
                                   onError:(void (^)(NSError* error))onError;
-(void)searchUnreadMessages:(NSString *)folderName
               withSessaion:(MCOIMAPSession *)session
            completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock;
-(void)markMessage:(MCOIndexSet *)indexSet
        fromFolder:(NSString *)folderName
      withSessaion:(MCOIMAPSession *)session
       requestKind:(MCOIMAPStoreFlagsRequestKind)kind
          flagType:(MCOMessageFlag)type
   completionBlock:(void (^)())completionBlock
           onError:(void (^)(NSError* error))onError;
-(void)searchTrashMails:(MCOIMAPSession *)session userId:(NSString *)userId
        completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock;
-(void)expungeFolder:(MCOIMAPSession *)session userId:(NSString *)userId  completionBlock:(void (^)(NSError* error))completionBlock;
-(void)deleteIndexSet:(MCOIndexSet*)indexset imapSession:(MCOIMAPSession *)session userId:(NSString *)userId  completionBlock:(void (^)(NSError* error))completionBlock;
-(void)searchStringInMessages:(NSString *)folderName
                      session:(MCOIMAPSession *)session
                       string:(NSString *)string
              completionBlock:(void (^)(NSError* error, MCOIndexSet *indexSet))completionBlock;
-(void)downloadAttachments:(NSManagedObject *)object session:(MCOIMAPSession *)session email:(NSString *)currentEmail;

@end
