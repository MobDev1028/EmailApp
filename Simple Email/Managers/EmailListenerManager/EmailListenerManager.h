//
//  EmailListenerManager.h
//  SimpleEmail
//
//  Created by Zahid on 08/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@class EmailListenerManager;
@protocol EmailListenerManagerDelegate <NSObject>
- (void)emailListenerManager:(EmailListenerManager*)manager didReceiveNewEmailWithId:(long)userId;
@end

@interface EmailListenerManager : NSObject
@property (assign, nonatomic) id <EmailListenerManagerDelegate> delegate;
@property (nonatomic, strong) MCOIMAPIdleOperation *idleOperation;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, assign) int lastMessageId;
@property (assign) BOOL isListening;
@property (assign) BOOL isListenerStopped;
@property (assign) BOOL isNotificationRegister;
@property (assign) long userId;
@property (nonatomic, strong) NSString * currentLoginMailAddress;
- (void)stopListner;
- (void)startEmailListnerTask;
- (id)initWithUser:(long)uid;
//+ (EmailListenerManager*)sharedEmailListenerManager;
@end
