//
//  ArchiveManager.m
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ArchiveManager.h"
#import "MailCoreUtilityManager.h"

@implementation ArchiveManager
/* https://github.com/MailCore/mailcore2/issues/574 */

+ (ArchiveManager*)sharedArchiveManager {
    static ArchiveManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(void)markArchiveIndexSet:(MCOIndexSet *)indexSetUid forFolder:(NSString *)folderName withSessaion:(MCOIMAPSession *)session destinationFolder:(NSString *)destFolder completionBlock:(completionBlock)completionBlock onError:(failureBlock)onError {
    
    MCOIMAPOperation *msgOperation = [session storeFlagsOperationWithFolder:folderName
                                                                       uids:indexSetUid
                                                                       kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagDeleted];
    [msgOperation start:^(NSError * error) {
        if (error == nil) {
            NSLog(@"Marked Archive.............");
            completionBlock(@"marked");
            /*[[MailCoreUtilityManager sharedMailCoreUtilityManager] copyIndexSet:indexSe tUid fromFolder:folderName withSessaion:session toFolder:destFolder completionBlock:^(id response) {
                if (response != nil) {
                    completionBlock(response);
                }
            } onError:^( NSError * error) {
                //  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot Fetch Profile!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                //  [av show];
                
            }];*/
        }
        else {
            onError(error);
            NSLog(@"error = %@", error.localizedDescription);
        }
    }];
}

-(void)dealloc {
    NSLog(@"dealloc : ArchiveManager");
}

@end
