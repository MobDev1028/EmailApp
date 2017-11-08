//
//  DraftManager.m
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "DraftManager.h"

@implementation DraftManager


/* https://github.com/MailCore/mailcore2/issues/1201
 http://libmailcore.com/mailcore2/api/Classes/MCOIMAPAppendMessageOperation.html
 https://github.com/MailCore/mailcore2/issues/303
 https://github.com/MailCore/mailcore2/issues/912
 below code is for saving draft
MCOIMAPAppendMessageOperation * op = [self.currentAccount.imapSession appendMessageOperationWithFolder:self.currentAccount.draftFolder messageData:data flags:MCOMessageFlagDraft];
[op start:^(NSError *error, uint32_t createdUID) {
    
}]; */


@end
