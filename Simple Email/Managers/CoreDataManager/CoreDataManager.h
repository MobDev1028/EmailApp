//
//  CoreDataManager.h
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ModelEmail.h"
#import "ModelUser.h"
#import "ModelEmailInfo.h"
#import "ModelAttachments.h"

@import Firebase;

@interface CoreDataManager : NSObject

+ (NSManagedObjectContext *)getManagedObjectContext;

+ (void)updateData;

+ (void)deleteObject:(NSManagedObject *)object;

+ (int)fetchUserCount;

+ (NSMutableArray *)fetchAllUsers;

+ (NSUInteger)isUniqueIdExist:(uint64_t)UniqueId forUserId:(long)userId entity:(NSString *)entity;

+ (NSUInteger)isThreadIdExist:(uint64_t)threadId forUserId:(long)userId forFolder:(int)folderType entity:(NSString *)entity;

//+ (NSUInteger )fetchEmailsCountForUserId:(long)userId;

+ (NSMutableArray *)fetchUserDataForId:(long)userId;

+ (void)mapNewUserDataWithModel:(ModelUser *)userData;

//+ (NSMutableArray *)fetchAllEmailsForUserId:(long)userId;

+ (NSMutableArray *)fetchSnoozedEmailsForUserId:(long)userId;

+(void)mapEmailDataWithModel:(ModelEmail *)emailData forUserId:(long)userId entity:(NSString *)entity;

+(NSMutableArray *)fetchEmailsForThreadId:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity;

+(NSMutableArray *)fetchTopEmailForThreadId:(uint64_t)threadId andUserId:(long)userId isTopEmail:(BOOL)isTop isTrash:(BOOL)isTrash entity:(NSString *)etity;

+(int)fetchUnreadCountUserId:(long)userId threadId:(uint64_t)threadId folderType:(int)folderType entity:(NSString *)entity;

+ (NSMutableArray *)fetchFavoriteEmailsForUserId:(long)userId withFetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)isSearching searchingString:(NSString *)text;

+ (NSMutableArray *)fetchEmailsForGivenStartDate:(NSDate *)date endDate:(NSDate *)endate andUserId:(long)userId ithFetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)searching text:(NSString *)text;

+ (NSUInteger )fetchEmailsCountForGivenStartDate:(NSDate *)date endDate:(NSDate *)endate andUserId:(long)userId;

+ (NSUInteger)fetchFavoriteCountUserId:(long)userId;

+(NSMutableArray *)fetchUnreadEmailsForUserId:(long)userId fetchLimit:(NSUInteger)fetchLimit andFetchOffset:(NSUInteger)fetchOffset isSearching:(BOOL)searching text:(NSString *)text;

+ (NSUInteger )fetchUnreadCountForUserId:(long)userId;

+ (NSFetchedResultsController *)initFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent entity:(NSString *)entityName;

+ (NSFetchedResultsController *)fetchedFavoriteEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text;

+ (NSFetchedResultsController *)fetchedTrashEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text entity:(NSString *)entity;

+ (NSMutableArray *)fetchSingleEmailForUniqueId:(uint64_t)uniqueId andUserId:(long)userId;

+ (NSFetchedResultsController *)fetchedSentEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text entity:(NSString *)entityName;

+ (NSMutableArray *)fetchThreadForId:(uint64_t)threadId userId:(long)userId;
+ (NSFetchedResultsController *)fetchedRegularEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent isInbox:(BOOL)inbox isConversation:(BOOL)conversation isTrash:(BOOL)trash isSnoozed:(BOOL)snoozed fetchReadOnly:(BOOL)needReadOnly entity:(NSString *)entityName;

+ (NSFetchedResultsController *)fetchedUnreadEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text;

+ (void)saveQuickResponsesWithSnapshot:(FIRDataSnapshot *)dataSnapshot;
+ (void)saveSnoozePreferencesWithData:(NSMutableDictionary *)dictionary;
+ (void)saveSendLaterPreferencesWithData:(NSMutableDictionary *)dictionary;

+ (NSMutableArray *)fetchQuickResponsesForEmail:(NSString *)email;
+ (NSMutableArray *)fetchQuickResponseForFirebaseId:(NSString *)firebaseId;
+ (NSMutableArray *)fetchUserIdForEmail:(NSString *)email;
+ (NSMutableArray *)fetchSnoozePreferencesForBool:(BOOL)isDeafult emailId:(NSString *)email;
+ (NSMutableArray *)fetchActiveSnoozePreferencesForBool:(BOOL)isDeafult emailId:(NSString *)email;
+ (NSMutableArray *)fetchSendlaterPreferencesForBool:(BOOL )isDeafult emailId:(NSString *)email;
+ (NSMutableArray *)fetchSnoozePreferenceForFirebaseId:(NSString *)firebaseId ;
+ (NSMutableArray *)fetchSendlaterPreferencesForFirebaseId:(NSString *)firebaseId;

+ (NSFetchedResultsController *)fetchedSnoozedEmailsForController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text;
+ (NSMutableArray *)fetchEmailWithId:(uint64_t)emailId userId:(long)userId entity:(NSString *)entity;
+ (NSMutableArray*)fetchAutocompleteDataforString:(NSString *)str userId:(NSString *)userId;
+ (NSMutableArray*)fetchAutocompleteContactsforString:(NSString *)str userId:(NSString *)userId;
+ (void)mapContactData:(int)priority title:(NSString *)emailTitle name:(NSString *)name;
+ (NSError* )wipeUser:(NSString *)userId;
+ (void)mapEmailInfo:(ModelEmailInfo *)emailInfo;
+ (BOOL)isEmailExist:(long)userId emailUid:(uint64_t)uid;
+ (BOOL)isEmailInfoExist:(long )userId emailUid:(uint64_t)uid;
+ (NSMutableArray*)fetchEmailInfo:(uint64_t)unId userId:(long)userId;
+ (NSFetchedResultsController *)initArchiveFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forUser:(long)userId isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft;

+ (NSUInteger)fetchInboxEmailsCountForUserId:(long)userId  isSearching:(BOOL)isSearching searchText:(NSString *)text fetchArchive:(BOOL)fetchArchive fetchDraft:(BOOL)fetchDraft isSent:(BOOL)sent isInbox:(BOOL)inbox isConversation:(BOOL)conversation isTrash:(BOOL)trash isSnoozed:(BOOL)snoozed;
+ (NSMutableArray *)fetchLatestTopEmailForUserId:(long)userId;
+ (NSUInteger)isGmailMessageIdExist:(uint64_t)gmailMessageId forUserId:(long)userId;
+ (NSMutableArray *)fetchLatestDraftEmailForUserId:(long)userId;
+ (NSMutableArray *)fetchLatestTrashEmailForUserId:(long)userId;
+ (NSMutableArray *)fetchLatestSentEmailForUserId:(long)userId;
+(NSMutableArray *)getEmailsForThreadId:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly entity:(NSString *)entity;
+(void)saveFakeDraft:(ModelEmail *)emailData forUserId:(long)userId subject:(NSString *)subject preview:(NSString *)preview fakeId:(long)fakeId;
+(NSMutableArray *)fetchAllFakeDrafts;
+(NSMutableArray *)fetchFakeDraftForId:(long)cloneId;
+(NSFetchedResultsController *)initThreadFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController threadId:(uint64_t)threadId andUserId:(int)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity;
+(NSMutableArray *)fetchSingleEmailForUniqueIdInTrash:(uint64_t)uniqueId andUserId:(long)userId;
+(NSMutableArray *)fetchSingleEmailForUniqueIdInArchive:(uint64_t)uniqueId andUserId:(long)userId;
+(NSMutableArray *)fetchSingleEmailForUniqueIdForInbox:(uint64_t)uniqueId andUserId:(long)userId;
+(NSUInteger)isThreadExist:(uint64_t)threadId forUserId:(long)userId;
+(NSMutableArray *)fetchAllthreads ;
+(NSUInteger)fetchTop;
+(NSMutableArray *)fetchThread:(uint64_t)threadId userId:(long)userId;
+(NSMutableArray *)fetchSingleThreadForId:(uint64_t)threadId userId:(long)userId;
+(NSMutableArray *)fetchCompleteThread:(uint64_t)threadId userId:(long)userId;
+(NSError *)deleteAllTrash:(NSString *)userId;
+(void)mapHistoryData:(NSDate *)date title:(NSString *)title isRecent:(BOOL)isRecent;
+(NSMutableArray *)isHistoryStringExist:(NSString *)str isRecent:(BOOL)isRecent;
+(NSMutableArray*)fetchHistory:(BOOL)isRecent;
+ (NSError *)deleteAllEntities:(NSString *)nameEntity;
+(void)mapAttachmentDataWithModel:(ModelAttachments *)attachmentsData entity:(NSString *)entity;
+(NSMutableArray *)getAttachment:(long)userId emailUid:(uint64_t)emailUid entity:(NSString *)entity;
+(NSMutableArray *)fetchThreadData:(uint64_t)threadId andUserId:(long)userId folderType:(int)folderType needOnlyIds:(BOOL)needIdsOnly isSnoozed:(BOOL)snoozed entity:(NSString *)entity;


+(void)deleteAllEmails;

@end
