//
//  SendMessageManager.h
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "MCOIMAPSessionManager.h"
@class SendMessageManager;
@protocol SendMessageManagerDelegate <NSObject>

-(void)sendMessageManager:(SendMessageManager *)manager emailSentSuccessfullyTo:(NSString*)to;
-(void)sendMessageManager:(SendMessageManager *)manager draftSavedSuccessfullyWithId:(long)uid;
-(void)sendMessageManager:(SendMessageManager *)manager didRecieveError:(NSError*)error;

@end

@interface SendMessageManager : NSObject
@property (nonatomic, weak) id <SendMessageManagerDelegate> delegate;
@property (nonatomic, strong) MCOSMTPSession *smtpSession;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) NSMutableArray *toAddresses;
@property (nonatomic, strong) NSMutableArray *ccAddresses;
@property (nonatomic, strong) NSMutableArray *bccAddresses;
@property (nonatomic, strong) NSMutableArray *fromData;
@property (nonatomic, strong) NSMutableArray *sendingData;
@property (nonatomic, strong) NSMutableArray *attachments;
@property (assign) int folderType;
@property (nonatomic, strong) MCOMessageHeader * header;

-(void)startSendingWithEmail:(NSString *)email;
@end
