//
//  ModelAttachments.m
//  SimpleEmail
//
//  Created by Zahid on 06/02/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "ModelAttachments.h"

@implementation ModelAttachments
-(id)init {
    return [self initWithAttachments:nil userId:-1 emailUniqueId:-1];
}
-(id)initWithAttachments:(NSMutableArray *)attachments userId:(long)userId emailUniqueId:(uint64_t)emailUniqueId {
    self = [super init];
    if (self != nil) {
        self.userId = userId;
        self.emailUniqueId = emailUniqueId;
        self.attachments = attachments;
    }
    return self;
}
@end
