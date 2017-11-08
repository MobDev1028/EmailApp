//
//  ArchiveManager.h
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@interface ArchiveManager : NSObject
+ (ArchiveManager*)sharedArchiveManager;
typedef void (^completionBlock)(id response);
typedef void (^failureBlock)(NSError* error);

-(void)markArchiveIndexSet:(MCOIndexSet *)indexSetUid forFolder:(NSString *)folderName withSessaion:(MCOIMAPSession *)session destinationFolder:(NSString *)destFolder completionBlock:(completionBlock)completionBlock onError:(failureBlock)onError;
@end
