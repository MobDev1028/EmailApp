//
//  SendMessageManager.m
//  SimpleEmail
//
//  Created by Zahid on 23/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SendMessageManager.h"
#import "MCOSMTPSessionManager.h"
#import "Utilities.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation SendMessageManager {
    MCOIMAPSessionManager * imapSessionManager;
    MCOSMTPSessionManager * mcoSMTPSessionManager;
}

-(void)startSendingWithEmail:(NSString *)email {
    NSMutableArray * array = [CoreDataManager fetchUserIdForEmail:email];
    long userId = -1;
    if (array.count>=1) {
        NSManagedObject * object = [array objectAtIndex:0];
        userId = [[object valueForKey:kUSER_ID] longLongValue];
    }
    NSString * currentAccount  = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    if (userId != -1) {
        currentAccount = [Utilities getStringFromLong:userId];
    }
    
    if ([Utilities isValidString:currentAccount]) {
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[currentAccount longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        NSString * keyChainName = [object valueForKey:kUSER_KEYCHANIN_ITEM_NAME];
        
        if (self.folderType == kFolderDraftMail) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
            imapSessionManager.delegate = self;
            [imapSessionManager createImapSessionWithUserData:object];
        }
        else {
            mcoSMTPSessionManager = [[MCOSMTPSessionManager alloc] init];
            [mcoSMTPSessionManager setDelegate:self];
            [mcoSMTPSessionManager createSmtpSessionForKeychainItemName:keyChainName];
            
        }
        
    }
}

-(void)composeMessage {
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    if (self.header != nil) { /* for reply, replyAll and forward message */
        builder.header = self.header;
    }
    
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:[self.fromData objectAtIndex:0] mailbox:[self.fromData objectAtIndex:1]]];
    
    NSMutableArray *to = [[NSMutableArray alloc] init];
    for(NSString *toAddress in self.toAddresses) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:toAddress];
        [to addObject:newAddress];
    }
    [[builder header] setTo:to];
    
    NSMutableArray *cc = [[NSMutableArray alloc] init];
    for(NSString *ccAddress in self.ccAddresses) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:ccAddress];
        [cc addObject:newAddress];
    }
    [[builder header] setCc:cc];
    NSMutableArray *bcc = [[NSMutableArray alloc] init];
    for(NSString *bccAddress in self.bccAddresses) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:bccAddress];
        [bcc addObject:newAddress];
    }
    
    [[builder header] setBcc:bcc];
    [[builder header] setSubject:[self.sendingData objectAtIndex:0]];
    
    
    //NSLog(@"text = %@",[self.sendingData objectAtIndex:1] );
    //NSLog(@"html text = %@",[self.sendingData objectAtIndex:2] );
    //[builder setTextBody:@"hello text body"];
    if(self.sendingData.count>2) {
        NSString * body = [NSString stringWithFormat:@"<p>%@</p>%@",[self.sendingData objectAtIndex:1],[self.sendingData objectAtIndex:2]];
        //NSLog(@"html text = %@",body );
        [builder setHTMLBody:body];
    }
    else {
        NSString * body = [NSString stringWithFormat:@"<p>%@</p>",[self.sendingData objectAtIndex:1]];
        //NSLog(@"html text = %@",body );
        [builder setHTMLBody:body];
    }
    
    for(int x = 0; x <self.attachments.count; x++) {
        id object = [self.attachments objectAtIndex:x];
        if ([object isKindOfClass:[NSData class]]) {
            //NSString * link = [self.attachments objectAtIndex:x];
            //SDImageCache* myCache = [SDImageCache sharedImageCache];
            //UIImage* displayImage = [myCache imageFromDiskCacheForKey:link];
            //NSData * imageData = UIImageJPEGRepresentation(displayImage, 1.0);
            NSData * data = (NSData *)[self.attachments objectAtIndex:x];
            MCOAttachment *attachment = [MCOAttachment attachmentWithData:data filename:[NSString stringWithFormat:@"atachment%d",x+1]];
            //MCOAttachment *attachment = [MCOAttachment attachmentWithContentsOfFile:link];
            attachment.mimeType =  @"image/jpg";
            [builder addAttachment:attachment];
            //SDImageCache* myCache = [SDImageCache sharedImageCache];
            //UIImage* displayImage = [myCache imageFromDiskCacheForKey:@"MyImage.png"];
        }
        else {
            [builder addAttachment:[self.attachments objectAtIndex:x]];
        }
    }
    
    NSData * rfc822Data = [builder data];
    if (self.folderType == kFolderDraftMail) {
        [self saveDraftMessageWithData:rfc822Data];
    }
    else {
        [self sendMessageWithData:rfc822Data];
    }
}
-(void)sendMessageWithData:(NSData*)rfc822Data {
    MCOSMTPSendOperation *sendOperation = [self.smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        if(error) {
            NSLog(@"%@ Error sending email:%@", @"", error);
            [self.delegate sendMessageManager:nil didRecieveError:error];
        } else {
            NSLog(@"Successfully sent email!");
            [self.delegate sendMessageManager:nil emailSentSuccessfullyTo:@""];
        }
    }];
    /* https://github.com/MailCore/mailcore2/wiki/SMTP-Examples */
}
-(void)saveDraftMessageWithData:(NSData*)rfc822Data {
    MCOIMAPAppendMessageOperation * op = [self.imapSession appendMessageOperationWithFolder:kFOLDER_DRAFT_MAILS messageData:rfc822Data flags:MCOMessageFlagDraft];
    [op start:^(NSError *error, uint32_t createdUID) {
        if(error) {
            NSLog(@"%@ Error saving draft:%@", @"", error);
            [self.delegate sendMessageManager:nil didRecieveError:error];
        } else {
            NSLog(@"Successfully saved draft!");
            [self.delegate sendMessageManager:self draftSavedSuccessfullyWithId:createdUID];
        }
    }];
}
//-(void)send {
//
//    NSString * body = @"";
//    NSString * subject = @"";
//    NSString * addedHtmlString = @"";
//    MCOIMAPMessage * message;
//
//    int msgType;
//    if (message) {
//        switch (msgType) {
//            case 1: /* empty */
//            {
//                NSString *path = [[NSBundle mainBundle] pathForResource: @"empty_template" ofType: @"html"];
//                body = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//            }
//                break;
//            case 2: /* forward */
//            {
//                NSString *path = [[NSBundle mainBundle] pathForResource: @"forward_template" ofType: @"html"];
//                NSString *format = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//                body = [NSString stringWithFormat:format, addedHtmlString];
//                subject = [NSString stringWithFormat:@"Fwd: %@", message.header.subject];
//
//                if ([message isKindOfClass:[MCOIMAPMessage class]]) {
//                    for (MCOIMAPMessagePart *part in message.attachments) {
//                        MCOIMAPFetchContentOperation *op = [self.imapSession fetchMessageAttachmentByUIDOperationWithFolder:@"INBOX"
//                                                                                                                        uid:((MCOIMAPMessage *)message).uid
//                                                                                                                     partID:[part partID]
//                                                                                                                   encoding:MCOEncodingBase64];
//                        [[NSNotificationCenter defaultCenter] postNotificationName:@"STARTLOADING" object:nil userInfo:nil];
//                        [op start:^(NSError *error, NSData *partData) {
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"STOPLOADING" object:nil userInfo:nil];
//                            if (error != nil) {
//                                NSLog(@"error:%@", error);
//                                return;
//                            }
//
//                            //                            AttachmentObj *attachmentObj = [[AttachmentObj alloc] init];
//                            //                            attachmentObj.data = partData;
//                            //                            attachmentObj.name = part.filename;
//                            //                            [self.attach addObject:attachmentObj];
//                            //                            [self.table reloadData];
//                        }];
//                    }
//                } else if ([message isKindOfClass:[MCOMessageParser class]]) {
//                    //                    for (MCOAttachment *attach in self.message.attachments) {
//                    //                        AttachmentObj *attachmentObj = [[AttachmentObj alloc] init];
//                    //                        attachmentObj.data = attach.data;
//                    //                        attachmentObj.name = attach.filename;
//                    //                        [self.attach addObject:attachmentObj];
//                    //                        [self.table reloadData];
//                    //                    }
//                }
//            }
//                break;
//            case 3: /* reply */
//            {
//                NSString *path = [[NSBundle mainBundle] pathForResource: @"reply_template" ofType: @"html"];
//                NSString *format = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//
//                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//                NSString *dateString = [dateFormatter stringFromDate:message.header.date];
//
//                MCOAddress *from = message.header.from;
//                NSString *wrote = [NSString stringWithFormat:@"On %@, %@ <%@> wrote:", dateString, from.displayName, from.mailbox];
//                body = [NSString stringWithFormat:format, wrote, addedHtmlString];
//
//                MCOAddress *addr = message.header.from;
//                MCOAddress * to = [NSSet setWithObject:addr.mailbox];
//                subject = [NSString stringWithFormat:@"Re: %@", message.header.subject];
//            }
//                break;
//            case 4:  /* reply all */
//            {
//                NSString *path = [[NSBundle mainBundle] pathForResource: @"reply_template" ofType: @"html"];
//                NSString *format = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//
//                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//                NSString *dateString = [dateFormatter stringFromDate:message.header.date];
//
//                MCOAddress *from = message.header.from;
//                NSString *wrote = [NSString stringWithFormat:@"On %@, %@ <%@> wrote:", dateString, from.displayName, from.mailbox];
//                body = [NSString stringWithFormat:format, wrote, addedHtmlString];
//
//                MCOAddress *addr = message.header.from;
//                MCOAddress *to = [NSSet setWithObject:addr.mailbox];
//
//                if (message.header.to.count > 1) {
//                    NSMutableArray *ccArray = [[NSMutableArray alloc] init];
//                    for (int i = 1; i < message.header.to.count; i++) {
//                        MCOAddress *addr = [message.header.to objectAtIndex:i];
//                        [ccArray addObject:addr.mailbox];
//                    }
//                    for (int i = 0; i < message.header.cc.count; i++) {
//                        MCOAddress *addr = [message.header.cc objectAtIndex:i];
//                        [ccArray addObject:addr.mailbox];
//                    }
//                    for (int i = 0; i < message.header.bcc.count; i++) {
//                        MCOAddress *addr = [message.header.cc objectAtIndex:i];
//                        [ccArray addObject:addr.mailbox];
//                    }
//                    MCOAddress * cc = [NSSet setWithArray:ccArray];
//                }
//
//                subject = [NSString stringWithFormat:@"Re: %@", message.header.subject];
//            }
//                break;
//            default:
//                break;
//        }
//    }
//
//}
#pragma - mark MCOSMTPSessionManager Delegates
-(void)MCOSMTPSessionManager:(MCOSMTPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOSMTPSession *)smtpSession {
    self.smtpSession = smtpSession;
    [self composeMessage];
}

-(void)MCOSMTPSessionManager:(MCOSMTPSessionManager *)manager didReceiveError:(NSError *)error {
    
}
#pragma - mark MCOIMAPSessionManager Delegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    [self composeMessage];
    
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
}



/*
 Reply / Reply All / Forward
 http://stackoverflow.com/questions/31059584/mailcore-2-ios-how-to-retrieve-reply-email-address
 https://github.com/MailCore/mailcore2/issues/146
 https://github.com/MailCore/mailcore2/issues/594
 https://github.com/MailCore/mailcore2/issues/700
 https://github.com/MailCore/mailcore2/issues/1078*/




/* or use below code
 
 http://stackoverflow.com/questions/31485359/sending-mailcore2-plain-emails-in-swift
 
 MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
 smtpSession.hostname = @"smtp.gmail.com";
 smtpSession.port = 465;
 smtpSession.username = @"matt@gmail.com";
 smtpSession.password = @"password";
 smtpSession.authType = MCOAuthTypeSASLPlain;
 smtpSession.connectionType = MCOConnectionTypeTLS;
 
 MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
 MCOAddress *from = [MCOAddress addressWithDisplayName:@"Matt R"
 mailbox:@"matt@gmail.com"];
 MCOAddress *to = [MCOAddress addressWithDisplayName:nil
 mailbox:@"hoa@gmail.com"];
 [[builder header] setFrom:from];
 [[builder header] setTo:@[to]];
 [[builder header] setSubject:@"My message"];
 [builder setHTMLBody:@"This is a test message!"];
 NSData * rfc822Data = [builder data];
 
 MCOSMTPSendOperation *sendOperation =
 [smtpSession sendOperationWithData:rfc822Data];
 [sendOperation start:^(NSError *error) {
 if(error) {
 NSLog(@"Error sending email: %@", error);
 } else {
 NSLog(@"Successfully sent email!");
 }
 }];
 
 
 
 
 
 
 
 
 
 
 
 
 
 To send an image as attachment in swift just add:
 
 var dataImage: NSData?
 dataImage = UIImageJPEGRepresentation(image, 0.6)!
 var attachment = MCOAttachment()
 attachment.mimeType =  "image/jpg"
 attachment.filename = "image.jpg"
 attachment.data = dataImage
 builder.addAttachment(attachment)*/

-(void)dealloc {
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    mcoSMTPSessionManager.delegate = nil;
    imapSessionManager = nil;
    mcoSMTPSessionManager = nil;
    NSLog(@"dealloc : SendMessageManager");
}
@end
