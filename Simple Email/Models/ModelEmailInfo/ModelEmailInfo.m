//
//  ModelEmailInfo.m
//  SimpleEmail
//
//  Created by Zahid on 28/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ModelEmailInfo.h"

@implementation ModelEmailInfo
@synthesize userId;
@synthesize emailId;
@synthesize emailThreadiD;
@synthesize emailUniqueId;
@synthesize emailDate;
@synthesize emailFolderName;

-(id)init {
    return [self initWithMessage:nil userId:nil folderName:nil];
}
-(id)initWithMessage:(MCOIMAPMessage *)message userId:(NSString *)uid folderName:(NSString *)folder {
    self = [super init];
    if (self != nil) {
        self.userId = [uid longLongValue];
        self.emailId = message.uid;
        self.emailThreadiD = message.gmailThreadID;
        self.emailUniqueId = message.gmailMessageID;
        self.emailDate = message.header.date;
        self.emailFolderName = folder;
    }
    return self;
}
@end
