//
//  Utilities.m
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "Utilities.h"
#import "SWRevealViewController.h"
#import "Constants.h"
#import "ModelEmail.h"
#import "WebServiceManager.h"
#import "Reachability.h"
#import "MBProgressHUD.h"
#import "SentViewController.h"
#import "InboxViewController.h"
#import "TrashViewController.h"
#import "DraftViewController.h"
#import "UnreadViewController.h"
#import "SnoozedViewController.h"
#import "ArchiveViewController.h"
#import "RegularInboxViewController.h"
#import "FavoriteMailsViewController.h"
#import "QuickResponseViewController.h"
#import "AcountAlertPageViewController.h"
#import "SharedInstanceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "QuickResponseSyncManager.h"
#import "SendLaterSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "EmailUpdateManager.h"
#import "SnoozePreferenceManager.h"
#import "SWRevealViewController.h"
#import "ComposeQuickResponseViewController.h"
#import "UtilityImapSessionManager.h"
#import "MailCoreServiceManager.h"
#import "ArchiveManager.h"
#import "AppDelegate.h"

@implementation Utilities
+ (void)setLayoutConstarintsForView:(UIView *)subview forParent:(UIView *)parentView topValue:(float)top {
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]];
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f]];
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:parentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:top]];
}

+ (void)setLayoutConstarintsForEditorView:(UIView *)editor parentView:(UIView *)view fromBottomView:(UIView *)bottomView bottomSpace:(float)bottomSpace topView:(UIView *)topView topSpace:(float)topSpace leadingSpace:(float)leadingSpace trailingSpace:(float)trailingSpace {
    [view addConstraint:[NSLayoutConstraint constraintWithItem:editor attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:bottomSpace]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:editor attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeTop multiplier:1.0f constant:topSpace]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:editor attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:leadingSpace]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:editor attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:trailingSpace]];
}


+ (void)synchDefaults
{
    NSUserDefaults *userDefauls;
    userDefauls = [NSUserDefaults standardUserDefaults];
    [userDefauls synchronize];
    
}
+ (void)setDefaults
{
    
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    
    // load the default values for the user defaults
    userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"Info"
                                                           ofType:@"plist"];
    userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
}


+ (void )setUserDefaultWithValue:(id)value andKey:(NSString *)key {
    NSUserDefaults *userDefauls;
    userDefauls = [NSUserDefaults standardUserDefaults];
    [userDefauls setObject:value forKey:key];
    [userDefauls synchronize];
    
}

+ (id)getUserDefaultWithValueForKey:(NSString *)key {
    NSUserDefaults *userDefauls;
    userDefauls = [NSUserDefaults standardUserDefaults];
    return [userDefauls objectForKey:key];
}

+ (void)pushViewController:(UIViewController *)uiviewController animated:(BOOL)animated {
    SWRevealViewController *sWRevealViewController = (SWRevealViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    UINavigationController * navController = (UINavigationController *)[sWRevealViewController frontViewController];
    
    [navController pushViewController:uiviewController animated:animated];
    
}

+(void)removeDelegatesForViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[RegularInboxViewController class]]) {
        RegularInboxViewController * regVC = (RegularInboxViewController *)vc;
        [regVC removeDelegates];
    }
    else if ([vc isKindOfClass:[SentViewController class]]) {
        SentViewController * sentVC = (SentViewController *)vc;
        [sentVC removeDelegates];
    }
    else if ([vc isKindOfClass:[InboxViewController class]]) {
        InboxViewController * inboxVC = (InboxViewController *)vc;
        [inboxVC removeDelegates];
    }
    else if ([vc isKindOfClass:[TrashViewController class]]) {
        TrashViewController * trashVC = (TrashViewController *)vc;
        [trashVC removeDelegates];
    }
    else if ([vc isKindOfClass:[DraftViewController class]]) {
        DraftViewController * draftVC = (DraftViewController *)vc;
        [draftVC removeDelegates];
    }
    else if ([vc isKindOfClass:[UnreadViewController class]]) {
        UnreadViewController * unreadVC = (UnreadViewController *)vc;
        [unreadVC removeDelegates];
    }
    else if ([vc isKindOfClass:[SnoozedViewController class]]) {
        SnoozedViewController * snoozedVC = (SnoozedViewController *)vc;
        [snoozedVC removeDelegates];
    }
    else if ([vc isKindOfClass:[ArchiveViewController class]]) {
        ArchiveViewController * archiveVC = (ArchiveViewController *)vc;
        [archiveVC removeDelegates];
    }
    else if ([vc isKindOfClass:[FavoriteMailsViewController class]]) {
        FavoriteMailsViewController * favoriteVC = (FavoriteMailsViewController *)vc;
        [favoriteVC removeDelegates];
    }
    else if ([vc isKindOfClass:[QuickResponseViewController class]]) {
        QuickResponseViewController * qrVC = (QuickResponseViewController *)vc;
        [qrVC removeDelegates];
    }
    else if ([vc isKindOfClass:[AcountAlertPageViewController class]]) {
        AcountAlertPageViewController * acAlertVC = (AcountAlertPageViewController *)vc;
        [acAlertVC removeDelegates];
    }
}
+(BOOL)isValidString:(NSString *)str {
    if (str!=nil && ![str isEqualToString:@""] && ![str isEqualToString:@"(null)"] && ![str isEqualToString:@"(null) "] ) {
        return true;
    }
    return false;
}


+(NSString *)getNewKeychainItemName {
    NSString * keyCount = [self getUserDefaultWithValueForKey:kKEY_COUNT];
    if ([self isValidString:keyCount]) { // incremnet key and save it
        int count = [keyCount intValue];
        if (count<0) {
            count = 0;
        }
        count++;
        keyCount = [NSString stringWithFormat:@"%d",count];
    }
    else { //first log_in
        keyCount = [NSString stringWithFormat:@"%d",1];
    }
    
    return [NSString stringWithFormat:@"%@%@",kKEYCHAIN_ITEM_NAME,keyCount];
}

+(NSString *) getStringFromDate:(NSDate *)date withFormat:(NSString *)formatString {
    NSDateFormatter *dateFormat;
    if (dateFormat == nil) {
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:formatString];
    }
    return [dateFormat stringFromDate:date];
}
+(NSString *) getSnoozedDateString:(NSDate *)date1 {
    NSDate * date2 = [NSDate date];
    
    NSDateFormatter *dateFormat;
    if (dateFormat == nil) {
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"h:mm a"];
    }
    if ([[self getDateWithoutTime:date1] compare:date2] == NSOrderedDescending) { // IF DATE IS IN FUTURE THAN SHOW DATE
        NSString *strFormat = @"MMMM d";
        
        NSString *currentYear = [Utilities getStringFromDate:date2 withFormat:@"YYYY"];
        NSString *year        = [Utilities getStringFromDate:date1 withFormat:@"YYYY"];
        
        if ([currentYear intValue] != [year intValue]) {
            strFormat = @"MMMM d, yyyy";
        }
        
        [dateFormat setDateFormat:strFormat];
    }
    return [dateFormat stringFromDate:date1];
}
+(NSString *) getEmailDateString:(NSDate *)date1 {
    NSDate * date2 = [NSDate date];
    
    NSDateFormatter *dateFormat;
    if (dateFormat == nil) {
        
        NSString *strFormat = @"MMMM d";
        
        NSString *currentYear = [Utilities getStringFromDate:date2 withFormat:@"YYYY"];
        NSString *year        = [Utilities getStringFromDate:date1 withFormat:@"YYYY"];
        
        if ([currentYear intValue] != [year intValue]) {
            strFormat = @"MMMM d, yyyy";
        }
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:strFormat];
    }
    if ([[self getDateWithoutTime:date1] compare:[self getDateWithoutTime:date2]] == NSOrderedSame) { // IF DATE IS IN FUTURE THAN SHOW DATE
        [dateFormat setDateFormat:@"h:mm a"];
    }
    return [dateFormat stringFromDate:date1];
}
+(NSString *) getEmailStringDateForDetailView:(NSDate *)date {
    
    NSDateFormatter *dateFormat;
    if (dateFormat == nil) {
        dateFormat = [[NSDateFormatter alloc] init];
        
        NSString *strFormat = @"d MMMM, h:mm a";
        
        NSDate * date2 = [NSDate date];
        NSString *currentYear = [Utilities getStringFromDate:date2 withFormat:@"YYYY"];
        NSString *year        = [Utilities getStringFromDate:date withFormat:@"YYYY"];
        
        if ([currentYear intValue] != [year intValue]) {
            strFormat = @"d MMMM, yyyy h:mm a";
        }
        
        [dateFormat setDateFormat:strFormat];
    }
    return [dateFormat stringFromDate:date];
}
+(NSDate *)getDateWithoutTime:(NSDate *)date {
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    return [calendar dateFromComponents:components];
}

+(NSMutableArray *)getMessageTypes:(MCOIMAPMessage *)message userId:(long)userId currentEmail:(NSString *)currentEmail {
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSMutableArray * msgArray = [CoreDataManager fetchSingleThreadForId:[message gmailThreadID] userId:userId];
    BOOL isSnoozed = NO;
    for (NSManagedObject * object in msgArray) {
        isSnoozed = [[object valueForKey:kIS_SNOOZED] boolValue];
        if (isSnoozed) {
            break;
        }
    }
    NSMutableArray * oldThread = [CoreDataManager fetchEmailsForThreadId:[message gmailThreadID] andUserId:userId folderType:[Utilities getFolderTypeForString:kFOLDER_INBOX] needOnlyIds:NO isSnoozed:isSnoozed entity:kENTITY_EMAIL];
    
    BOOL isSent = NO;
    BOOL isInbox = NO;
    
    BOOL isContainSent = NO;
    BOOL isContainInbox = NO;
    BOOL isConvo = NO;
    if ([message.header.sender.mailbox isEqualToString:currentEmail]) {
        isContainSent = YES;
        isSent = YES;
    }
    else {
        isInbox = YES;
        isContainInbox = YES;
    }
    
    for (NSManagedObject *object in oldThread) {
        
        if (!isContainSent || !isContainInbox) { // already convo
            if ([[object valueForKey:kIS_CONVERSATION] boolValue]) {
                isContainInbox = YES;
                isContainSent = YES;
                isConvo = YES;
                break;
            }
            else {
                if (isContainInbox) {
                    if ([[object valueForKey:kIS_SENT_EMAIL] boolValue]) {
                        isContainSent = YES;
                    }
                }
                else if (isContainSent){
                    if([[object valueForKey:kIS_Inbox_EMAIL] boolValue]) {
                        isContainInbox = YES;
                    }
                }
            }
        }
    }
    if (isContainInbox && isContainSent) {
        isConvo = YES;
    }
    if (isConvo) {
        for (NSManagedObject *object in oldThread) {
            [object setValue:[NSNumber numberWithBool:YES] forKey:kIS_CONVERSATION];
        }
        [CoreDataManager updateData];
    }
    [array addObject:[NSNumber numberWithBool:isInbox]];
    [array addObject:[NSNumber numberWithBool:isSent]];
    [array addObject:[NSNumber numberWithBool:isConvo]];
    return array;
}

+ (id) dataToDictionary:(id)data
{
    NSDictionary *json = nil;
    if (![data isKindOfClass:[NSDictionary class]]) {
        
        NSError* error;
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:kNilOptions error:&error];
        
        if(error != nil)
        {
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return json;
}
+(MCOIMAPSession *)getSessionForUID:(NSString *)userId {
    NSMutableDictionary * imapDictionary = [[SharedInstanceManager sharedInstance] imapSharedSessions];
    UtilityImapSessionManager * utilityImapSessionManager = [imapDictionary objectForKey:userId];
    MCOIMAPSession * imapSession = [utilityImapSessionManager imapSession];
    if (imapSession == nil) {
        [utilityImapSessionManager createSessionForUser:userId type:1];
        return nil;
    }
    return imapSession;
}
+(MCOIMAPSession *)getSyncSessionForUID:(NSString *)userId {
    NSMutableDictionary * imapDictionary = [[SharedInstanceManager sharedInstance] imapSyncSessions];
    UtilityImapSessionManager * utilityImapSessionManager = [imapDictionary objectForKey:userId];
    MCOIMAPSession * imapSession = [utilityImapSessionManager imapSession];
    if (imapSession == nil) {
        [utilityImapSessionManager createSessionForUser:userId type:1];
        return nil;
    }
    return imapSession;
}
+(NSArray *)parseProfile:(NSDictionary *)dictionary {
    dictionary = [dictionary objectForKey:@"entry"];
    NSDictionary * dictionary1 = [[dictionary objectForKey:@"author"] objectAtIndex:0];
    NSString * name = [[dictionary1 objectForKey:@"name"] objectForKey:@"$t"];
    
    NSDictionary * dictionary2 = [dictionary objectForKey:@"gphoto$thumbnail"] ;
    NSString * thumb = [dictionary2 objectForKey:@"$t"];
    
    return [[NSArray alloc] initWithObjects:name,thumb, nil];
}

+(ModelEmail *)saveEmailModelForMessage:(MCOIMAPMessage *)message unreadCount:(long)unreadCount isThreadEmail:(BOOL)isThread mailFolderName:(NSString *)folderName isSent:(BOOL)isSent isTrash:(BOOL)isTrash isArchive:(BOOL)isArchive isDarft:(BOOL)isDarft draftFetchedFromServer:(BOOL)draftFromServer isConversation:(BOOL)conversation isInbox:(BOOL)isInbox userId:(NSString *)userId isFakeDraft:(BOOL)isFake enitity:(NSString *)entity {
    ModelEmail * emailData = [[ModelEmail alloc] init];
    NSString * currentAccount = userId;
    if (![Utilities isValidString:currentAccount]) {
        currentAccount = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    }
    
    emailData.userId = [currentAccount intValue];
    emailData.isFakeDraft = isFake;
    emailData.emailPreview = @"";
    emailData.emailFolderName = folderName;
    emailData.emailId = message.uid;
    emailData.emailFlags = message.flags;
    emailData.emailSubject = message.header.subject;
    emailData.senderName = message.header.sender.displayName;
    emailData.emailDate = message.header.date;
    emailData.emailUniqueId = message.gmailMessageID;
    emailData.emailTitle = message.header.from.mailbox;
    emailData.totalUnreadCount = unreadCount;
    emailData.isDraft = isDarft;
    emailData.isSent = isSent;
    emailData.isTrash = isTrash;
    emailData.isInbox = isInbox;
    emailData.isConversation = conversation;
    emailData.message = message;
    emailData.draftSavedOnServer = draftFromServer;
    emailData.toAddresses = [[NSMutableArray alloc] initWithArray:[self getParseAdressFromObject:message.header.to]];
    emailData.fromAddresses = [[NSMutableArray alloc] initWithArray:[self getParseAdressFromObject:message.header.from]];
    emailData.bccAddresses = [[NSMutableArray alloc] initWithArray:[self getParseAdressFromObject:message.header.bcc]];
    emailData.ccAddresses = [[NSMutableArray alloc] initWithArray:[self getParseAdressFromObject:message.header.cc]];
    emailData.isArchive = isArchive;
    if ( message.flags == 0 ) {
        emailData.unreadCount = 1;
    }
    emailData.isThreadEmail = isThread;
    emailData.emailThreadiD = message.gmailThreadID;
    if (message.attachments && message.attachments.count>0) {
        emailData.isAttachementAvailable = YES;
    }
    else {
        emailData.isAttachementAvailable = NO;
    }
    emailData.attachmentCount = (int)message.attachments.count;
    emailData.isSnoozed = NO;
    emailData.isFavorite = NO;
    // dispatch_async(dispatch_get_main_queue(), ^{
    if ([CoreDataManager isUniqueIdExist:message.gmailMessageID forUserId:emailData.userId entity:entity]>0) {
        /* skip if unique id exist */
        return nil;
    }
    else {
        //[CoreDataManager mapEmailDataWithModel:emailData forUserId:emailData.userId entity:entity];
        
        if (emailData != nil) {
            [Utilities addEmail:emailData forEntity:entity];
        }
        
        return emailData;
    }
    // });
}

+(ModelEmail *)parseEmailModelForDBdata:(NSManagedObject *)object {
    ModelEmail * emailData = [[ModelEmail alloc] init];
    emailData.emailDate = [object valueForKey:kEMAIL_DATE];
    emailData.emailId = [[object valueForKey:kEMAIL_ID] longLongValue];
    emailData.emailHtmlPreview  = [object valueForKey:kEMAIL_HTML_PREVIEW];
    emailData.emailPreview  = [object valueForKey:kEMAIL_PREVIEW];
    emailData.emailSubject = [object valueForKey:kEMAIL_SUBJECT];
    emailData.emailTitle = [object valueForKey:kEMAIL_TITLE];
    emailData.isAttachementAvailable = [[object valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
    emailData.isFavorite = [[object valueForKey:kIS_FAVORITE] boolValue];
    emailData.isSnoozed = [[object valueForKey:kIS_SNOOZED] boolValue];
    emailData.senderId = [[object valueForKey:kSENDER_ID] longLongValue];
    emailData.isThreadEmail = [[object valueForKey:kIS_THREAD_TOP_EMAIL] boolValue];
    emailData.senderImageUrl = [object valueForKey:kSENDER_IMAGE_URL];
    emailData.senderName = [object valueForKey:kSENDER_NAME];
    emailData.emailFolderName = [object valueForKey:kMAIL_FOLDER];
    emailData.snoozedDate = [object valueForKey:kSNOOZED_DATE];
    emailData.snoozedMarkedAt = [object valueForKey:kSNOOZED_MARKED_AT];
    emailData.userId = [[object valueForKey:kUSER_ID] longLongValue];
    emailData.isSent = [[object valueForKey:kIS_SENT_EMAIL] boolValue];
    emailData.unreadCount = [[object valueForKey:kUNREAD_COUNT] longLongValue];
    emailData.emailThreadiD = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    emailData.emailUniqueId = [[object valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
    
    return emailData;
}
+(NSString *)getToNamesString:(NSManagedObject *)object {
    
    NSString * name = nil;
    if (object == nil) {
        NSLog(@"object is null");
        return name;
    }
    long userId = [[object valueForKey:kUSER_ID] integerValue];
    NSString * email = [Utilities getEmailForId:[Utilities getStringFromLong:userId]];
    uint64_t threadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSMutableArray * thread = [CoreDataManager fetchEmailsForThreadId:threadId andUserId:userId folderType:kFolderSentMail needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
    NSMutableArray * namesArray = [NSMutableArray new];
    for (NSManagedObject * mail in thread) {
        NSString * sender = [mail valueForKey:kEMAIL_TITLE];
        if ([sender isEqualToString:email]) { /* i am sender */
            id object = [Utilities getUnArchivedArrayForObject:[mail valueForKey:kTO_ADDRESSES]];
            NSMutableArray * array = nil;
            if ([object isKindOfClass:[NSMutableArray class]]) {
                array = (NSMutableArray *)object;
            }
            if (array != nil) {
                for (int i = 0; i<array.count; ++i) {
                    NSMutableDictionary * dic = [array objectAtIndex:i];
                    NSString * to = [NSString stringWithFormat:@"%@ ", [dic objectForKey:kMAIL_BOX]];
                        
                    if (![namesArray containsObject:to]) {
                        [namesArray addObject:to];
                        //NSArray* foo = [to componentsSeparatedByString: @"@"];
                        //if (foo.count<=0) {
                        //    return nil;
                        //}
                        //NSString* firstBit = [foo objectAtIndex: 0];
                        if (name == nil) {
                            name = to;
                        }
                        else {
                            name = [NSString stringWithFormat:@"%@, %@",name, to];
                        }
                        if ([name length]>=50) {
                            return name;
                        }
                    }
                }
            }
        }
    }
    if ([name containsString:@"(null)"]) {
        return email;
    }
    return name;
}
+(NSMutableArray *)getParseAdressFromObject:(id)object {
    NSMutableArray * array = [[NSMutableArray alloc] init];
    if ([object isKindOfClass:[NSArray class]]) {
        NSArray * addArray = (NSArray *)object;
        for (int i = 0; i<addArray.count; ++i) {
            NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
            MCOAddress * address = [addArray objectAtIndex:i];
            [dic setValue:address.mailbox forKey:kMAIL_BOX];
            [dic setValue:address.mailbox forKey:kDISPLAY_NAME];
            [array addObject:dic];
        }
    }
    else {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        MCOAddress * mCOAddress = (MCOAddress *)object;
        [dic setValue:mCOAddress.mailbox forKey:kMAIL_BOX];
        [dic setValue:mCOAddress.mailbox forKey:kDISPLAY_NAME];
        [array addObject:dic];
    }
    return array;
}
+(NSMutableArray *)fillArrayForMessageDetail:(NSManagedObject *)object {
    NSMutableArray * array = [[NSMutableArray alloc] init];
    if (object) {
        MCOIMAPMessage * message = (MCOIMAPMessage*)[self getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
        
        if (message) {
            NSMutableDictionary * dic1 = [[NSMutableDictionary alloc] init];
            [dic1 setValue:@"FROM" forKey:@"cellTitle"];
            MCOAddress * mcoAddress = message.header.from;
            [dic1 setValue:mcoAddress.displayName forKey:@"title"];
            [dic1 setValue:mcoAddress.mailbox forKey:@"subTitle"];
            [array addObject:dic1];
            
            NSArray * toArray = message.header.to;
            for (int i = 0; i<toArray.count; ++i) {
                mcoAddress = [toArray objectAtIndex:i];
                NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
                if (i == 0) {
                    [dic setValue:@"TO" forKey:@"cellTitle"];
                }
                else {
                    [dic setValue:@"" forKey:@"cellTitle"];
                }
                [dic setValue:mcoAddress.displayName forKey:@"title"];
                [dic setValue:mcoAddress.mailbox forKey:@"subTitle"];
                [array addObject:dic];
            }
            
            NSArray * ccArray = message.header.cc;
            for (int i = 0; i<ccArray.count; ++i) {
                mcoAddress = [ccArray objectAtIndex:i];
                NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
                if (i == 0) {
                    [dic setValue:@"CC" forKey:@"cellTitle"];
                }
                else {
                    [dic setValue:@"" forKey:@"cellTitle"];
                }
                [dic setValue:mcoAddress.displayName forKey:@"title"];
                [dic setValue:mcoAddress.mailbox forKey:@"subTitle"];
                [array addObject:dic];
            }
            
            NSArray * bccArray = message.header.bcc;
            for (int i = 0; i<bccArray.count; ++i) {
                mcoAddress = [bccArray objectAtIndex:i];
                NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
                if (i == 0) {
                    [dic setValue:@"BCC" forKey:@"cellTitle"];
                }
                else {
                    [dic setValue:@"" forKey:@"cellTitle"];
                }
                [dic setValue:mcoAddress.displayName forKey:@"title"];
                [dic setValue:mcoAddress.mailbox forKey:@"subTitle"];
                [array addObject:dic];
            }
            
            NSMutableDictionary * dic2 = [[NSMutableDictionary alloc] init];
            [dic2 setValue:@"SUBJECT" forKey:@"cellTitle"];
            [dic2 setValue:message.header.subject forKey:@"title"];
            [dic2 setValue:@"" forKey:@"subTitle"];
            [array addObject:dic2];
            return array;
        }
    }
    return nil;
}
+(BOOL)isDateInFuture:(NSDate *)date1 {
    NSDate * date2 = [NSDate date];
    if ([date1 compare:date2] == NSOrderedDescending) {
        // NSLog(@"date1 is later than date2");
        return YES;
    } else if ([date1 compare:date2] == NSOrderedAscending) {
        //NSLog(@"date1 is earlier than date2");
        return NO;
    } else {
        //NSLog(@"dates are the same");
        return NO;
    }
}

+(BOOL)isDate:(NSDate *)date1 isLatestThanDate:(NSDate *)date2 {
    
    if ([date1 compare:date2] == NSOrderedDescending) {
        // NSLog(@"date1 is later than date2");
        return YES;
    } else if ([date1 compare:date2] == NSOrderedAscending) {
        //NSLog(@"date1 is earlier than date2");
        return NO;
    } else {
        //NSLog(@"dates are the same");
        return NO;
    }
}
+(BOOL)areDaysSameInDates:(NSDate *)date1 date2:(NSDate *)date2 {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date1];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date2];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([today isEqualToDate:otherDate]) {
        //do stuff
        return YES;
    }
    else {
        return NO;
    }
}
+(void)deleteMessageFromServerWithSession:(MCOIMAPSession *)session andObject:(NSManagedObject *)object {
}

+(void)fetchEmailForUniqueId:(uint64_t)mId session:(MCOIMAPSession *)session userId:(NSString *)uid markArchive:(BOOL)mark threadId:(uint64_t)threadId entity:(NSString *)entity {
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:kFOLDER_INBOX expression: [MCOIMAPSearchExpression searchGmailMessageID:mId]];
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        if (error == nil) {
            if (indexSet.count>0) {
                [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:indexSet fromFolder:kFOLDER_INBOX withSessaion:session requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
                    if (error == nil) {
                        if (messages.count>0) {
                            MCOIMAPMessage *msg = [messages lastObject];
                            ModelEmailInfo * info = [[ModelEmailInfo alloc] initWithMessage:msg userId:uid folderName:kFOLDER_INBOX];
                            [CoreDataManager mapEmailInfo:info];
                            
                            if (mark) {
                                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:mId userId:[uid longLongValue]];
                                
                                if (emailInfo.count>0) {
                                    NSManagedObject * infoObject = [emailInfo lastObject];
                                    
                                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                                    
                                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:session destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                                        NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:threadId andUserId: [uid longLongValue] folderType:kFolderAllMail needOnlyIds:NO entity:entity];
                                        
                                        for (NSManagedObject * object in emailIdArray) {
                                            /* change folder name to [Gmail]/All Mail if email belong to INBOX */
                                            NSString * folderName = [object valueForKey:kMAIL_FOLDER];
                                            if ([folderName isEqualToString:kFOLDER_INBOX]) {
                                                [object setValue:kFOLDER_ALL_MAILS forKey:kMAIL_FOLDER];
                                            }
                                            
                                            if (![Utilities emailHasBeenSnoozedRecently:object]) {
                                                [self syncDeleteActionToFirebaseWithObject:object];
                                            }
                                        }
                                    } onError:^( NSError * error) {
                                        NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:threadId andUserId: [uid longLongValue] folderType:kFolderAllMail needOnlyIds:NO entity:entity];
                                        
                                        for (NSManagedObject * objc in emailIdArray) {
                                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
                                            [CoreDataManager updateData];
                                        }
                                        
                                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot Archive Email!" message:@"Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                                        [av show];
                                    }];
                                }
                            }
                        }
                    }
                    else {
                    }
                }onError:^(NSError* error) {
                }];
            }
        }
    }];
}

+(void)updateThreadStatus:(uint64_t)threadId userId:(long)userId {
    NSMutableArray * completeThread = [CoreDataManager fetchSingleThreadForId:threadId userId:userId];
    NSLog(@"Thread id: %llu, user Id: %ld, completeThreadCount: %lu", threadId, userId,(unsigned long)completeThread.count);
    BOOL containInbox = NO;
    BOOL containSent = NO;
    for (NSManagedObject * object in completeThread) { /* check if contain inbox */
        BOOL isInbox = [[object valueForKey:kIS_Inbox_EMAIL] boolValue];
        if (isInbox) {
            containInbox = YES;
        }
        
        BOOL isSent = [[object valueForKey:kIS_SENT_EMAIL] boolValue];
        if (isSent) {
            containSent = YES;
        }
    }
    if (containInbox == NO || containSent == NO) {
        NSLog(@"it is no more conversation");
        for (NSManagedObject * object in completeThread) { /* it is no more conversation */
            [object setValue:[NSNumber numberWithBool:NO] forKey:kIS_CONVERSATION];
        }
    }
    else {
        NSLog(@"still conversation");
    }
    [CoreDataManager updateData];
}
+(void)markSnoozedAndFavorite:(MCOIMAPMessage *)message userId:(long )userId isInboxMail:(BOOL)isInboxMail {
    NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:message.gmailThreadID userId:userId];
    
    BOOL isFavorite = NO;
    NSString * favoriteFireBaseId = nil;
    BOOL isCompleteThreadFavorite = NO;
    for (NSManagedObject * obj in emailArray) {
        if ([[obj valueForKey:kIS_FAVORITE] boolValue]) {
            isFavorite = [[obj valueForKey:kIS_FAVORITE] boolValue];
            favoriteFireBaseId = [obj valueForKey:kFAVORITE_FIREBASE_ID];
            isCompleteThreadFavorite = [[obj valueForKey:kIS_COMPLETE_THREAD_FAVORITE] boolValue];;
            break;
        }
    }
    if ([Utilities isValidString:favoriteFireBaseId]) {
        for (NSManagedObject * obj in emailArray) {
            if (![[obj valueForKey:kIS_FAVORITE] boolValue]) {
                [obj setValue:favoriteFireBaseId forKey:kFAVORITE_FIREBASE_ID];
                
                [obj setValue:[NSNumber numberWithBool:isFavorite] forKey:kIS_FAVORITE];
                [obj setValue:[NSNumber numberWithBool:isCompleteThreadFavorite] forKey:kIS_COMPLETE_THREAD_FAVORITE];
                [CoreDataManager updateData];
            }
        }
    }
    
    if (isInboxMail) {
        /* unmarked snooze if reply has arrive in a thread with
         *only If No One Reply* flag is true */
        for (NSManagedObject * obj in emailArray) {
            if ([[obj valueForKey:kIS_SNOOZED] boolValue]) {
                if ([[obj valueForKey:kSNOOZED_ONLY_IF_NO_REPLY] boolValue]) {
                    NSString * firebaseSnoozedId = [obj valueForKey:kSNOOZED_FIREBASE_ID];
                    long userId = [[obj valueForKey:kUSER_ID] longLongValue];
                    NSString * strUserId = [NSString stringWithFormat:@"%ld", userId];
                    if ([Utilities isValidString:firebaseSnoozedId]) {
                        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:strUserId performAction:kActionDelete firebaseId:firebaseSnoozedId];
                        return;
                    }
                }
            }
        }
    }
    
    /* marked new mail snooze if thread is already marked */
    NSString * snoozedFirebaseKey = nil;
    BOOL isCompleteThreadSnoozed = NO;
    BOOL isSnoozed = NO;
    BOOL onlyIfReply = NO;
    NSDate * date = nil;
    NSDate * snoozedMarkedAt = nil;
    for (NSManagedObject * obj in emailArray) {
        if ([[obj valueForKey:kIS_SNOOZED] boolValue]) {
            
            snoozedFirebaseKey = [obj valueForKey:kSNOOZED_FIREBASE_ID];
            isCompleteThreadSnoozed = [[obj valueForKey:kIS_COMPLETE_THREAD_SNOOZED] boolValue];
            isSnoozed = [[obj valueForKey:kIS_SNOOZED] boolValue];
            onlyIfReply = [[obj valueForKey:kSNOOZED_ONLY_IF_NO_REPLY] boolValue];
            date = (NSDate *)[obj valueForKey:kSNOOZED_DATE];
            snoozedMarkedAt = (NSDate *)[obj valueForKey:kSNOOZED_MARKED_AT];
            break;
        }
    }
    if ([Utilities isValidString:snoozedFirebaseKey]) {
        for (NSManagedObject * obj in emailArray) {
            if (![[obj valueForKey:kIS_SNOOZED] boolValue]) {
                [obj setValue:snoozedFirebaseKey forKey:kSNOOZED_FIREBASE_ID];
                [obj setValue:[NSNumber numberWithBool:isCompleteThreadSnoozed] forKey:kIS_COMPLETE_THREAD_SNOOZED];
                [obj setValue:[NSNumber numberWithBool:isSnoozed] forKey:kIS_SNOOZED];
                [obj setValue:[NSNumber numberWithBool:onlyIfReply] forKey:kSNOOZED_ONLY_IF_NO_REPLY];
                [obj setValue:date forKey:kSNOOZED_DATE];
                [obj setValue:snoozedMarkedAt forKey:kSNOOZED_MARKED_AT];
                [CoreDataManager updateData];
            }
        }
    }
}

+(BOOL)emailHasBeenSnoozedRecently:(NSManagedObject *)object {
    
    BOOL result = FALSE;
    NSDate *snoozeMarkedDate = [object valueForKey:kSNOOZED_MARKED_AT];
    NSDate *currentDate = [NSDate date];
    
    NSTimeInterval timeDiff = currentDate.timeIntervalSince1970 - snoozeMarkedDate.timeIntervalSince1970;
    
    if(timeDiff < 120 ) {
        
        result = TRUE;
    }
    
    return result;
}


+(NSString *)getDeviceIdentifier {
    //kUNIQUE_IDENTIFIER
    NSString* uniqueIdentifier = [Utilities getUserDefaultWithValueForKey:kUNIQUE_IDENTIFIER];
    if (uniqueIdentifier == nil) {
        uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; // IOS 6+
        [Utilities setUserDefaultWithValue:uniqueIdentifier andKey:kUNIQUE_IDENTIFIER];
    }
    return uniqueIdentifier;
}
+(int)getFolderTypeForString:(NSString*)name {
    if ([name isEqualToString:kFOLDER_INBOX]) {
        return kFolderInboxMail;
    }
    else if ([name isEqualToString:kFOLDER_ALL_MAILS]){
        return kFolderAllMail;
    }
    else if ([name isEqualToString:kFOLDER_SENT_MAILS]){
        return kFolderSentMail;
    }
    else if ([name isEqualToString:kFOLDER_DRAFT_MAILS]){
        return kFolderDraftMail;
    }
    else if ([name isEqualToString:kFOLDER_TRASH_MAILS]){
        return kFolderTrashMail;
    }
    return -1;
}
+(NSString *)getImageNameForMimeType:(NSString *)mime {
    NSLog(@"mime: %@",mime);
    NSString * img = @"anyfile";
    if ([mime isEqualToString:@"application/rtf"]) {
        img = @"rtf_file";
    }
    else if ([mime isEqualToString:@"image/png"] || [mime isEqualToString:@"image/jpeg"] || [mime isEqualToString:@"image/jpg"]) {
        img = @"photo_icon";
    }
    else if ([mime isEqualToString:@"application/json"]) {
        img = @"json_file";
    }
    else if ([mime isEqualToString:@"application/zip"]) {
        img = @"file_attach_1";
    }
    else if ([mime isEqualToString:@"application/photoshop"]) {
        img = @"file_attach_2";
    }
    else if ([mime isEqualToString:@"application/pdf"]) {
        img = @"pdf_file";
    }
    else if ([mime isEqualToString:@"application/msword"] || [mime isEqualToString:@"application/vnd.openxmlformats-officedocument.wordprocessingml.document"]) {
        img = @"file_attach_3";
        
    }
    else if ([mime isEqualToString:@"text/plain"]) {
        img = @"txt_file";
    }
    return img;
}
+(long)getInboxLastFetchCount:(NSString *)user {
    NSString * key = [NSString stringWithFormat:@"%@%@",kFETCH_COUNT,user];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getInboxLastFetchCount = %ld",countw );
        return countw;
        
    }
    else { //first log_in
        NSLog(@"getInboxLastFetchCount = %d",0 );
        return 0;
    }
}

+(void)updateInboxLastFetchCount:(long)fetchCount userId:(NSString *)user {
    NSString * key = [NSString stringWithFormat:@"%@%@",kFETCH_COUNT,user];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount + countw] andKey:key];
    }
    else { //first log_in
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
    }
}
+(long)getTrashLastFetchCountForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kTRASH_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getTrashLastFetchCount = %ld",countw );
        return countw;
        
    }
    else { //first log_in
        NSLog(@"getTrashLastFetchCount = %d",0 );
        return 0;
    }
}
+(void)updateTrashLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kTRASH_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        if (fetchCount>0) {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount + countw] andKey:key];
        }
        else if (fetchCount == 0) {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
        }
        else {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld", countw + fetchCount] andKey:key];
        }
    }
    else { //first log_in
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
    }
}
+(long)getSentLastFetchCountForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kSENT_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getSentLastFetchCountForUser = %ld",countw );
        return countw;
        
    }
    else { //first log_in
        NSLog(@"getSentLastFetchCountForUser = %d",0 );
        return 0;
    }
}
+(void)updateSentLastFetchCount:(long)fetchCount  forUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kSENT_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        if (fetchCount>0) {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount + countw] andKey:key];
        }
        else if (fetchCount == 0) {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
        }
        else {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",countw + fetchCount] andKey:key];
        }
    }
    else { //first log_in
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
    }
}
+(long)getArchiveLastFetchCountForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kARCHIVE_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getArchiveLastFetchCount = %ld",countw );
        return countw;
        
    }
    else { //first log_in
        NSLog(@"getArchiveLastFetchCount = %d",0 );
        return 0;
    }
}
+(void)updateArchiveLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kARCHIVE_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount + countw] andKey:key];
    }
    else { //first log_in
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
    }
}

+(long)getDarftLastFetchCountForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kDRAFT_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getDarftLastFetchCount = %ld",countw );
        return countw;
        
    }
    else { //first log_in
        NSLog(@"getDarftLastFetchCount = %d",0 );
        return 0;
    }
}
+(void)updateDarftLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId {
    NSString * key = [NSString stringWithFormat:@"%@%@",kDRAFT_FETCH_COUNT,userId];
    NSString * count = [self getUserDefaultWithValueForKey:key];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        if (fetchCount>0) {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount + countw] andKey:key];
        }
        else if (fetchCount == 0){
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
        }
        else {
            [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",countw + fetchCount] andKey:key];
        }
        
    }
    else { //first log_in
        [self setUserDefaultWithValue:[NSString stringWithFormat:@"%ld",fetchCount] andKey:key];
    }
}
+(long)getFakeDraftId {
    NSString * count = [self getUserDefaultWithValueForKey:kIS_FAKE_DRAFT];
    if ([self isValidString:count]) { // incremnet key and save it
        long countw = [count longLongValue];
        NSLog(@"getArchiveLastFetchCount = %ld",countw );
        long newId = countw + 1;
        [self setUserDefaultWithValue:[self getStringFromLong:newId] andKey:kIS_FAKE_DRAFT];
        return countw;
    }
    else { //first log_in
        NSLog(@"getArchiveLastFetchCount = %d",1 );
        [self setUserDefaultWithValue:[self getStringFromLong:2] andKey:kIS_FAKE_DRAFT];
        return 1;
    }
}
+(BOOL) NSStringIsValidEmail:(NSString *)checkString {
    //BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    //NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    //NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&amp;'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&amp;'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    
    //NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
+(BOOL)isInternetActive {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if (remoteHostStatus != NotReachable) {
        // do work here if the user has a valid connection
        return YES;
    }
    else {
        return NO;
    }
}
+(NSString *)getEmailForId:(NSString *)uid {
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[uid longLongValue]];
    if (userArray.count == 0) {
        return nil;
    }
    NSManagedObject * object = [userArray lastObject];
    
    return [object valueForKey:kUSER_EMAIL];
}
+(NSString *)getStringFromInt:(int)value {
    return [NSString stringWithFormat:@"%d",value];
}
+(NSString *)getStringFromLong:(long)value {
    return [NSString stringWithFormat:@"%ld",value];
}
+(NSArray *)getIndexSetFromObject:(NSManagedObject *)object {
    MCOIndexSet * indexSet = [[MCOIndexSet alloc] init];
    NSString * folderName  = [object valueForKey:kMAIL_FOLDER];
    //    NSString * userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    //    NSString * threadId = [object valueForKey:kEMAIL_THREAD_ID];
    //    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[threadId longLongValue] andUserId: [userId longLongValue] folderType:[Utilities getFolderTypeForString:folderName] needOnlyIds:NO isSnoozed:NO];
    
    
    //    if (emailIdArray.count>1) {
    //
    //        for (int i = 0; i< emailIdArray.count; i++) {
    //            long ids = [[[emailIdArray objectAtIndex:i] objectForKey:kEMAIL_ID] longLongValue];
    //            NSLog(@"folder = %@", [[emailIdArray objectAtIndex:i] valueForKey:kMAIL_FOLDER]);
    //            [indexSet addIndex:ids];
    //        }
    //    }
    //    else {
    [indexSet addIndex:[[object valueForKey:kEMAIL_ID] longLongValue]];
    //    }
    return [[NSArray alloc] initWithObjects:folderName,indexSet, nil];
}
+(void)destroyImapSession:(MCOIMAPSession *)session {
    if (session!=nil) {
        MCOIMAPOperation * op = [session disconnectOperation];
        [op start:^(NSError * error) {
            if (error == nil) {
                // NSLog(@"IMAP Session destroyed");
            }
            else {
                NSLog(@"Error while destroying IMAP Session");
            }
        }];
    }
}
/*+(void)saveNewIdsInDBWithDictionary:(NSDictionary *)dictionary isDraft:(BOOL)isDraft isArchive:(BOOL)isArchive isDeleted:(BOOL)isDeleted forThreadId:(uint64_t)threadId userId:(long)userId folderName:(NSString*)folderName {
 NSMutableArray * dataArray = [CoreDataManager fetchEmailsForThreadId:threadId andUserId:userId folderType:kFolderAllMail needOnlyIds:NO isSnoozed:NO];
 for (int i = 0; i < [dictionary count]; ++i) {
 if (dataArray.count <= [dictionary count]) {
 NSManagedObject * object = [dataArray objectAtIndex:i];
 NSString * oldId = [object valueForKey:kEMAIL_ID];
 long newId = [[dictionary objectForKey:oldId] longLongValue];
 [object setValue:[NSNumber numberWithLong:newId] forKey:kEMAIL_ID];
 [object setValue:[NSNumber numberWithBool:isDeleted] forKey:kIS_TRASH_EMAIL];
 [object setValue:[NSNumber numberWithBool:isArchive] forKey:kIS_ARCHIVE];
 [object setValue:[NSNumber numberWithBool:NO] forKey:kIS_FAVORITE];
 [object setValue:folderName forKey:kMAIL_FOLDER];
 [CoreDataManager updateData];
 }
 }
 }*/
+(MCOIMAPMessagesRequestKind)getImapRequestKind {
    MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
    (MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
     MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
     MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindGmailThreadID | MCOIMAPMessagesRequestKindGmailMessageID );
    return requestKind;
}
+(void)saveContacts {
    [CoreDataManager mapContactData:0 title:kBCC name:@""];
    [CoreDataManager mapContactData:0 title:kCC name:@""];
}
//+(void)saveArchiceIdsInDBWithIndexSet:(MCOIndexSet *)indexSet isDraft:(BOOL)isDraft isArchive:(BOOL)isArchive isDeleted:(BOOL)isDeleted forThreadId:(uint64_t)threadId userId:(long)userId folderName:(NSString*)folderName {
//    NSMutableArray * dataArray = [CoreDataManager fetchEmailsForThreadId:threadId andUserId:userId folderType:kFolderAllMail needOnlyIds:NO isSnoozed:NO];
//    for (int i = 0; i < [indexSet count]; ++i) {
//        if (dataArray.count <= [indexSet count]) {
//            NSManagedObject * object = [dataArray objectAtIndex:i];
//            //NSString * oldId = [object valueForKey:kEMAIL_ID];
//            //long newId = [[dictionary objectForKey:oldId] longLongValue];
//            //[object setValue:[NSNumber numberWithLong:newId] forKey:kEMAIL_ID];
//            [object setValue:[NSNumber numberWithBool:isDeleted] forKey:kIS_TRASH_EMAIL];
//            [object setValue:[NSNumber numberWithBool:isArchive] forKey:kIS_ARCHIVE];
//            [object setValue:folderName forKey:kMAIL_FOLDER];
//            [CoreDataManager updateData];
//        }
//    }
//}
+(NSString *)encodeToBase64:(NSString*)plainString {
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    /*NSLog(@"base64EmailString: %@", base64String);*/ // Zm9v
    return base64String;
}
+(void)syncToFirebase:(NSMutableDictionary *)data syncType:(id)type userId:(NSString *)uid performAction:(int)action firebaseId:(NSString *)firebaseId {
    NSMutableDictionary * dictionary = [[SharedInstanceManager sharedInstance] firebaseSharedInstance];
    if (dictionary != nil) {
        NSMutableArray * dataArray = [dictionary objectForKey:[NSString stringWithFormat:@"%@",uid]];
        if (dataArray != nil) {
            for (id instanceData in dataArray) {
                if ([instanceData isKindOfClass:[type class]]) {
                    [Utilities composeData:data userId:uid classType:instanceData performAction:action firebaseId:firebaseId];
                    break;
                }
            }
        }
    }
}
+(void)composeData:(NSMutableDictionary *)data userId:(NSString *)uid classType:(id)classType performAction:(int)action firebaseId:(NSString *)firebaseId {
    
    if ([classType isKindOfClass:[FavoriteEmailSyncManager class]]) {
        FavoriteEmailSyncManager * favoriteEmailSyncManager = (FavoriteEmailSyncManager *)classType;
        if (action == kActionInsert) {
            [favoriteEmailSyncManager pushDataToFirebase:data];
        }
        else if (action == kActionDelete) {
            [favoriteEmailSyncManager deleteFavoriteEmailForFirebaseId:firebaseId];
        }
        else if (action == kActionEdit) {
            [favoriteEmailSyncManager editFavoriteEmailForFirebaseId:firebaseId data:data];
        }
    }
    else if ([classType isKindOfClass:[QuickResponseSyncManager class]]) {
        QuickResponseSyncManager * quickResponseSyncManager = (QuickResponseSyncManager *)classType;
        if (action == kActionInsert) {
            [quickResponseSyncManager pushDataToFirebase:data];
        }
        else if (action == kActionDelete) {
            [quickResponseSyncManager deleteQuickResponseForFirebaseId:firebaseId];
        }
        else if (action == kActionEdit) {
            [quickResponseSyncManager editQuickResponseForFirebaseId:firebaseId data:data];
        }
        else if (action == kActionOnce) {
            [quickResponseSyncManager pushOneTimeLog:data];
        }
        else  if (action == kActionInsertAttachment) {
            [quickResponseSyncManager uploadImageToFirebaseStorage:data];
        }
        else  if (action == kActionDeleteAttachment) {
            [quickResponseSyncManager deleteFirebaseStorage:data];
        }
    }
    else if ([classType isKindOfClass:[SendLaterSyncManager class]]) {
        SendLaterSyncManager * sendLaterSyncManager = (SendLaterSyncManager *)classType;
        if (action == kActionInsert) {
            [sendLaterSyncManager pushDataToFirebase:data];
        }
        else if (action == kActionDelete) {
            [sendLaterSyncManager deleteSendLaterPreferenceForFirebaseId:firebaseId];
        }
        else if (action == kActionEdit) {
            [sendLaterSyncManager editSendLaterPreferenceForFirebaseId:firebaseId data:data];
        }
        else if (action == kActionOnce) {
            [sendLaterSyncManager pushOneTimeLog:data];
        }
    }
    else if ([classType isKindOfClass:[SnoozeEmailSyncManager class]]) {
        SnoozeEmailSyncManager * snoozeEmailSyncManager = (SnoozeEmailSyncManager *)classType;
        if (action == kActionInsert) {
            [snoozeEmailSyncManager pushDataToFirebase:data];
        }
        else if (action == kActionDelete) {
            [snoozeEmailSyncManager deleteSnoozeEmailForFirebaseId:firebaseId];
        }
        else if (action == kActionEdit) {
            [snoozeEmailSyncManager editSnoozeEmailForFirebaseId:firebaseId data:data];
        }
    }
    else if ([classType isKindOfClass:[SnoozePreferenceManager class]]) {
        SnoozePreferenceManager * snoozePreferenceManager = (SnoozePreferenceManager *)classType;
        if (action == kActionInsert) {
            [snoozePreferenceManager pushDataToFirebase:data];
        }
        else if (action == kActionDelete) {
            [snoozePreferenceManager deleteSnoozePreferenceForFirebaseId:firebaseId];
        }
        else if (action == kActionEdit) {
            [snoozePreferenceManager editSnoozePreferenceForFirebaseId:firebaseId data:data];
        }
        else if (action == kActionOnce) {
            [snoozePreferenceManager pushOneTimeLog:data];
        }
    }
}
+(void)editQuickReponseWithObject:(NSManagedObject *)obj {
    ComposeQuickResponseViewController * composeQuickResponseViewController = [[ComposeQuickResponseViewController alloc] initWithNibName:@"ComposeQuickResponseViewController" bundle:nil];
    composeQuickResponseViewController.object = obj;
    [self pushViewController:composeQuickResponseViewController animated:YES];
}
+(NSMutableDictionary *)getDictionaryFromObject:(NSManagedObject *)object email:(NSString *)email isThread:(BOOL)isThread dictionaryType:(int)type nsdate:(double)date {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[object valueForKey:kMAIL_FOLDER] forKey:kMAIL_FOLDER];
    [dictionary setObject:[object valueForKey:kEMAIL_ID] forKey:kEMAIL_ID];
    [dictionary setObject:[object valueForKey:kEMAIL_THREAD_ID] forKey:kEMAIL_THREAD_ID];
    [dictionary setObject:[object valueForKey:kEMAIL_UNIQUE_ID] forKey:kEMAIL_UNIQUE_ID];
    [dictionary setObject:email forKey:kUSER_EMAIL];
    [dictionary setObject:[NSNumber numberWithBool:isThread] forKey:kMARK_COMPLETE_THREAD];
    if (type == kTypeSnoozed) {
        [dictionary setObject:[NSString stringWithFormat:@"%f",date] forKey:kSNOOZED_DATE];
        [dictionary setObject:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey:kSNOOZED_MARKED_AT];
    }
    return dictionary;
}
+(void)startFirebaseForUserId:(NSString *)uid email:(NSString *)email {
    NSString * encodedEmail = [Utilities encodeToBase64:email];
    FavoriteEmailSyncManager * favoriteEmailSyncManager = [[FavoriteEmailSyncManager alloc] initWithEmail:encodedEmail userId:uid];
    QuickResponseSyncManager * quickResponseSyncManager = [[QuickResponseSyncManager alloc] initWithEmail:encodedEmail userId:uid];
    SnoozeEmailSyncManager * snoozeEmailSyncManager = [[SnoozeEmailSyncManager alloc] initWithEmail:encodedEmail userId:uid];
    SendLaterSyncManager * sendLaterSyncManager = [[SendLaterSyncManager alloc] initWithEmail:encodedEmail userId:uid];
    //[[SharedInstanceManager sharedInstance].firebaseSharedInstance setObject:[[NSMutableArray alloc] initWithObjects:favoriteEmailSyncManager,quickResponseSyncManager,snoozeEmailSyncManager,sendLaterSyncManager, nil] forKey:uid];
    SnoozePreferenceManager * snoozePreferenceManager = [[SnoozePreferenceManager alloc] initWithEmail:encodedEmail userId:uid];
    [[SharedInstanceManager sharedInstance].firebaseSharedInstance setObject:[[NSMutableArray alloc] initWithObjects:favoriteEmailSyncManager,quickResponseSyncManager,snoozeEmailSyncManager,sendLaterSyncManager,snoozePreferenceManager, nil] forKey:uid];
}
+(void)preloadSendLaterPreferencesForEmail:(NSString *)email andUserId:(NSString *)uid saveLocally:(BOOL)locally {
    NSError* err = nil;
    NSString* dataPath = [[NSBundle mainBundle] pathForResource:@"PreloadSendLaterPreference" ofType:@"json"];
    NSArray* snoozePreference = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                                options:kNilOptions
                                                                  error:&err];
    
    NSMutableArray *sendlaterarray = [CoreDataManager fetchSendlaterPreferencesForBool:NO emailId:email];
    for (NSManagedObject *object in sendlaterarray) {
        [CoreDataManager deleteObject:object];
    }
    
    for (NSMutableDictionary * dataDictionary in snoozePreference) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:dataDictionary];
        [dictionary setObject:email forKey:kUSER_EMAIL];
        if (locally) {
            [CoreDataManager saveSendLaterPreferencesWithData:dictionary];
        }
        else {
            [Utilities syncToFirebase:dictionary syncType:[SendLaterSyncManager class] userId:uid performAction:kActionInsert firebaseId:nil];
        }
    }
}
+(void)preloadSnoozePreferencesForEmail:(NSString *)email andUserId:(NSString *)uid saveLocally:(BOOL)locally {
    NSError* err = nil;
    NSString* dataPath = [[NSBundle mainBundle] pathForResource:@"PreloadSnoozePreference" ofType:@"json"];
    NSArray* snoozePreference = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                                options:kNilOptions
                                                                  error:&err];
    
    NSMutableArray *snoozearray = [CoreDataManager fetchSnoozePreferencesForBool:NO emailId:email];
    for (NSManagedObject *object in snoozearray) {
        [CoreDataManager deleteObject:object];
    }
    
    for (NSMutableDictionary * dataDictionary in snoozePreference) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:dataDictionary];
        
        [dictionary setObject:email forKey:kUSER_EMAIL];
        if (locally) {
            [CoreDataManager saveSnoozePreferencesWithData:dictionary];
        }
        else {
            [Utilities syncToFirebase:dictionary syncType:[SnoozePreferenceManager class] userId:uid performAction:kActionInsert firebaseId:nil];
        }
    }
}

+(void)setEmailToSnoozeTill:(NSDate *)date withObject:(NSManagedObject *)selectedMailData currentEmail:(NSString *)currentEmail onlyIfNoReply:(BOOL)snoozedOnlyIfNoReply userId:(NSString *)uid {
    
    NSMutableDictionary * dictionary = [Utilities getDictionaryFromObject:selectedMailData email:currentEmail isThread:YES dictionaryType:kTypeSnoozed nsdate:date.timeIntervalSince1970];
    [dictionary setObject:[NSNumber numberWithBool:snoozedOnlyIfNoReply] forKey:kSNOOZED_ONLY_IF_NO_REPLY];
    /* if it is already snoozed
     than just edit its time and sync to firebase */
    if ([[selectedMailData valueForKey:kIS_SNOOZED] boolValue]) {
        NSString * firebaseId = [selectedMailData valueForKey:kSNOOZED_FIREBASE_ID];
        [Utilities syncToFirebase:dictionary syncType:[SnoozeEmailSyncManager class] userId:uid performAction:kActionEdit firebaseId:firebaseId];
    }
    else {
        [Utilities syncToFirebase:dictionary syncType:[SnoozeEmailSyncManager class] userId:uid performAction:kActionInsert firebaseId:nil];
    }
}
+(NSDate *)calculateDateWithHours:(int)hour minutes:(int)minutes preferenceId:(int)preferenceId currentEmail:(NSString *)currentEmail userId:(NSString *)userId emailData:(NSManagedObject *)selectedMailData onlyIfNoReply:(BOOL)snoozedOnlyIfNoReply viewType:(int)viewType {
    if (viewType == 3) {
        if (preferenceId == 1) { /* after one hour today */
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setHour:hour];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
            
            /* get 12 AM At night below */
            NSDate *const date = NSDate.date;
            NSCalendar *const calendar1 = NSCalendar.currentCalendar;
            NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
            NSDateComponents *const components = [calendar1 components:preservedComponents fromDate:date];
            components.day = components.day+1;
            NSDate *const normalizedDate = [calendar1 dateFromComponents:components];
            
            BOOL is = [Utilities isDate:newDate isLatestThanDate:normalizedDate];
            if (!is) {
                return newDate;
            }
            else {
                return normalizedDate;
            }
        }
        else if(preferenceId == 2) { /* tomorrow @ 08:00 AM */
            NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:1 hour:hour minute:minutes];
            return date;
        }
        else if(preferenceId == 3) { /* monday @ 08:00 AM */
            NSDate * date = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:2] day:0 hour:hour minute:minutes];
            NSDate * currentDate = [NSDate date];
            
            /* first check if date is in future
             if ture than set notification
             else check if days are equal with today
             */
            
            BOOL is = [Utilities isDate:currentDate isLatestThanDate:date];
            if (is) {
                BOOL dateAreSameInDate = [Utilities areDaysSameInDates:currentDate date2:date];
                if (dateAreSameInDate) {
                    /* if days are equal than add 7 days and set notitfication */
                    NSDate * date1 = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:1] day:7 hour:hour minute:minutes];
                    return date1;
                }
            }
            else {
                return date;
            }
        }
        else if(preferenceId == 4) { /* in one week */
            NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:7 hour:hour minute:minutes];
            return date;
        }
        else if(preferenceId == 5) { /* in 3 days */
            NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:3 hour:hour minute:minutes];
            return date;
        }
        return nil;
    }
    if (preferenceId == 1) { /* later today */
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setHour:hour];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
        
        /* get 12 AM At night below */
        NSDate *const date = NSDate.date;
        NSCalendar *const calendar1 = NSCalendar.currentCalendar;
        NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
        NSDateComponents *const components = [calendar1 components:preservedComponents fromDate:date];
        components.day = components.day+1;
        NSDate *const normalizedDate = [calendar1 dateFromComponents:components];
        
        BOOL is = [Utilities isDate:newDate isLatestThanDate:normalizedDate];
        if (!is) {
            [Utilities setEmailToSnoozeTill:newDate withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
        }
        else {
            [Utilities setEmailToSnoozeTill:normalizedDate withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
        }
    }
    else if(preferenceId == 2) { /* this evening */
        NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:0 hour:hour minute:minutes];
        
        
        BOOL is = [Utilities isDate:[NSDate date] isLatestThanDate:date];
        if (is) {
            return nil;
        }
        [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
    }
    else if(preferenceId == 3) { /* tomorrow */
        NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:1 hour:hour minute:minutes];
        [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
    }
    else if(preferenceId == 4) {/* tomorrow eve */
        NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:1 hour:hour minute:minutes];
        [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
    }
    else if(preferenceId == 5) {/* weekend */
        NSDate * date = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:1] day:0 hour:hour minute:minutes];
        NSDate * currentDate = [NSDate date];
        
        /* first check if date is in future
         if ture than set notification
         else check if days are equal with today
         */
        
        BOOL is = [Utilities isDate:currentDate isLatestThanDate:date];
        if (is) {
            BOOL dateAreSameInDate = [Utilities areDaysSameInDates:currentDate date2:date];
            if (dateAreSameInDate) {
                /* if days are equal than add 7 days and set notitfication */
                NSDate * date1 = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:1] day:7 hour:hour minute:minutes];
                [Utilities setEmailToSnoozeTill:date1 withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
            }
        }
        else {
            [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
        }
    }
    else if(preferenceId == 6) { /* next week */
        NSDate * date = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:2] day:0 hour:hour minute:minutes];
        NSDate * currentDate = [NSDate date];
        
        /* first check if date is in future
         if ture than set notification
         else check if days are equal with today
         */
        BOOL is = [Utilities isDate:currentDate isLatestThanDate:date];
        if (is) {
            BOOL dateAreSameInDate = [Utilities areDaysSameInDates:currentDate date2:date];
            if (dateAreSameInDate) {
                /* if days are equal than add 7 days and set notitfication */
                NSDate * date1 = [Utilities addComponentsToDate:[Utilities getDateOfSpecificDay:2] day:7 hour:hour minute:minutes];
                [Utilities setEmailToSnoozeTill:date1 withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
            }
        }
        else {
            [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
        }
    }
    else if(preferenceId == 7) { /* in a month */
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setMonth:1];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
        
        NSDate * date = [Utilities addComponentsToDate:newDate day:0 hour:hour minute:minutes];
        [Utilities setEmailToSnoozeTill:date withObject:selectedMailData currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
        
    }
    else if(preferenceId == 8) { /*Some day*/
        
    }
    return nil;
}
+(void)preloadQuickResponsesForEmail:(NSString *)email andUserId:(NSString *)uid {
    NSError* err = nil;
    NSString* dataPath = [[NSBundle mainBundle] pathForResource:@"PreloadQuickResponse" ofType:@"json"];
    NSArray* quickResponses = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                              options:kNilOptions
                                                                error:&err];
    for (NSMutableDictionary * dataDictionary in quickResponses) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:dataDictionary];
        
        [dictionary setObject:email forKey:kUSER_EMAIL];
        [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:uid performAction:kActionInsert firebaseId:nil];
    }
}

+(NSDate *)addComponentsToDate:(NSDate *)date day:(int)day hour:(int)hour minute:(int)minute {
    NSDateComponents *components1 = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekOfMonth) fromDate:date];
    if (day>0) {
        components1.day = components1.day+day;
    }
    [components1 setHour:hour];
    [components1 setMinute:minute];
    return [[NSCalendar currentCalendar] dateFromComponents:components1];
}
+(NSDate *) getDateOfSpecificDay:(NSInteger ) day /// here day will be 1 or 2.. or 7
{
    NSInteger desiredWeekday = day;
    NSRange weekDateRange = [[NSCalendar currentCalendar] maximumRangeOfUnit:NSCalendarUnitWeekday];
    NSInteger daysInWeek = weekDateRange.length - weekDateRange.location + 1;
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSInteger currentWeekday = dateComponents.weekday;
    NSInteger differenceDays = (desiredWeekday - currentWeekday + daysInWeek) % daysInWeek;
    NSDateComponents *daysComponents = [[NSDateComponents alloc] init];
    daysComponents.day = differenceDays;
    [daysComponents setHour:0];
    [daysComponents setMinute:0];
    
    NSDate *resultDate = [[NSCalendar currentCalendar] dateByAddingComponents:daysComponents toDate:[NSDate date] options:0];
    return resultDate;
}
+(NSData*)getArchivedArray:(id)data {
    return [NSKeyedArchiver archivedDataWithRootObject:data];
}
+(id)getUnArchivedArrayForObject:(id)object {
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:object];
}
+(NSDate *)resetTimeForGivenDate:(NSDate *)date hours:(int)hours minutes:(int)minutes seconds:(int)seconds {
    //gather current calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    //gather date components from date
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    
    //set date components
    [dateComponents setHour:hours];
    [dateComponents setMinute:minutes];
    [dateComponents setSecond:seconds];
    
    //return date relative from date
    return [calendar dateFromComponents:dateComponents];
}
+(BOOL)isThreadContainConversation:(NSArray *)threadMessages forCurrentLoginMail:(NSString *) currentLoginMailAddress {
    BOOL isContainConversation = NO;
    
    
    BOOL isThreadContainMyMessages = NO;
    BOOL isThreadContainOtherSenderMessages = NO;
    for (int x = 0; x < threadMessages.count; ++x) {
        /* this loop will iterate once and
         determine that thread has any other
         email in it other than sent */
        
        MCOIMAPMessage* threadMessage = [threadMessages objectAtIndex:x];
        NSString * senderMail = threadMessage.header.sender.mailbox;
        if ([senderMail isEqualToString:currentLoginMailAddress]) {
            /* this flag will mark whole thread
             as conversation even it has only one
             sent message */
            isThreadContainMyMessages = YES;
            if (isThreadContainMyMessages && isThreadContainOtherSenderMessages) {
                break;
            }
            
        }
        else {
            isThreadContainOtherSenderMessages = YES;
            if (isThreadContainMyMessages && isThreadContainOtherSenderMessages) {
                break;
            }
        }
    }
    
    if (isThreadContainMyMessages && isThreadContainOtherSenderMessages) {
        isContainConversation = YES;
    }
    return isContainConversation;
}

+(void)btnSwipeDeleteActionAtIndexPath:(NSManagedObject *)object isSnoozed:(BOOL)isSnoozed {
    
    if (![self isInternetActive]) {
        return;
    }
    uint64_t threadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:threadId andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:isSnoozed entity:[object entity].name];
    
    for (NSManagedObject * obj in emailIdArray) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        
        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
        NSString * entity = [obj entity].name;
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:kFOLDER_TRASH_MAILS completionBlock:^(id response) {
                
                NSIndexSet * ind = indexSet.nsIndexSet;
                uint64_t emailUid = ind.firstIndex;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:emailUid userId:usrId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [self syncDeleteActionToFirebaseWithObject:object];
                    [CoreDataManager deleteObject:object];
                    [CoreDataManager updateData];
                }
                
            } onError:^( NSError * error) {
                NSIndexSet * ind = indexSet.nsIndexSet;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:ind.firstIndex userId:usrId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [object setValue:[NSNumber numberWithBool:NO] forKey:kIS_TRASH_EMAIL];
                    [CoreDataManager updateData];
                }
            }];
        }
    }
}

+(void)btnSwipeArchiveActionAtIndexPath:(NSManagedObject *)object {
    if (![Utilities isInternetActive]) {
        return;
    }
    NSString * strThreadId = [object valueForKey:kEMAIL_THREAD_ID];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSEntityDescription * des = [object entity];
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
    
    for (NSManagedObject * obj in emailIdArray) {
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[strThreadId longLongValue] entity:des.name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:usrId];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        
                        if (response != nil) {
                        }
                    } onError:^( NSError * error) {
                        for (NSManagedObject * objc in emailIdArray) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
                            [CoreDataManager updateData];
                        }
                        
                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot Archive Email!" message:@"Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [av show];
                    }];
                }
            }
        }
    }
}

+(void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object {
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * firebaseFavoriteId = [object valueForKey:kFAVORITE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseFavoriteId]) {
        [Utilities syncToFirebase:nil syncType:[FavoriteEmailSyncManager class] userId:strUid performAction:kActionDelete firebaseId:[object valueForKey:kFAVORITE_FIREBASE_ID]];
    }
    
    NSString * firebaseSnoozedId = [object valueForKey:kSNOOZED_FIREBASE_ID];
    if ([Utilities isValidString:firebaseSnoozedId]) {
        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:strUid performAction:kActionDelete firebaseId:[object valueForKey:kSNOOZED_FIREBASE_ID]];
    }
}
+(NSArray *)getAttachmentListFromPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:fileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:attachmentPath];
    if (fileExists) {
        NSData * data = [NSData dataWithContentsOfFile:attachmentPath];
        MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
        return messageParser.attachments;
    }
    else{
        return nil;
    }
}
+(void)removeFilesFromPaths:(NSMutableArray *)paths {
    for (NSString * fileName in paths) {
        NSLog(@"fileName %@",fileName);
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *saveDirectory = [docPaths objectAtIndex:0];
        NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:attachmentPath error:NULL];
    }
}
+ (NSString *)mimeTypeForData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @".jpeg";
            break;
        case 0x89:
            return @".png";
            break;
        case 0x47:
            return @".gif";
            break;
        case 0x49:
        case 0x4D:
            return @".tiff";
            break;
        case 0x25:
            return @".pdf";
            break;
        case 0xD0:
            return @".vnd";
            break;
        case 0x46:
            return @".plain";
            break;
        default:
            return @".octet-stream";
    }
    return nil;
}
+(NSMutableArray *)saveAttachmentsToTempPath:(NSMutableArray *)attachments {
    NSMutableArray * paths = [[NSMutableArray alloc] init];
    NSString *fileName = nil;
    for (int i = 0; i<attachments.count; ++i) {
        id obj = [attachments objectAtIndex:i];
        NSData * data = nil;
        if ([obj isKindOfClass:[NSData class]]) {
            data = [attachments objectAtIndex:i];
            fileName = [NSString stringWithFormat:@"Attachment_%d%@",i+1,[self mimeTypeForData:data]];
        }
        else {
            MCOAttachment * attachment = (MCOAttachment*)[attachments objectAtIndex:i];
            fileName = attachment.filename;
            data = attachment.data;
        }
        
        NSLog(@"fileName %@",fileName);
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *saveDirectory = [docPaths objectAtIndex:0];
        NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:fileName];

        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:attachmentPath];
        if (fileExists) {
            NSLog(@"File already exists!");
            [[NSFileManager defaultManager] removeItemAtPath:attachmentPath error:NULL];
            [data writeToFile:attachmentPath atomically:YES];
        }
        else{
            NSLog(@"Writing fileeee: %@",attachmentPath);
            [data writeToFile:attachmentPath atomically:YES];
        }
        [paths addObject:fileName];
//        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
//        NSURL *fileURL = [tmpDirURL URLByAppendingPathComponent:attachment.filename];
//        NSString *path= fileURL.absoluteString;
//        NSError *error;
//        [[NSFileManager defaultManager] createDirectoryAtURL: fileURL withIntermediateDirectories:NO attributes:nil error:&error];
//        if (error != nil) {
//            NSLog(@"error: %@",error.description);
//            return nil;
//        }
//        [attachment.data writeToFile:path options:NSDataWritingAtomic error:&error];
//        [paths addObject:fileURL];
    }
    return paths;
}
+ (void)clearTmpDirectory {
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}
+(void)reloadTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation {
    NSLog(@"CALL reload");
    [tableView beginUpdates];
    [tableView reloadRowsAtIndexPaths:indexArray withRowAnimation:animation];
    [tableView endUpdates];
}
+(void)removeTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation {
    NSLog(@"CALL remove");
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:indexArray withRowAnimation:animation];
    [tableView endUpdates];
}
+(void)insertTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation {
    NSLog(@"CALL insert");
    [tableView beginUpdates];
    [tableView insertRowsAtIndexPaths:indexArray withRowAnimation:animation];
    [tableView endUpdates];
}

+ (void) reloadSection:(NSInteger)section forTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)rowAnimation {
    NSLog(@"CALL reloadSection");
    NSRange range = NSMakeRange(section, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [tableView reloadSections:sectionToReload withRowAnimation:rowAnimation];
}

+ (UIImage *) createImageWithText:(NSString *) text andColor:(UIColor *) color
{
    UIImageView *imgVew = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 97, 97)];
    [imgVew setImageWithString:text color:color circular:false textAttributes:@{
                                                                                NSFontAttributeName:[UIFont systemFontOfSize:22.0],
                                                                                NSForegroundColorAttributeName: [UIColor whiteColor]
                                                                                }];
    
    return imgVew.image;
}

+(void) addEmail:(ModelEmail *) email forEntity:(NSString *) entity
{
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [delegate addEmail:email forEntity:entity];
    
}

@end
