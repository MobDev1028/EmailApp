//
//  MailCoreUtilityManager.h
//  SimpleEmail
//
//  Created by Zahid on 25/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@interface MailCoreUtilityManager : NSObject
+ (MailCoreUtilityManager*)sharedMailCoreUtilityManager;
typedef void (^completionBlock)(id response);
typedef void (^failureBlock)(NSError* error);
//-(void)copyIndexSet:(MCOIndexSet *)indexSetUid
//         fromFolder:(NSString *)fromFolderName
//       withSessaion:(MCOIMAPSession *)session
//           toFolder:(NSString *)toFolderName
//    completionBlock:(completionBlock)completionBlock
//            onError:(failureBlock)onError;
//
//
//-(void)fetchMessageForIndexSet:(MCOIndexSet *)indexSet
//                    fromFolder:(NSString *)folderName
//
//                  withSessaion:(MCOIMAPSession *)session
//                   requestKind:(MCOIMAPMessagesRequestKind)request
//               completionBlock:(void (^)(NSError* error, NSArray *threadMessages ,MCOIndexSet *vanishedMessages))completionBlock
//                       onError:(void (^)(NSError* error))onError;
@end
