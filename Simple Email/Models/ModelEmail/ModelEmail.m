//
//  ModelEmail.m
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ModelEmail.h"

@implementation ModelEmail

@synthesize emailId;
@synthesize senderId;
@synthesize userId;
@synthesize emailDate;
@synthesize snoozedDate;
@synthesize emailPreview;
@synthesize emailSubject;
@synthesize emailTitle;
@synthesize emailUniqueId;
@synthesize senderImageUrl;
@synthesize senderName;
@synthesize isAttachementAvailable;
@synthesize isFavorite;
@synthesize isSnoozed;
@synthesize unreadCount;
@synthesize totalUnreadCount;
@synthesize emailThreadiD;
@synthesize isThreadEmail;
@synthesize emailFolderName;
@synthesize emailHtmlPreview;
@synthesize emailBody;
@synthesize isSent;
@synthesize isTrash;
@synthesize isFakeDraft;
@synthesize isInbox;
@synthesize isDraft;
@synthesize isArchive;
@synthesize emailFlags;
@synthesize draftSavedOnServer;
@synthesize message;
@synthesize attachmentCount;

- (id) init {
    self = [super init];
    if (self != nil) {
        
        self.userId = -1;
        self.emailId = -1;
        self.senderId = -1;
        self.emailFlags = -1;
        self.unreadCount = 0;
        self.emailThreadiD = -1;
        self.emailUniqueId = -1;
        self.totalUnreadCount = -1;
        self.attachmentCount = 0;
        
        self.message = nil;
        self.emailDate = nil;
        self.emailBody = nil;
        self.emailTitle = nil;
        self.senderName = nil;
        self.snoozedDate = nil;
        self.snoozedMarkedAt = nil;
        self.emailPreview = nil;
        self.emailSubject = nil;
        self.senderImageUrl = nil;
        self.emailFolderName = nil;
        self.emailHtmlPreview = nil;
        
        self.isSent = NO;
        self.isTrash = NO;
        self.isInbox = NO;
        self.isDraft = NO;
        self.isArchive = NO;
        self.isSnoozed = NO;
        self.isFavorite = NO;
        self.isFakeDraft = NO;
        self.isThreadEmail = NO;
        self.isConversation = NO;
        self.draftSavedOnServer = NO;
        self.isAttachementAvailable = NO;
    }
    return self;
}

@end
