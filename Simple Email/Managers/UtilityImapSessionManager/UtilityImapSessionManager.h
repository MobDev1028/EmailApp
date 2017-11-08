//
//  UtilityImapSessionManager.h
//  SimpleEmail
//
//  Created by Zahid on 15/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@interface UtilityImapSessionManager : NSObject
@property (nonatomic, strong) NSString *user;
@property (nonatomic, assign) int sessionType;
@property (nonatomic, strong) MCOIMAPSession * imapSession;
- (void)createSessionForUser:(NSString *)userId type:(int)type;
@end
