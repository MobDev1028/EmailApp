//
//  ModelUser.m
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ModelUser.h"

@implementation ModelUser
@synthesize userEmail;
@synthesize userId;
@synthesize userImageUrl;
@synthesize userKeychainItemName;
@synthesize userOAuthAccessToken;
@synthesize userName;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.userEmail = nil;
        self.userId = -1;
        self.userImageUrl = nil;
        self.userKeychainItemName = nil;
        self.userOAuthAccessToken = nil;
        self.userName = nil;
    }
    return self;
}
@end
