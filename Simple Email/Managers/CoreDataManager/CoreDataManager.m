//
//  CoreDataManager.m
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "Utilities.h"
@implementation CoreDataManager

+ (NSManagedObjectContext *)getManagedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

+ (NSManagedObjectContext *)getManagedObjectContextToSave {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

+ (NSPersistentStoreCoordinator *)getPersistentStoreCoordinator {
    NSPersistentStoreCoordinator *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(persistentStoreCoordinator)]) {
        context = [delegate persistentStoreCoordinator];
    }
    return context;
}

+(void)mapNewUserDataWithModel:(ModelUser *)userData {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *newUser = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_USER inManagedObjectContext:context];
    [newUser setValue:userData.userName forKey:kUSER_NAME];
    [newUser setValue:userData.userEmail forKey:kUSER_EMAIL];
    [newUser setValue:userData.userImageUrl forKey:kUSER_IMAGE_URL];
    [newUser setValue:[NSNumber numberWithInt:userData.userId] forKey:kUSER_ID];
    [newUser setValue:userData.userOAuthAccessToken forKey:kUSER_OAUTH_ACCESS_TOKEN];
    [newUser setValue:userData.userKeychainItemName forKey:kUSER_KEYCHANIN_ITEM_NAME];
    [newUser setValue:userData.refreshToken forKey:kREFRESH_TOKEN];
    [newUser setValue:userData.tokenExpireDate forKey:kEXPIRE_DATE];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}
+(void)mapHistoryData:(NSDate *)date title:(NSString *)title isRecent:(BOOL)isRecent {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *newHistory = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_HISTORY inManagedObjectContext:context];
    [newHistory setValue:title forKey:kHISTORY_TITLE];
    [newHistory setValue:[NSNumber numberWithBool:isRecent] forKey:kHISTORY_ISRECENT];
    [newHistory setValue:date forKey:kHISTORY_DATE];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

+(void)mapEmailDataWithModel:(ModelEmail *)emailData forUserId:(long)userId entity:(NSString *)entity {

    if ([self isEmailExist:emailData.userId emailUid:emailData.emailUniqueId]) {
        return;
    }
    
    NSManagedObjectContext *context = [self getManagedObjectContext];
    //NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //    temporaryContext.parentContext = context;
    //    [temporaryContext performBlock:^{
    
    // do something that takes some time asynchronously using the temp context
    NSManagedObject *newEmail = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:context];
    [newEmail setValue:emailData.emailDate forKey:kEMAIL_DATE];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailData.emailId] forKey:kEMAIL_ID];
    [newEmail setValue:nil forKey:kEMAIL_PREVIEW];
    [newEmail setValue:emailData.emailBody forKey:kEMAIL_BODY];
    [newEmail setValue:emailData.emailSubject forKey:kEMAIL_SUBJECT];
    [newEmail setValue:emailData.emailTitle forKey:kEMAIL_TITLE];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isAttachementAvailable] forKey:kIS_ATTACHMENT_AVAILABLE];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isFavorite] forKey:kIS_FAVORITE];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isTrash] forKey:kIS_TRASH_EMAIL];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isArchive] forKey:kIS_ARCHIVE];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isDraft] forKey:kIS_DRAFT];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isSent] forKey:kIS_SENT_EMAIL];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isInbox] forKey:kIS_Inbox_EMAIL];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isConversation] forKey:kIS_CONVERSATION];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isSnoozed] forKey:kIS_SNOOZED];
    [newEmail setValue:[NSNumber numberWithLong:emailData.senderId] forKey:kSENDER_ID];
    [newEmail setValue:[NSNumber numberWithInt:emailData.emailFlags] forKey:kMAIL_FLAGS];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isThreadEmail] forKey:kIS_THREAD_TOP_EMAIL];
    [newEmail setValue:emailData.senderImageUrl forKey:kSENDER_IMAGE_URL];
    [newEmail setValue:emailData.senderName forKey:kSENDER_NAME];
    [self mapContactData:1 title:emailData.emailTitle name:emailData.senderName];
    [newEmail setValue:emailData.emailFolderName forKey:kMAIL_FOLDER];
    [newEmail setValue:emailData.snoozedDate forKey:kSNOOZED_DATE];
    [newEmail setValue:emailData.snoozedMarkedAt forKey:kSNOOZED_MARKED_AT];
    [newEmail setValue:[NSNumber numberWithLong:emailData.userId] forKey:kUSER_ID];
    [newEmail setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
    [newEmail setValue:[NSNumber numberWithBool:emailData.isFakeDraft] forKey:kIS_FAKE_DRAFT];
    [newEmail setValue:[NSNumber numberWithLong:emailData.unreadCount] forKey:kUNREAD_COUNT];
    [newEmail setValue:[NSNumber numberWithLong:emailData.totalUnreadCount] forKey:kTOTAL_UNREAD_THREAD_COUNT];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailData.emailThreadiD] forKey:kEMAIL_THREAD_ID];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailData.emailUniqueId] forKey:kEMAIL_UNIQUE_ID];
    [newEmail setValue:[NSNumber numberWithInt:emailData.attachmentCount] forKey:kATTACHMENT_COUNT];
    NSData * data = [Utilities getArchivedArray:emailData.message];
    [newEmail setValue:data forKey:kMESSAGE_INSTANCE];
    [newEmail setValue:[Utilities getArchivedArray:emailData.toAddresses] forKey:kTO_ADDRESSES];
    [newEmail setValue:[Utilities getArchivedArray:emailData.fromAddresses] forKey:kFROM_ADDRESS];
    [newEmail setValue:[Utilities getArchivedArray:emailData.ccAddresses] forKey:kCC_ADDRESSES];
    [newEmail setValue:[Utilities getArchivedArray:emailData.bccAddresses] forKey:kBCC_ADDRESSES];
    
    
        NSError *error = nil;
    // Save the object to persistent store
    
    //int value = [[Utilities getUserDefaultWithValueForKey:@"test_counter"] intValue];
    
    //if (value == 25) {
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
      /*  [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d", 0] andKey:@"test_counter"];
    }
    else {
        value = value + 1;
        
        NSLog(@"############ Skiping Context Save : %d ############", value);
        
        [Utilities setUserDefaultWithValue:[NSString stringWithFormat:@"%d", value] andKey:@"test_counter"];
    }*/
    
    

}
+(void)mapAttachmentDataWithModel:(ModelAttachments *)attachmentsData entity:(NSString *)entity {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *newAttachment = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:context];
    [newAttachment setValue:[Utilities getArchivedArray:attachmentsData.attachments] forKey:kATTACHMENT_PATHS];
    [newAttachment setValue:[NSNumber numberWithLong:attachmentsData.userId] forKey:kUSER_ID];
    [newAttachment setValue:[NSNumber numberWithUnsignedLongLong:attachmentsData.emailUniqueId] forKey:kEMAIL_UNIQUE_ID];
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}
+(NSMutableArray *)getAttachment:(long)userId emailUid:(uint64_t)emailUid entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p;
    if (emailUid== -100) {
        p = [NSPredicate predicateWithFormat:@"userId == %ld" ,userId];
    }
    else {
        p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu" ,userId, emailUid];
    }
    
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar;
}
+(void)saveFakeDraft:(ModelEmail *)emailData forUserId:(long)userId subject:(NSString *)subject preview:(NSString *)preview fakeId:(long)fakeId {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *newEmail = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_EMAIL inManagedObjectContext:context];
    [newEmail setValue:preview forKey:kEMAIL_PREVIEW];
    [newEmail setValue:subject forKey:kEMAIL_SUBJECT];
    [newEmail setValue:[NSDate date] forKey:kEMAIL_DATE];
    [newEmail setValue:[NSNumber numberWithBool:YES] forKey:kIS_DRAFT];
    [newEmail setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
    [newEmail setValue:[NSNumber numberWithBool:YES] forKey:kIS_FAKE_DRAFT];
    [newEmail setValue:[NSNumber numberWithLong:fakeId] forKey:kCLONE_ID];
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

+(void)mapEmailInfo:(ModelEmailInfo *)emailInfo {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    
    if ([self isEmailInfoExist:emailInfo.userId emailUid:emailInfo.emailUniqueId]) {
        NSLog(@"Can't Save! Already Exists");
        return;
    }
    
    NSManagedObject *newEmail = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_EMAIL_INFO inManagedObjectContext:context];
    [newEmail setValue:emailInfo.emailDate forKey:kEMAIL_DATE];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailInfo.emailId] forKey:kEMAIL_ID];
    [newEmail setValue:emailInfo.emailFolderName forKey:kMAIL_FOLDER];
    [newEmail setValue:[NSNumber numberWithLong:emailInfo.userId] forKey:kUSER_ID];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailInfo.emailThreadiD] forKey:kEMAIL_THREAD_ID];
    [newEmail setValue:[NSNumber numberWithUnsignedLongLong:emailInfo.emailUniqueId] forKey:kEMAIL_UNIQUE_ID];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

+(BOOL)isEmailExist:(long)userId emailUid:(uint64_t)uid {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %@ AND emailUniqueId == %llu" ,[NSNumber numberWithLong:userId], uid];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    if (ar.count>=1) {
        return YES;
    }
    return NO;
}

+(BOOL)isEmailInfoExist:(long)userId emailUid:(uint64_t)uid {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL_INFO];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %@" ,[NSNumber numberWithLong:userId]];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    if (ar.count>=1) {
        return YES;
    }
    return NO;
}
+(NSMutableArray *)isHistoryStringExist:(NSString *)str isRecent:(BOOL)isRecent {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_HISTORY];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"title == %@ AND isRecent == %@" ,str, [NSNumber numberWithBool:isRecent]];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar;
}
+(NSMutableArray*)fetchHistory:(BOOL)isRecent {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_HISTORY];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"isRecent == %@" ,[NSNumber numberWithBool:isRecent]];
    [fetchRequest setPredicate:p];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kHISTORY_DATE ascending:NO];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar;
}
+(NSMutableArray*)fetchEmailInfo:(uint64_t)unId userId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL_INFO];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu" ,userId, unId];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar;
}
+(void)saveSnoozePreferencesWithData:(NSMutableDictionary *)dictionary {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *snoozePreferences = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_SNOOZE_PREFERENCE inManagedObjectContext:context];
    NSTimeInterval timeStamp = [[dictionary objectForKey:kSNOOZE_DATE] doubleValue];
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSString * firebaseId = [dictionary objectForKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseId]) {
        [snoozePreferences setValue:firebaseId forKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
    }
    [snoozePreferences setValue:date forKey:kSNOOZE_DATE];
    [snoozePreferences setValue:[dictionary objectForKey:kSNOOZE_TITLE] forKey:kSNOOZE_TITLE];
    [snoozePreferences setValue:[dictionary objectForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
    [snoozePreferences setValue:[dictionary objectForKey:kTIME_STRING] forKey:kTIME_STRING];
    [snoozePreferences setValue:[dictionary objectForKey:kSNOOZE_TIME_PERIOD] forKey:kSNOOZE_TIME_PERIOD];
    [snoozePreferences setValue:[dictionary objectForKey:kIMAGE] forKey:kIMAGE];
    [snoozePreferences setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kSNOOZE_IS_DEFAULT] boolValue]] forKey:kSNOOZE_IS_DEFAULT];
    
    [snoozePreferences setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kIS_PREFERENCE_ACTIVE] boolValue]] forKey:kIS_PREFERENCE_ACTIVE];
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kSNOOZE_MINUTE_COUNT] integerValue]] forKey:kSNOOZE_MINUTE_COUNT];
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kSNOOZE_HOUR_COUNT] integerValue]] forKey:kSNOOZE_HOUR_COUNT];
    
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kPREFERENCE_ID] integerValue]] forKey:kPREFERENCE_ID];
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}
+(void)saveSendLaterPreferencesWithData:(NSMutableDictionary *)dictionary {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSManagedObject *snoozePreferences = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_SEND_LATER_PREFERENCES inManagedObjectContext:context];
    NSTimeInterval timeStamp = [[dictionary objectForKey:kSEND_DATE] doubleValue];
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSString * firebaseId = [dictionary objectForKey:kSEND_PREFERENCES_FIREBASEID];
    if ([Utilities isValidString:firebaseId]) {
        [snoozePreferences setValue:firebaseId forKey:kSEND_PREFERENCES_FIREBASEID];
    }
    [snoozePreferences setValue:date forKey:kSEND_DATE];
    [snoozePreferences setValue:[dictionary objectForKey:kSEND_LATER_TITLE] forKey:kSEND_LATER_TITLE];
    [snoozePreferences setValue:[dictionary objectForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
    [snoozePreferences setValue:[dictionary objectForKey:kTIME_STRING] forKey:kTIME_STRING];
    [snoozePreferences setValue:[dictionary objectForKey:kSNOOZE_TIME_PERIOD] forKey:kSNOOZE_TIME_PERIOD];
    [snoozePreferences setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kSNOOZE_IS_DEFAULT] boolValue]] forKey:kSNOOZE_IS_DEFAULT];
    
    [snoozePreferences setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kIS_PREFERENCE_ACTIVE] boolValue]] forKey:kIS_PREFERENCE_ACTIVE];
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kSEND_MINUTE_COUNT] integerValue]] forKey:kSEND_MINUTE_COUNT];
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kSEND_HOUR_COUNT] integerValue]] forKey:kSEND_HOUR_COUNT];
    [snoozePreferences setValue:[NSNumber numberWithInteger:[[dictionary objectForKey:kPREFERENCE_ID] integerValue]] forKey:kPREFERENCE_ID];
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}
+(NSMutableArray *)fetchSnoozePreferencesForBool:(BOOL )isDeafult emailId:(NSString *)email {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_SNOOZE_PREFERENCE];
    NSPredicate *predicate = nil;
    if (isDeafult) {
        predicate = [NSPredicate predicateWithFormat:@"isDefault == %@", [NSNumber numberWithBool:isDeafult]];
    }
    else {
        predicate = [NSPredicate predicateWithFormat:@"userEmail ==[c] %@ AND isDefault == %@", email, [NSNumber numberWithBool:isDeafult]];
    }
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kPREFERENCE_ID ascending:YES];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchActiveSnoozePreferencesForBool:(BOOL )isDeafult emailId:(NSString *)email {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_SNOOZE_PREFERENCE];
    NSPredicate *predicate = nil;
    if (isDeafult) {
        predicate = [NSPredicate predicateWithFormat:@"isDefault == %@", [NSNumber numberWithBool:isDeafult]];
    }
    else {
        predicate = [NSPredicate predicateWithFormat:@"userEmail ==[c] %@ AND isDefault == %@ AND isPreferenceActive == %@", email, [NSNumber numberWithBool:isDeafult],[NSNumber numberWithBool:YES]];
    }
    
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kPREFERENCE_ID ascending:YES];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchSendlaterPreferencesForBool:(BOOL )isDeafult emailId:(NSString *)email {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_SEND_LATER_PREFERENCES];
    NSPredicate *predicate = nil;
    if (isDeafult) {
        predicate = [NSPredicate predicateWithFormat:@"isDefault == %@", [NSNumber numberWithBool:isDeafult]];
    }
    else {
        predicate = [NSPredicate predicateWithFormat:@"userEmail ==[c] %@ AND isDefault == %@", email, [NSNumber numberWithBool:isDeafult]];
    }
    
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kPREFERENCE_ID ascending:YES];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(void)saveQuickResponsesWithSnapshot:(FIRDataSnapshot *)dataSnapshot {
    
    NSDictionary * dataDictionary = dataSnapshot.value;
    NSManagedObjectContext *context = [self getManagedObjectContext];
    
    NSManagedObject *quickResponse = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_QUICK_RESPONSE inManagedObjectContext:context];
    
    [quickResponse setValue:dataSnapshot.key forKey:kFIREBASE_ID];
    [quickResponse setValue:[dataDictionary objectForKey:kQUICK_REPONSE_Title] forKey:kQUICK_REPONSE_Title];
    [quickResponse setValue:[dataDictionary objectForKey:kQUICK_REPONSE_HTML] forKey:kQUICK_REPONSE_HTML];
    [quickResponse setValue:[dataDictionary objectForKey:kQUICK_REPONSE_Text] forKey:kQUICK_REPONSE_Text];
    [quickResponse setValue:[dataDictionary objectForKey:kQUICK_REPONSE_ATTACHMENT_PATH] forKey:kQUICK_REPONSE_ATTACHMENT_PATH];
    [quickResponse setValue:[dataDictionary objectForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
    NSString * strNumber = [NSString stringWithFormat:@"%@",[dataDictionary objectForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE]];
    if ([strNumber isEqualToString:@"0"]) {
        [quickResponse setValue:[NSNumber numberWithBool:NO] forKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE];
    }
    else {
        [quickResponse setValue:[NSNumber numberWithBool:YES] forKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE];
    }
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
}
+(NSMutableArray *)fetchQuickResponsesForEmail:(NSString *)email {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_QUICK_RESPONSE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEmail ==[c] %@", email];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(NSMutableArray *)fetchQuickResponseForFirebaseId:(NSString *)firebaseId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_QUICK_RESPONSE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firebaseId ==[c] %@", firebaseId];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kQUICK_REPONSE_ID ascending:YES];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(NSMutableArray *)fetchSnoozePreferenceForFirebaseId:(NSString *)firebaseId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_SNOOZE_PREFERENCE];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"snoozePreferenceFirebaseId ==[c] %@", firebaseId];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchSendlaterPreferencesForFirebaseId:(NSString *)firebaseId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_SEND_LATER_PREFERENCES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sendPreferenceFirebaseId ==[c] %@", firebaseId];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(int)fetchUnreadCountUserId:(long)userId threadId:(uint64_t)threadId folderType:(int)folderType entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return 0;
    }
    BOOL isTrashMail = NO;
    /*BOOL isInboxMail = NO;*/
    BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    
    if (folderType == kFolderAllMail) {
    }
    else if (folderType == kFolderInboxMail) {
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@", userId,threadId,[NSNumber numberWithBool:isTrashMail]];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    int total = 0;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    for (NSManagedObject *object in ar) {
        NSNumber *objectRowTotalNumber = [object valueForKey:kUNREAD_COUNT];
        int objectRowTotal = [objectRowTotalNumber intValue];
        total = total + objectRowTotal;
    }
    return total;
}

//+(NSMutableArray *)fetchAllEmailsForUserId:(long)userId {
//    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL ];
//    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@", userId,[NSNumber numberWithBool:NO]];
//    ///NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld", userId];
//    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
//
//    [fetchRequest setPredicate:p];
//    fetchRequest.sortDescriptors = @[sdSortDate];
//    NSError *fetchError;
//    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
//}

+(NSMutableArray *)fetchEmailsForThreadId:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    BOOL isTrashMail = NO;
    /*BOOL isInboxMail = NO;*/
    BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    if (folderType == kFolderAllMail) {
    }
    else if (folderType == kFolderInboxMail) {
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@ AND isSnoozed == %@", userId,threadId,[NSNumber numberWithBool:isTrashMail],[NSNumber numberWithBool:snoozed]];
    if (needIdsOnly) {
        [fetchRequest setResultType:NSDictionaryResultType];
        [fetchRequest setPropertiesToFetch:
         [NSArray arrayWithObjects:@"emailId", /* etc. */ nil]];
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(NSMutableArray *)getEmailsForThreadId:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    BOOL isTrashMail = NO;
    /*BOOL isInboxMail = NO;*/
    BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    if (folderType == kFolderAllMail) {
        
    }
    else if (folderType == kFolderInboxMail) {
        
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@", userId,threadId,[NSNumber numberWithBool:isTrashMail]];
    if (needIdsOnly) {
        [fetchRequest setResultType:NSDictionaryResultType];
        [fetchRequest setPropertiesToFetch:
         [NSArray arrayWithObjects:@"emailId", /* etc. */ nil]];
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchThreadForId:(uint64_t)threadId userId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL ];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@", userId,threadId,[NSNumber numberWithBool:NO]];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchSingleThreadForId:(uint64_t)threadId userId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL ];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu", userId,threadId];
    
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchEmailWithId:(uint64_t)emailId userId:(long)userId entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailId == %llu AND isTrashEmail == %@", userId,emailId,[NSNumber numberWithBool:YES]];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchTopEmailForThreadId:(uint64_t)threadId andUserId:(long)userId isTopEmail:(BOOL)isTop isTrash:(BOOL)isTrash entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isThreadTopEmail == %@ AND isTrashEmail == %@", userId,threadId, [NSNumber numberWithBool:isTop],[NSNumber numberWithBool:isTrash]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(NSMutableArray *)fetchSingleEmailForUniqueId:(uint64_t)uniqueId andUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu", userId,uniqueId];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(NSMutableArray *)fetchSingleEmailForUniqueIdForInbox:(uint64_t)uniqueId andUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@", userId,uniqueId,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchSingleEmailForUniqueIdInTrash:(uint64_t)uniqueId andUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@", userId,uniqueId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchSingleEmailForUniqueIdInArchive:(uint64_t)uniqueId andUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu AND isArchive == %@ AND isTrashEmail == %@ AND isDraft == %@ AND isSnoozed == %@" , userId,uniqueId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchLatestTopEmailForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    fetchRequest.fetchOffset = 0;
    fetchRequest.fetchLimit = 5;
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@  AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND (isConversation == %@ OR isInboxEmail == %@)",userId,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchLatestDraftEmailForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    fetchRequest.fetchOffset = 0;
    fetchRequest.fetchLimit = 5;
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND isSentEmail == %@ AND isThreadTopEmail == %@",userId,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchLatestTrashEmailForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    fetchRequest.fetchOffset = 0;
    fetchRequest.fetchLimit = 5;
    
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND isTrashEmail == %@ AND isThreadTopEmail == %@",userId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchLatestSentEmailForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    fetchRequest.fetchOffset = 0;
    fetchRequest.fetchLimit = 5;
    
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND (isConversation == %@ OR isSentEmail == %@) AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND isDraft == %@ AND isSnoozed == %@ AND isThreadTopEmail == %@",userId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchThread:(uint64_t)threadId userId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_THREAD];
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu ",userId,threadId];
    [fetchRequest setPredicate:p];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchCompleteThread:(uint64_t)threadId userId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu ",userId,threadId];
    [fetchRequest setPredicate:p];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSUInteger)isThreadIdExist:(uint64_t)threadId forUserId:(long)userId forFolder:(int)folderType entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return 0;
    }
    BOOL isTrashMail = NO;
    BOOL isInboxMail = NO;
    //BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    if (folderType == kFolderAllMail) {
        
    }
    else if (folderType == kFolderInboxMail) {
        
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        //isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    /* NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %ld AND isTrashEmail == %@ AND isSentEmail == %@" ,userId, threadId,[NSNumber numberWithBool:isTrashMail],[NSNumber numberWithBool:isSentMail]];*/
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@" ,userId, threadId,[NSNumber numberWithBool:isTrashMail]];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar.count;
}

+(NSUInteger)isThreadExist:(uint64_t)threadId forUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu" ,userId, threadId];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar.count;
}
+(NSUInteger)isUniqueIdExist:(uint64_t)UniqueId forUserId:(long)userId entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return 0;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu",userId, UniqueId];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar.count;
}
+(NSUInteger)isGmailMessageIdExist:(uint64_t)gmailMessageId forUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND emailUniqueId == %llu",userId, gmailMessageId];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * ar = [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    return ar.count;
}
+(NSMutableArray *)fetchSnoozedEmailsForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND isSnoozed == %@ AND isThreadTopEmail == %@", userId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO]];
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kSNOOZED_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchAllFakeDrafts {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"isFakeDraft == %@", [NSNumber numberWithBool:YES]];
    
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSMutableArray *)fetchFakeDraftForId:(long)cloneId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"cloneId == %ld", cloneId];
    
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSUInteger)fetchFavoriteCountUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@ AND isFavorite == %@ AND isArchive == %@ AND isSnoozed == %@ AND isTrashEmail == %@", userId,[NSNumber numberWithBool:NO] ,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSUInteger  count = [managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (fetchError == nil) {
        return count;
    }
    else {
        return 0;
    }
}
+(NSMutableArray *)fetchFavoriteEmailsForUserId:(long)userId withFetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)isSearching searchingString:(NSString *)text {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = nil;
    if (isSearching) {
        p = [NSPredicate predicateWithFormat:@"userId == %ld AND isFavorite == %@ AND isThreadTopEmail == %@  AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isArchive == %@ AND isSnoozed == %@ AND isTrashEmail == %@", userId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    else {
        p = [NSPredicate predicateWithFormat:@"userId == %ld AND isFavorite == %@ AND isThreadTopEmail == %@ AND isArchive == %@ AND isSnoozed == %@ AND isTrashEmail == %@", userId,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
        fetchRequest.fetchOffset = fetchOffset;
        fetchRequest.fetchLimit = fetchLimit;
        
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+ (NSUInteger )fetchEmailsCountForGivenStartDate:(NSDate *)date endDate:(NSDate *)endate andUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailDate > %@ AND emailDate < %@ AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", userId, date,endate, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    [fetchRequest setPredicate:p];
    
    
    NSError *fetchError;
    NSUInteger  count = [managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (fetchError == nil) {
        return count;
    }
    else {
        return 0;
    }
}

+(NSMutableArray *)fetchEmailsForGivenStartDate:(NSDate *)date endDate:(NSDate *)endate andUserId:(long)userId ithFetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)searching text:(NSString *)text  {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = nil;
    if (searching == NO) {
        p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailDate > %@ AND emailDate < %@ AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", userId, date,endate, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
        fetchRequest.fetchOffset = fetchOffset;
        fetchRequest.fetchLimit = fetchLimit;
    }
    else {
        p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailDate > %@ AND emailDate < %@ AND isThreadTopEmail == %@ AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", userId, date,endate, [NSNumber numberWithBool:NO], text, text, text, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    
    
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+ (NSUInteger )fetchUnreadCountForUserId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@ AND unreadCount >= %ld AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", userId, [NSNumber numberWithBool:NO], 1,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    [fetchRequest setPredicate:p];
    
    
    NSError *fetchError;
    NSUInteger  count = [managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (fetchError == nil) {
        return count;
    }
    else {
        return 0;
    }
    
}
+(NSMutableArray *)fetchUnreadEmailsForUserId:(long)userId fetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)searching text:(NSString *)text  {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p = nil;
    if (searching == NO) {
        //[NSPredicate predicateWithFormat:@"SUBQUERY(games, $g, $g.kickOffDate >= %@ AND $g.kickOffDate <= %@).@count > 0", [self startOfDay:[NSDate date]],[self endOfDay:[NSDate date]]];
        //p=[NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@ AND unreadCount >= %ld AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@ AND isSnoozed == %@ AND isArchive == %@", userId, [NSNumber numberWithBool:NO], 1, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
        p=[NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@ AND unreadCount >= %ld AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@ AND isSnoozed == %@ AND isArchive == %@", userId, [NSNumber numberWithBool:NO], 1, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
        
        //p=[NSPredicate predicateWithFormat:@"SUBQUERY(threadInfo, $g, $g.isThreadTopEmail == %@ AND $g.userId == %ld).@count > 0", [NSNumber numberWithBool:NO],userId];
        fetchRequest.fetchOffset = fetchOffset;
        fetchRequest.fetchLimit = fetchLimit;
    }
    else {
        p=[NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@ AND unreadCount >= %ld AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", userId, [NSNumber numberWithBool:NO], 1,text,text,text, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:NO];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}

+(void)deleteObject:(NSManagedObject *)object {
    [[self getManagedObjectContext] deleteObject:object];
}
+ (void)updateData {
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

+ (NSFetchedResultsController *)initFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent entity:(NSString *)entityName {
    if (fetchedResultsController != nil || ![Utilities isValidString:entityName]) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    if (isSearching) {
        p=[NSPredicate predicateWithFormat:@"(isThreadTopEmail == %@ AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@  AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND isSentEmail == %@ AND hideEmail == %@) OR isFakeDraft == %@",[NSNumber numberWithBool:NO], text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:NO], [NSNumber numberWithBool:sent],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:YES]];
    } else {
        p=[NSPredicate predicateWithFormat:@"(isThreadTopEmail == %@  AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND isSentEmail == %@ AND hideEmail == %@) OR isFakeDraft == %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:NO], [NSNumber numberWithBool:sent],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:YES]];
    }
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}
+(NSMutableArray *)fetchThreadData:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity {
    if (![Utilities isValidString:entity]) {
        return [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    BOOL isTrashMail = NO;
    /*BOOL isInboxMail = NO;*/
    BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    if (folderType == kFolderAllMail) {
        
    }
    else if (folderType == kFolderInboxMail) {
        
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@ AND isSnoozed == %@AND hideEmail == %@", userId,threadId,[NSNumber numberWithBool:isTrashMail],[NSNumber numberWithBool:snoozed], [NSNumber numberWithBool:NO]];
    if (needIdsOnly) {
        [fetchRequest setResultType:NSDictionaryResultType];
        [fetchRequest setPropertiesToFetch:
         [NSArray arrayWithObjects:@"emailId", /* etc. */ nil]];
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSFetchedResultsController *)initThreadFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController threadId:(uint64_t)threadId andUserId:(int)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity {
    if (fetchedResultsController != nil || ![Utilities isValidString:entity]) {
        return fetchedResultsController;
    }
    
    BOOL isTrashMail = NO;
    /*BOOL isInboxMail = NO;*/
    BOOL isSentMail = NO;
    BOOL isDraftMail = NO;
    if (folderType == kFolderAllMail) {
        
    }
    else if (folderType == kFolderInboxMail) {
        
    }
    else if (folderType == kFolderTrashMail) {
        isTrashMail = YES;
    }
    else if (folderType == kFolderSentMail) {
        isSentMail = YES;
    }
    else if (folderType == kFolderDraftMail) {
        isDraftMail = YES;
    }
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld AND emailThreadId == %llu AND isTrashEmail == %@ AND isSnoozed == %@AND hideEmail == %@", userId,threadId,[NSNumber numberWithBool:isTrashMail],[NSNumber numberWithBool:snoozed], [NSNumber numberWithBool:NO]];
    if (needIdsOnly) {
        [fetchRequest setResultType:NSDictionaryResultType];
        [fetchRequest setPropertiesToFetch:
         [NSArray arrayWithObjects:@"emailId", /* etc. */ nil]];
    }
    NSSortDescriptor *sdSortDate = [NSSortDescriptor sortDescriptorWithKey:kEMAIL_DATE ascending:YES];
    
    [fetchRequest setPredicate:p];
    fetchRequest.sortDescriptors = @[sdSortDate];
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}
+ (NSFetchedResultsController *)initArchiveFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_EMAIL inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    if (isSearching) {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@ AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@  AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND hideEmail == %@",[NSNumber numberWithBool:NO], text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    } else {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@ AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND hideEmail == %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}
+(NSUInteger)fetchInboxEmailsCountForUserId:(long)userId  isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent isInbox:(BOOL)inbox isConversation:(BOOL)conversation isTrash:(BOOL)trash isSnoozed:(BOOL)snoozed {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND isThreadTopEmail == %@  AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND (isConversation == %@ OR isInboxEmail == %@)",userId,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:trash],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:snoozed], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES]];
    
    [fetchRequest setPredicate:p];
    
    
    NSError *fetchError;
    NSUInteger  count = [managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (fetchError == nil) {
        return count;
    }
    else {
        return 0;
    }
}
+(NSUInteger)fetchTop {
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    
    NSPredicate * p = [NSPredicate predicateWithFormat:@"SUBQUERY(thread, $sub, $sub.userId == %@).@count > 0",[NSNumber numberWithInt:1]];
    
    [fetchRequest setPredicate:p];
    
    NSError *fetchError;
    NSUInteger  count = [managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (fetchError == nil) {
        return count;
    }
    else {
        return 0;
    }
}//https://console.firebase.google.com/project/simpleemail-13b1e/overview
+ (NSFetchedResultsController *)fetchedRegularEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent isInbox:(BOOL)inbox isConversation:(BOOL)conversation isTrash:(BOOL)trash isSnoozed:(BOOL)snoozed fetchReadOnly:(BOOL)needReadOnly entity:(NSString *)entityName {
    if (fetchedResultsController != nil || ![Utilities isValidString:entityName]) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    
    if(needReadOnly) {
        [parr addObject:[NSPredicate predicateWithFormat:@"unreadCount == %ld",0]];
    }
    
    if (isSearching) {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@ AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@  AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND (isConversation == %@ OR isInboxEmail == %@) AND hideEmail == %@",[NSNumber numberWithBool:NO], text,text,text,[NSNumber numberWithBool:trash],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:snoozed], [NSNumber numberWithBool:conversation], [NSNumber numberWithBool:inbox], [NSNumber numberWithBool:NO]];
    } else {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@  AND isTrashEmail == %@ AND isArchive == %@ AND isDraft == %@ AND isSnoozed == %@ AND (isConversation == %@ OR isInboxEmail == %@) AND hideEmail == %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:trash],[NSNumber numberWithBool:fetchArchive],[NSNumber numberWithBool:fetchDraft],[NSNumber numberWithBool:snoozed], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        
        //p=[NSPredicate predicateWithFormat:@"SUBQUERY(isThreadTopEmail == %@, $x, $x.@sum.numbervalue == %@).@count > 0)",[NSNumber numberWithBool:NO]];
        
        //p=[NSPredicate predicateWithFormat:@"(isThreadTopEmail == %@), $x , $x.isDraft == %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    fetchRequest.includesPendingChanges = NO;
    [fetchRequest setFetchBatchSize:20];
    
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}
+ (NSFetchedResultsController *)fetchedFavoriteEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_EMAIL inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    
    if (isSearching) {
        p = [NSPredicate predicateWithFormat:@"isFavorite == %@ AND isThreadTopEmail == %@  AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND isSnoozed == %@ AND isArchive == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    else {
        p = [NSPredicate predicateWithFormat:@"isFavorite == %@ AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND isSnoozed == %@ AND isArchive == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}
+ (NSFetchedResultsController *)fetchedSnoozedEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_EMAIL inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    if (isSearching) {
        p = [NSPredicate predicateWithFormat:@"AND isSnoozed == %@ AND isThreadTopEmail == %@  AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND hideEmail == %@", [NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    else {
        /*p = [NSPredicate predicateWithFormat:@"isSnoozed == %@ AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND hideEmail == %@", [NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
         */
        
        p = [NSPredicate predicateWithFormat:@"isSnoozed == %@ AND isThreadTopEmail == %@ AND isTrashEmail == %@", [NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}

+ (NSFetchedResultsController *)fetchedTrashEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text entity:(NSString *)entityName {
    if (fetchedResultsController != nil || ![Utilities isValidString:entityName]) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSPredicate *p = nil;
    
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    
    if (isSearching) {
        p = [NSPredicate predicateWithFormat:@"isTrashEmail == %@ AND isThreadTopEmail == %@  AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isDraft == %@ AND hideEmail == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    else {
        p = [NSPredicate predicateWithFormat:@"isTrashEmail == %@ AND isThreadTopEmail == %@ AND isDraft == %@ AND hideEmail == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}

+ (NSFetchedResultsController *)fetchedSentEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text entity:(NSString *)entityName {
    
    if (fetchedResultsController != nil || ![Utilities isValidString:entityName]) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSPredicate *p = nil;
    
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    
    if (isSearching) {
        p = [NSPredicate predicateWithFormat:@"(isConversation == %@ OR isSentEmail == %@) AND isThreadTopEmail == %@  AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND isDraft == %@ AND isSnoozed == %@",[NSNumber numberWithBool:YES] ,[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],text,text,text,[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    else {
        p = [NSPredicate predicateWithFormat:@"(isConversation == %@ OR isSentEmail == %@) AND isThreadTopEmail == %@ AND isTrashEmail == %@ AND isDraft == %@ AND isSnoozed == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    }
    
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}

+ (NSFetchedResultsController *)fetchedUnreadEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_EMAIL inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kEMAIL_DATE ascending:NO];
    //NSSortDescriptor *sort = [[NSSortDescriptor alloc]
    //                         initWithKey:kEMAIL_THREAD_ID ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSPredicate *p = nil;
    NSMutableArray *parr = [NSMutableArray array];
    if(userId>0) {
        [parr addObject:[NSPredicate predicateWithFormat:@"userId == %ld",userId]];
    }
    
    if (isSearching) {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@ AND unreadCount >= %ld AND (senderName BEGINSWITH[cd] %@ OR emailBody CONTAINS[cd] %@ OR emailSubject BEGINSWITH[cd] %@) AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", [NSNumber numberWithBool:NO], 1,text,text,text, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
    }
    else {
        p=[NSPredicate predicateWithFormat:@"isThreadTopEmail == %@ AND unreadCount >= %ld AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@ AND isArchive == %@", [NSNumber numberWithBool:NO], 1, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
        //p=[NSPredicate predicateWithFormat:@"userId == %ld AND SUBQUERY(Email, $x, $x.@sum.unreadCount >= %ld AND $x.emailThreadId == emailThreadId) AND isTrashEmail == %@ AND isSentEmail == %@ AND isDraft == %@  AND isSnoozed == %@", userId, 1, [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO]];
    }
    
    /*NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"unreadCount"];
     
     // Create an expression to represent the sum of marks
     NSExpression *maxExpression = [NSExpression expressionForFunction:@"sum:"
     arguments:@[keyPathExpression]];
     
     NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
     [expressionDescription setName:@"marksSum"];
     [expressionDescription setExpression:maxExpression];
     [expressionDescription setExpressionResultType:NSInteger32AttributeType];
     
     NSArray *propertiesToFetch = [NSArray arrayWithObjects:@"emailThreadId", expressionDescription, nil];
     
     [fetchRequest setPropertiesToFetch:propertiesToFetch];
     [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObject:@"emailThreadId"]];*/
    [parr addObject:p];
    NSPredicate *compoundpred = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    fetchRequest.predicate = compoundpred;
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    return theFetchedResultsController;
}

+(NSMutableArray*)fetchAutocompleteDataforString:(NSString *)str userId:(NSString *)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_EMAIL inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"emailTitle"],[[entity propertiesByName] objectForKey:@"senderName"], nil];
    fetchRequest.returnsDistinctResults = YES;
    NSPredicate * p = [NSPredicate predicateWithFormat:@"(senderName CONTAINS[cd] %@ OR emailTitle CONTAINS[cd] %@)",str,str];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(void)mapContactData:(int)priority title:(NSString *)emailTitle name:(NSString *)name {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_CONTACTS];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"emailTitle ==[c] %@", emailTitle];
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    NSMutableArray * array = [[context executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
    if (array.count == 0) {
        NSManagedObject *newContact = [NSEntityDescription insertNewObjectForEntityForName:kENTITY_CONTACTS inManagedObjectContext:context];
        [newContact setValue:emailTitle forKey:kEMAIL_TITLE];
        [newContact setValue:[NSNumber numberWithInt:priority] forKey:kPRIORITY];
        [newContact setValue:name forKey:kSENDER_NAME];
        
        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    }
}
+(NSMutableArray*)fetchAutocompleteContactsforString:(NSString *)str userId:(NSString *)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:kENTITY_CONTACTS inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate * p = [NSPredicate predicateWithFormat:@"(senderName CONTAINS[cd] %@ OR emailTitle CONTAINS[cd] %@)",str,str];
    [fetchRequest setPredicate:p];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:kPRIORITY ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(int)fetchUserCount {
    NSManagedObjectContext *context = [self getManagedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: [NSEntityDescription entityForName:kENTITY_USER inManagedObjectContext:context]];
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest: request error: &error];
    return (int)count;
}

+(NSMutableArray *)fetchUserDataForId:(long)userId {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_USER];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"userId == %ld", userId];
    fetchRequest.predicate = predicate;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
}
+(NSMutableArray *)fetchAllUsers {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_USER];
    return [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
}
+(NSMutableArray *)fetchAllthreads {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Thread"];
    return [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
}
+(NSMutableArray *)fetchUserIdForEmail:(NSString *)email {
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_USER];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userEmail ==[c] %@", email];
    
    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToFetch:
     [NSArray arrayWithObjects:@"userId", /* etc. */ nil]];
    
    [fetchRequest setPredicate:p];
    NSError *fetchError;
    return [[managedObjectContext executeFetchRequest:fetchRequest error:&fetchError] mutableCopy];
}
+(NSError *)deleteAllTrash:(NSString *)userId {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate * p = [NSPredicate predicateWithFormat:@"userId == %ld AND isTrashEmail == %@ AND isThreadTopEmail == %@ AND isDraft == %@ AND hideEmail == %@",[userId longLongValue], [NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO]];
    
    [fetchRequest setPredicate:p];
    
    NSArray *emails = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        return error;
    }
    
    //error handling goes here
    for (int i = 0; i<emails.count; ++i) {
        NSManagedObject * email = [emails objectAtIndex:i];
        [managedObjectContext deleteObject:email];
    }
    NSError *saveError = nil;
    [managedObjectContext save:&saveError];
    if (saveError != nil) {
        return saveError;
    }
    return error;
}
+ (NSError *)deleteAllEntities:(NSString *)nameEntity
{
    if (![Utilities isValidString:nameEntity]) {
        return [NSError errorWithDomain:NSCocoaErrorDomain code:404 userInfo:nil];
    }
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:nameEntity];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        [managedObjectContext deleteObject:object];
    }
    
    NSError *saveError = nil;
    [managedObjectContext save:&saveError];
    if (saveError != nil) {
        return saveError;
    }
    return nil;
}
+(NSError* )wipeUser:(NSString *)userId {
    
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    /*    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
     NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld", [userId longLongValue]];
     [request setPredicate:p];
     NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
     
     NSError *deleteError = nil;
     [[self getPersistentStoreCoordinator] executeRequest:delete withContext:managedObjectContext error:&deleteError];
     if (deleteError != nil) {
     return deleteError;
     }*/
    
    /* delete all emails */
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"userId == %ld", [userId longLongValue]];
    [fetchRequest setPredicate:p];
    
    NSError *error = nil;
    NSArray *emails = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        return error;
    }
    
    //error handling goes here
    for (NSManagedObject *email in emails) {
        [managedObjectContext deleteObject:email];
    }
    NSError *saveError = nil;
    [managedObjectContext save:&saveError];
    if (saveError != nil) {
        return saveError;
    }
    
    /* delete user */
    NSFetchRequest *userfetchRequest = [[NSFetchRequest alloc] initWithEntityName:kENTITY_USER];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId == %ld", [userId longLongValue]];
    [userfetchRequest setPredicate:predicate];
    
    NSError *userFetchError = nil;
    NSArray *users = [managedObjectContext executeFetchRequest:userfetchRequest error:&userFetchError];
    if (userFetchError != nil) {
        return userFetchError;
    }
    for (NSManagedObject *user in users) {
        long usrId = [[user valueForKey:kUSER_ID] longLongValue];
        NSMutableArray * attachments = [self getAttachment:usrId emailUid:-100 entity:kENTITY_ATTACHMENTS];
        for (NSManagedObject *attachment in attachments) {
            NSMutableArray * attachmentPaths = (NSMutableArray *)[Utilities getUnArchivedArrayForObject:[attachment valueForKey:kATTACHMENT_PATHS]];
            [Utilities removeFilesFromPaths:attachmentPaths];
            [managedObjectContext deleteObject:attachment];
        }
    }
    
    for (NSManagedObject *user in users) {
        [managedObjectContext deleteObject:user];
    }
    NSError *userSaveError = nil;
    [managedObjectContext save:&userSaveError];
    if (userSaveError != nil) {
        return userSaveError;
    }
    [Utilities updateInboxLastFetchCount:0 userId:userId];
    [Utilities updateDarftLastFetchCount:0 ForUser:userId];
    [Utilities updateArchiveLastFetchCount:0 ForUser:userId];
    [Utilities updateSentLastFetchCount:0 forUser:userId];
    [Utilities updateTrashLastFetchCount:0 ForUser:userId];
    
    return nil;
}

// Remove All Email Objects From CoreData
+(void)deleteAllEmails {
    NSManagedObjectContext * context = [self getManagedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kENTITY_EMAIL];

    [request setIncludesPropertyValues:NO]; //only fetch the managedObjectID

    NSError *error = nil;
    NSArray *emails = [context executeFetchRequest:request error:&error];

    for (NSManagedObject *object in emails) {
        [context deleteObject:object];
    }
    NSError *saveError = nil;
    [context save:&saveError];
}


/*[...]
 NSData *arrayData = [NSKeyedArchiver archivedDataWithRootObject:TheArray];
 myEntity.arrayProperty = arrayData;
 [self saveContext]; //Self if we are in the model class
 [...]
 Then you can retrieve all the original array info by doing the opposite operation:
 
 [...]
 NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:anEntity.arrayProperty];
 [...]
 https://coderwall.com/p/mx_wmq/how-to-save-a-nsarray-nsmutablearray-in-core-data*/
@end
