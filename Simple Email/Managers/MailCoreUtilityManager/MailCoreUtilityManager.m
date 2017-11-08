//
//  MailCoreUtilityManager.m
//  SimpleEmail
//
//  Created by Zahid on 25/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MailCoreUtilityManager.h"
#import "Constants.h"

@implementation MailCoreUtilityManager

+ (MailCoreUtilityManager*)sharedMailCoreUtilityManager {
    static MailCoreUtilityManager *sharedManager = nil;
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
            completionBlock(dic);
            NSLog(@"Updated flags! with dictionary = %@", dic);
        } else {
            onError(error);
            NSLog(@"Error updating flags:%@", error);
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
