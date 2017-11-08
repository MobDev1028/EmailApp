//
//  MCOIMAPFetchContentOperationManager.h
//  SimpleEmail
//
//  Created by Zahid on 16/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "CoreDataManager.h"
#import "MCOIMAPSessionManager.h"

@class MCOIMAPFetchContentOperationManager;

@protocol MCOIMAPFetchContentOperationManagerDelegate <NSObject>
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath;

-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error;
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion;
@end

@interface MCOIMAPFetchContentOperationManager : NSObject<MCOIMAPSessionManagerDelegate>
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, assign) id<MCOIMAPFetchContentOperationManagerDelegate> delegate;
@property (nonatomic, strong) NSString * strUserId;

-(void)createFetcherWithUserId:(NSString *)uid;
-(void)startFetchOpWithFolder:(NSString *)folderName andMessageId:(int)uid forNSManagedObject:(NSManagedObject *)object nsindexPath:(NSIndexPath *)index needHtml:(BOOL)needHtml;
@end
