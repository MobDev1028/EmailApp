//
//  ModelEmail.h
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@interface ModelEmail : NSObject

@property (nonatomic, assign) long userId;
@property (nonatomic, assign) uint64_t emailId;
@property (nonatomic, assign) long senderId;
@property (nonatomic, assign) int  emailFlags;
@property (nonatomic, assign) long unreadCount;
@property (nonatomic, assign) uint64_t emailUniqueId;
@property (nonatomic, assign) uint64_t emailThreadiD;
@property (nonatomic, assign) long totalUnreadCount;
@property (nonatomic, assign) int attachmentCount;

@property (nonatomic, strong) NSDate * emailDate;
@property (nonatomic, assign) NSDate * snoozedDate;
@property (nonatomic, assign) NSDate * snoozedMarkedAt;

@property (nonatomic, strong) NSString * emailBody;
@property (nonatomic, strong) NSString * senderName;
@property (nonatomic, strong) NSString * emailTitle;
@property (nonatomic, strong) NSString * emailPreview;
@property (nonatomic, strong) NSString * emailSubject;
@property (nonatomic, strong) NSString * senderImageUrl;
@property (nonatomic, strong) NSString * emailFolderName;
@property (nonatomic, strong) NSString * emailHtmlPreview;

@property (nonatomic, strong) MCOIMAPMessage * message;
@property (nonatomic, strong) NSMutableArray * toAddresses;
@property (nonatomic, strong) NSMutableArray * fromAddresses;
@property (nonatomic, strong) NSMutableArray * ccAddresses;
@property (nonatomic, strong) NSMutableArray * bccAddresses;

@property (nonatomic, assign) BOOL isSent;
@property (nonatomic, assign) BOOL isTrash;
@property (nonatomic, assign) BOOL isDraft;
@property (nonatomic, assign) BOOL isInbox;
@property (nonatomic, assign) BOOL isSnoozed;
@property (nonatomic, assign) BOOL isArchive;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isFakeDraft;
@property (nonatomic, assign) BOOL isThreadEmail;
@property (nonatomic, assign) BOOL isConversation;
@property (nonatomic, assign) BOOL draftSavedOnServer;
@property (nonatomic, assign) BOOL isAttachementAvailable;
@end
