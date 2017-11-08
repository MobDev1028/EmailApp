
//
//  MCOIMAPFetchContentOperationManager.m
//  SimpleEmail
//
//  Created by Zahid on 16/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MCOIMAPFetchContentOperationManager.h"
#import "Utilities.h"
#import "Constants.h"
#import "MCOIMAPSessionManager.h"
#import "MailCoreServiceManager.h"

@implementation MCOIMAPFetchContentOperationManager {
    MCOIMAPSessionManager * imapSessionManager;
}
- (id)init {
    if (self=[super init]) {
        
    }
    return self;
}
-(void)createFetcherWithUserId:(NSString *)uid {
    
    if ([Utilities isValidString:uid]) {
        self.strUserId = uid;
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.delegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[uid longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        
        [imapSessionManager createImapSessionWithUserData:object];
    }
}
-(void)startFetchOpWithFolder:(NSString *)folderName andMessageId:(int)uid forNSManagedObject:(NSManagedObject *)object nsindexPath:(NSIndexPath *)index needHtml:(BOOL)needHtml {
    if ([Utilities isInternetActive] == NO) {
        return;
    }
    if (self.imapSession == nil) {
        [self createFetcherWithUserId:self.strUserId];
        return;
    }
    if (!needHtml) {
        MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
        __block MCOIMAPMessageRenderingOperation *messageRenderingOperation = [self.imapSession plainTextBodyRenderingOperationWithMessage:message
                                                                                                                folder:folderName];
    				[messageRenderingOperation start:^(NSString * plainTextBodyString, NSError * error) {
                        if (error == nil) {
                            
                            //                            NSManagedObjectContext *context = [CoreDataManager getManagedObjectContext];
                            //                            NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                            //                            temporaryContext.parentContext = context;
                            //
                            //                            [temporaryContext performBlock:^{
                            
                            NSString * plainString = plainTextBodyString;
                            
                            //                                NSString * html = [message htmlRenderingWithFolder:folderName delegate:self];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate MCOIMAPFetchContentOperation:self didReceiveHtmlBody:@"" andMessagePreview:plainString atIndexPath:index];
                            });
                            
                            if (object !=nil) {
                                if (![Utilities isValidString:plainString]) {
                                    plainString = @" ";
                                }
                                [object setValue:plainString forKey:kEMAIL_BODY];
                                if ([plainString length]>=50) {
                                    plainString = [plainString substringToIndex:50];
                                }
                                
                                [object setValue:plainString forKey:kEMAIL_PREVIEW];
                                //[object setValue:@"" forKey:kEMAIL_HTML_PREVIEW];
                                [CoreDataManager updateData];
                            }
                            
                            [[NSThread currentThread] isMainThread] ? NSLog(@"MAIN THREAD19") : NSLog(@"NOT MAIN THREAD19");
                            
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate MCOIMAPFetchContentOperation:self didRecieveError:error];
                            });
                            
                        }
                        messageRenderingOperation = nil;
                    }];
    }
    else {
        
        MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
        
        MCOIMAPMessageRenderingOperation *messageRenderingOperation = [self.imapSession htmlBodyRenderingOperationWithMessage:message
                                                                                                                       folder:folderName];
        
    				[messageRenderingOperation start:^(NSString * htmlBodyString, NSError * error) {
                        if (error != nil) {
                            [self.delegate MCOIMAPFetchContentOperation:self didRecieveError:error];
                        }
                        else {
                            
                            //                NSManagedObjectContext *context = [CoreDataManager getManagedObjectContext];
                            //                NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                            //                temporaryContext.parentContext = context;
                            //
                            //                [temporaryContext performBlock:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate MCOIMAPFetchContentOperation:self didReceiveHtmlBody:htmlBodyString andMessagePreview:@"" atIndexPath:index];
                            });
                            if (object !=nil) {
                                //[object setValue:[Utilities isValidString:messageBody]? messageBody : @" " forKey:kEMAIL_BODY];
                                //if ([messageBody length]>=50) {
                                //    messageBody = [messageBody substringToIndex:50];
                                //}
                                
                                //[object setValue:[Utilities isValidString:messageBody]? messageBody : @" " forKey:kEMAIL_PREVIEW];
                                [object setValue:htmlBodyString forKey:kEMAIL_HTML_PREVIEW];
                                [CoreDataManager updateData];
                            }
                            
                        }
                    }];
        /*__block  MCOIMAPFetchContentOperation *operation = [self.imapSession  fetchMessageOperationWithFolder:folderName  uid:uid];
        [operation start:^(NSError *error, NSData *data) {
            if (error != nil) {
                [self.delegate MCOIMAPFetchContentOperation:self didRecieveError:error];
            }
            else {
                
                MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
                //[[MailCoreServiceManager sharedMailCoreServiceManager] downloadAttachments:message messageParser:messageParser];
                NSString * messageBody = [messageParser plainTextBodyRendering];
                NSString * html = [messageParser htmlRenderingWithDelegate:self];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate MCOIMAPFetchContentOperation:self didReceiveHtmlBody:html andMessagePreview:messageBody atIndexPath:index];
                });
                if (object !=nil) {
                    [object setValue:[Utilities isValidString:messageBody]? messageBody : @" " forKey:kEMAIL_BODY];
                    if ([messageBody length]>=50) {
                        messageBody = [messageBody substringToIndex:50];
                    }
                    
                    [object setValue:[Utilities isValidString:messageBody]? messageBody : @" " forKey:kEMAIL_PREVIEW];
                    [object setValue:html forKey:kEMAIL_HTML_PREVIEW];
                    [CoreDataManager updateData];
                }
                
                [operation cancel];
            }
        }];*/
    }
}
-(NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header {
    return @"";
    
}
-(BOOL) MCOAbstractMessage:(MCOAbstractMessage *)msg canPreviewPart:(MCOAbstractPart *)part {
    return NO;
}
//-(NSString*) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part {
//    return @"";
//}
-(NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part {
    return @"";
}
-(NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header {
    return @"";
}
//- (NSString *)MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg {
//    return @"";
//}
//- (NSString *)MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg {
//    return @"";
//
//}
- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header {
    return @"";
}
- (BOOL)MCOAbstractMessage:(MCOAbstractMessage *)msg shouldShowPart:(MCOAbstractPart *)part {
    return YES;
}
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html {
//    return @"";
//}
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html {
//   return @"";
//}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    [self.delegate MCOIMAPFetchContentOperation:self didUpdateAccessTokenSuccessfullyWithSession:imapSession];
    manager = nil;
    imapSessionManager = nil;
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    [self.delegate MCOIMAPFetchContentOperation:self didRecieveError:error];
}
-(void)dealloc {
    NSLog(@"dealloc - MCOIMAPFetchContentOperationManager");
    [Utilities destroyImapSession:self.imapSession];
    imapSessionManager.delegate = nil;
    imapSessionManager = nil;
}
@end
