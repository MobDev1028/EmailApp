//
//  MCOSMTPSessionManager.h
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@class MCOSMTPSessionManager;

@protocol MCOSMTPSessionManagerDelegate <NSObject>
-(void)MCOSMTPSessionManager:(MCOSMTPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOSMTPSession *)smtpSession;
-(void)MCOSMTPSessionManager:(MCOSMTPSessionManager *)manager didReceiveError:(NSError *)error;
@end


@interface MCOSMTPSessionManager : NSObject
@property (nonatomic, assign) id<MCOSMTPSessionManagerDelegate> delegate;
-(void)createSmtpSessionForKeychainItemName:(NSString *)keychainItemName;
@end
