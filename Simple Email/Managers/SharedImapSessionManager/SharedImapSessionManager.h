//
//  SharedImapSessionManager.h
//  SimpleEmail
//
//  Created by Zahid on 26/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@interface SharedImapSessionManager : NSObject
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) NSString *user;
- (void)createSessionForUser:(NSString *)userId;
+ (SharedImapSessionManager*)sharedSession;
@end
