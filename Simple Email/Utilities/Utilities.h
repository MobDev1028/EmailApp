//
//  Utilities.h
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "CoreDataManager.h"
#import "ModelEmail.h"
#import "UIImageView+Letters.h"


@interface Utilities : NSObject

+ (void)setLayoutConstarintsForView:(UIView *)subview forParent:(UIView *)parentView topValue:(float)top;
+ (void)setUserDefaultWithValue:(id)value andKey:(NSString *)key;
+ (id)getUserDefaultWithValueForKey:(NSString *)key;
+ (void)setDefaults;
+ (void)synchDefaults;
+ (void)pushViewController:(UIViewController *)uiviewController animated:(BOOL)animated;
+ (NSString *)getNewKeychainItemName;
+ (BOOL)isValidString:(NSString *)str;
+ (NSString *) getStringFromDate:(NSDate *)date withFormat:(NSString *)formatString;
+ (id) dataToDictionary:(id)data;
+ (NSArray *)parseProfile:(NSDictionary *)dictionary;
+(ModelEmail *)saveEmailModelForMessage:(MCOIMAPMessage *)message unreadCount:(long)unreadCount isThreadEmail:(BOOL)isThread mailFolderName:(NSString *)folderName isSent:(BOOL)isSent isTrash:(BOOL)isTrash isArchive:(BOOL)isArchive isDarft:(BOOL)isDarft draftFetchedFromServer:(BOOL)draftFromServer isConversation:(BOOL)conversation isInbox:(BOOL)isInbox userId:(NSString *)userId isFakeDraft:(BOOL)isFake enitity:(NSString *)entity;
+ (BOOL)isDateInFuture:(NSDate *)date1 ;
+ (NSString *)encodeToBase64:(NSString*)plainString;
+ (NSString *) getSnoozedDateString:(NSDate *)date;
+ (long)getInboxLastFetchCount:(NSString *)user;
+ (void)updateInboxLastFetchCount:(long)fetchCount userId:(NSString *)user;
+ (void)reloadTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation;
+ (void)removeTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation;
+ (void)insertTableViewRows:(UITableView *)tableView forIndexArray:(NSArray *)indexArray withAnimation:(UITableViewRowAnimation)animation;
+ (ModelEmail *)parseEmailModelForDBdata:(NSManagedObject *)object;

+ (NSDate *)resetTimeForGivenDate:(NSDate *)date hours:(int)hours minutes:(int)minutes seconds:(int)seconds;
+ (void) reloadSection:(NSInteger)section forTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)rowAnimation;
+ (BOOL)isInternetActive;
+ (BOOL) NSStringIsValidEmail:(NSString *)checkString;
+ (long)getTrashLastFetchCountForUser:(NSString *)userId;
+ (void)updateTrashLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId;
+ (int)getFolderTypeForString:(NSString*)name;
+ (NSArray *)getIndexSetFromObject:(NSManagedObject *)object;
/*+ (void)saveNewIdsInDBWithDictionary:(NSDictionary *)dictionary isDraft:(BOOL)isDraft isArchive:(BOOL)isArchive isDeleted:(BOOL)isDeleted forThreadId:(uint64_t)threadId userId:(long)userId folderName:(NSString*)folderName;*/
//+ (void)saveArchiceIdsInDBWithIndexSet:(MCOIndexSet *)indexSet isDraft:(BOOL)isDraft isArchive:(BOOL)isArchive isDeleted:(BOOL)isDeleted forThreadId:(uint64_t)threadId userId:(long)userId folderName:(NSString*)folderName;
+ (MCOIMAPMessagesRequestKind)getImapRequestKind;
+ (void)updateArchiveLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId;
+ (long)getArchiveLastFetchCountForUser:(NSString *)userId;
+ (long)getDarftLastFetchCountForUser:(NSString *)userId;
+ (void)updateDarftLastFetchCount:(long)fetchCount  ForUser:(NSString *)userId;
+ (NSData*)getArchivedArray:(id)data;
+ (id)getUnArchivedArrayForObject:(id)object;
+ (long)getSentLastFetchCountForUser:(NSString *)userId;
+ (void)updateSentLastFetchCount:(long)fetchCount  forUser:(NSString *)userId;
+ (BOOL)isThreadContainConversation:(NSArray *)threadMessages forCurrentLoginMail:(NSString *) currentLoginMailAddress;
+ (NSMutableArray *)fillArrayForMessageDetail:(NSManagedObject *)object;
+ (NSMutableArray *)getMessageTypes:(MCOIMAPMessage *)message userId:(long)userId currentEmail:(NSString *)currentEmail;
+ (BOOL)isDate:(NSDate *)date1 isLatestThanDate:(NSDate *)date2;
+ (void)removeDelegatesForViewController:(UIViewController *)vc;
+ (void)setLayoutConstarintsForEditorView:(UIView *)editor parentView:(UIView *)view fromBottomView:(UIView *)bottomView bottomSpace:(float)bottomSpace topView:(UIView *)topView topSpace:(float)topSpace leadingSpace:(float)leadingSpace trailingSpace:(float)trailingSpace;
+ (void)syncToFirebase:(NSMutableDictionary *)data syncType:(id)type userId:(NSString *)uid performAction:(int)action firebaseId:(NSString *)firebaseId;
+ (void)startFirebaseForUserId:(NSString *)uid email:(NSString *)email;
+ (void)preloadQuickResponsesForEmail:(NSString *)email andUserId:(NSString *)uid;
+ (NSMutableDictionary *)getDictionaryFromObject:(NSManagedObject *)object email:(NSString *)email isThread:(BOOL)isThread dictionaryType:(int)type nsdate:(double)date;
+(void)markSnoozedAndFavorite:(MCOIMAPMessage *)message userId:(long )userId isInboxMail:(BOOL)isInboxMail;
+(BOOL)emailHasBeenSnoozedRecently:(NSManagedObject *)object;

+(void)preloadSnoozePreferencesForEmail:(NSString *)email andUserId:(NSString *)uid saveLocally:(BOOL)locally;
+(void)preloadSendLaterPreferencesForEmail:(NSString *)email andUserId:(NSString *)uid saveLocally:(BOOL)locally;

+(NSDate *) getDateOfSpecificDay:(NSInteger ) day;
+(NSDate *)addComponentsToDate:(NSDate *)date day:(int)day hour:(int)hour minute:(int)minute;
+(BOOL)areDaysSameInDates:(NSDate *)date1 date2:(NSDate *)date2;
+(void)setEmailToSnoozeTill:(NSDate *)date withObject:(NSManagedObject *)selectedMailData currentEmail:(NSString *)currentEmail onlyIfNoReply:(BOOL)snoozedOnlyIfNoReply userId:(NSString *)uid;
+(NSDate *)calculateDateWithHours:(int)hour minutes:(int)minutes preferenceId:(int)preferenceId currentEmail:(NSString *)currentEmail userId:(NSString *)userId emailData:(NSManagedObject *)selectedMailData onlyIfNoReply:(BOOL)snoozedOnlyIfNoReply viewType:(int)viewType;
+(NSString *) getEmailDateString:(NSDate *)date1;
+(void)editQuickReponseWithObject:(NSManagedObject *)obj;

+(MCOIMAPSession *)getSessionForUID:(NSString *)userId;
+(void)fetchEmailForUniqueId:(uint64_t)mId session:(MCOIMAPSession *)session userId:(NSString *)uid markArchive:(BOOL)mark threadId:(uint64_t)threadId entity:(NSString *)entity;
+(NSString *)getEmailForId:(NSString *)uid;
+(NSString *)getStringFromInt:(int)value;
+(NSString *)getStringFromLong:(long)value;
+(void)destroyImapSession:(MCOIMAPSession *)session;
+(void)btnSwipeDeleteActionAtIndexPath:(NSManagedObject *)object isSnoozed:(BOOL)isSnoozed;
+(void)btnSwipeArchiveActionAtIndexPath:(NSManagedObject *)object;
+(long)getFakeDraftId;
+(NSString *)getToNamesString:(NSManagedObject *)object;
+(MCOIMAPSession *)getSyncSessionForUID:(NSString *)userId;
+(NSString *) getEmailStringDateForDetailView:(NSDate *)date;
+(void)updateThreadStatus:(uint64_t)threadId userId:(long)userId;
+(NSString *)getDeviceIdentifier;
+(void)saveContacts;
+(NSArray *)getAttachmentListFromPath:(NSString *)fileName;
+(void)clearTmpDirectory;
+(NSMutableArray *)saveAttachmentsToTempPath:(NSMutableArray *)attachments;
+(void)removeFilesFromPaths:(NSMutableArray *)paths;
+(NSString *)getImageNameForMimeType:(NSString *)mime;
+ (NSString *)mimeTypeForData:(NSData *)data;

+ (UIImage *) createImageWithText:(NSString *) text andColor:(UIColor *) color;

+(void) addEmail:(ModelEmail *) email forEntity:(NSString *) entity;
@end
