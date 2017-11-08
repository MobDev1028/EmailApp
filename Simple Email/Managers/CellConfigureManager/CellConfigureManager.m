//
//  CellConfigureManager.m
//  SimpleEmail
//
//  Created by Zahid on 25/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "CellConfigureManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "EmailDetailViewController.h"
#import "MailThreadViewController.h"

@implementation CellConfigureManager

+(SmartInboxTableViewCell *)configureInboxCell:(SmartInboxTableViewCell *)cell withData:(NSManagedObject *)data andContentFetchManager:(MCOIMAPFetchContentOperationManager*)contentFetchManager view:(UIView*)view atIndexPath:(NSIndexPath *)indexPath isSent:(BOOL)isSent {
    
    NSString * subject = [data valueForKey:kEMAIL_SUBJECT];
    if ([Utilities isValidString:subject]) {
        cell.lblSubject.text = subject;
    }
    else {
        cell.lblSubject.text = kNO_SUBJECT_MESSAGE;
    }
    MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[data valueForKey:kMESSAGE_INSTANCE]];
    MCOAddress * mcoAddress = message.header.from;
    NSString * name = mcoAddress.displayName;//[data valueForKey:kSENDER_NAME];
    if (name == nil) { // if sender name nil, set email as name
        name = [data valueForKey:kEMAIL_TITLE];
    }
    if (isSent) {
        NSString * names = [Utilities getToNamesString:data];
        if (names != nil) {
            name = names;
        }
    }
    cell.lblSenderName.text = name;
    cell.btnAttachment.hidden = ![[data valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
    cell.btnFavorite.hidden = ![[data valueForKey:kIS_FAVORITE] boolValue];
    NSString * messagePreview = [data valueForKey:kEMAIL_PREVIEW];
    NSString * messageId = [data valueForKey:kEMAIL_ID];
    cell.tag = messageId.integerValue;
    NSString * folder = [data valueForKey:kMAIL_FOLDER];
    //messagePreview = [message htmlRenderingWithFolder:folder delegate:self];
    /*if ([Utilities isValidString:messagePreview]) {*/
    if (messagePreview != nil) {
        cell.lblDetail.text = messagePreview;
    }
    else { // get message preview if not available in db
        cell.lblDetail.text = @" ";
        if (contentFetchManager != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [contentFetchManager startFetchOpWithFolder:folder andMessageId:[messageId intValue] forNSManagedObject:data nsindexPath:indexPath needHtml:NO];
            });
        }
    }
    
    long userId = [[data valueForKey:kUSER_ID] integerValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:userId threadId:[[data valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[data entity].name];
    if (unreadCount>0) {
        cell.imgNitificationCount.hidden = NO;
        cell.lblNitificationCount.text = [NSString stringWithFormat:@"%d",unreadCount];
    }
    else {
        cell.imgNitificationCount.hidden = YES;
        cell.lblNitificationCount.text = @"";
    }
    NSDate * emailDate = (NSDate *)[data valueForKey:kEMAIL_DATE];
    cell.lblDate.text = [Utilities getEmailDateString:emailDate];//[Utilities getStringFromDate:[data valueForKey:kEMAIL_DATE] withFormat:@"MMMM d"];
    
    NSDate * snoozedDate = [data valueForKey:kSNOOZED_DATE];
    if ([[data valueForKey:kIS_SNOOZED] boolValue]) {
        if ([Utilities isDateInFuture:snoozedDate]) { // notification is not fired yet
            cell.contraintClockWidth.constant = 17.0f;
            cell.lblDate.text = [Utilities getSnoozedDateString:snoozedDate]; // set snoozed date
        }
        else {
            //            cell.contraintClockWidth.constant = 0.0f; // hide clock icon
            //            // set values to default
            //            [data setValue:[NSNumber numberWithBool:NO] forKey:kIS_SNOOZED];
            //            [data setValue:[NSNumber numberWithBool:YES] forKey:kSNOOZED_ONLY_IF_NO_REPLY];
            //            [data setValue:nil forKey:kSNOOZED_DATE];
            //            [CoreDataManager updateData];
        }
    }
    else {
        cell.contraintClockWidth.constant = 0.0f;
    }
    
    [view setNeedsUpdateConstraints];
    [view layoutIfNeeded];
    return cell;
}

+(SmartInboxTableViewCell *)configureInboxCell:(SmartInboxTableViewCell *)cell withData:(NSDictionary *)data view:(UIView*)view atIndexPath:(NSIndexPath *)indexPath isSent:(BOOL)isSent {
    
    NSString * subject = [data valueForKey:@"subject"];
    if (subject == nil) {
        cell.lblSubject.text = kNO_SUBJECT_MESSAGE;
    }
    else if ([Utilities isValidString:subject]) {
        cell.lblSubject.text = subject;
    }
    else {
        cell.lblSubject.text = kNO_SUBJECT_MESSAGE;
    }
    
    NSMutableArray *toAddress = [data valueForKey:@"to"];
    NSString * name = [toAddress firstObject];
    cell.lblSenderName.text = name;
    cell.btnAttachment.hidden = YES;
    cell.btnFavorite.hidden = YES;
    cell.imgNitificationCount.hidden = YES;
    NSString * messagePreview = [data valueForKey:@"message"];
//    NSString * messageId = [data valueForKey:kEMAIL_ID];
//    cell.tag = messageId.integerValue;
//    NSString * folder = [data valueForKey:kMAIL_FOLDER];
    //messagePreview = [message htmlRenderingWithFolder:folder delegate:self];
    /*if ([Utilities isValidString:messagePreview]) {*/
    if (messagePreview != nil) {
        cell.lblDetail.text = messagePreview;
    }
    else { // get message preview if not available in db
        cell.lblDetail.text = @" ";
//        if (contentFetchManager != nil) {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                [contentFetchManager startFetchOpWithFolder:folder andMessageId:[messageId intValue] forNSManagedObject:data nsindexPath:indexPath needHtml:NO];
//            });
//        }
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *date = [data valueForKey:@"send_time"];
    NSDate * emailDate = [dateFormat dateFromString:[data valueForKey:@"send_time"]];
    cell.lblDate.text = [Utilities getEmailDateString:emailDate];//[Utilities getStringFromDate:[data valueForKey:kEMAIL_DATE] withFormat:@"MMMM d"];
    
    [view setNeedsUpdateConstraints];
    [view layoutIfNeeded];
    return cell;
}

//- (NSData *) MCOAbstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
//{
//    return [self _dataForIMAPPart:part folder:folder];
//}
//- (NSData *) _dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
//{
//    NSData * data;
//    NSString * partUniqueID = [part uniqueID];
//    data = [[self delegate] MCOMessageView:self dataForPartWithUniqueID:partUniqueID];
//    if (data == NULL) {
//        [[self delegate] MCOMessageView:self fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError * error) {
//            [self _refresh];
//        }];
//    }
//    return data;
//}
+(void)didTapOnEmail:(NSManagedObject *)data folderType:(int)type {
    NSString * folderName  = [data valueForKey:kMAIL_FOLDER];
    //    uint64_t threadId = [[data valueForKey:kEMAIL_THREAD_ID] longLongValue];
    //    BOOL isSnoozed = [[data valueForKey:kIS_SNOOZED] boolValue];
    //    long userId = [[data valueForKey:kUSER_ID] integerValue];
    //    int folderType = [Utilities getFolderTypeForString:folderName];
    
    //if ([CoreDataManager fetchEmailsForThreadId:threadId andUserId: userId folderType:folderType needOnlyIds:YES isSnoozed:isSnoozed].count>1) {
    
    MailThreadViewController * mailThreadViewController = [[MailThreadViewController alloc] initWithNibName:@"MailThreadViewController" bundle:nil];
    mailThreadViewController.selectedEmailThreadId = [[data valueForKey:kEMAIL_THREAD_ID] longLongValue];
    mailThreadViewController.folderName = folderName;
    mailThreadViewController.isSnoozed =  [[data valueForKey:kIS_SNOOZED] boolValue];
    mailThreadViewController.object = data;
    mailThreadViewController.folderType = type;
    [Utilities pushViewController:mailThreadViewController animated:YES];
    //}
    //    else {
    //        EmailDetailViewController * emailDetailViewController = [[EmailDetailViewController alloc] initWithNibName:@"EmailDetailViewController" bundle:nil];
    //        emailDetailViewController.isViewPresented = NO;
    //        emailDetailViewController.modelEmail = [Utilities parseEmailModelForDBdata:data];
    //        emailDetailViewController.object = data;
    //        emailDetailViewController.folderType = [Utilities getFolderTypeForString:folderName];
    //        [Utilities pushViewController:emailDetailViewController animated:YES];
    //    }
}

@end
