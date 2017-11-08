//
//  Constants.h
//  SimpleEmail
//
//  Created by Zahid on 02/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define kCLIENT_ID             @"662252151929-nevnqvhaqs8fole6a5f9l5m81dm5nb91.apps.googleusercontent.com"
#define kGOOGLE_API_KEY                                 @"AIzaSyCIjnzDOYswHKySerDzf8gsh8lo4-btBPs"
#define kSTORAGE_REFERENCE                              @"gs://simpleemail-13b1e.appspot.com"
#define kCLIENT_SECRET                                  @""
#define kKEYCHAIN_ITEM_NAME                             @"MailCore_OAuth_2.0_Token_"
#define kNUMBER_OF_MESSAGES_TO_LOAD		                50
#define kUNDO_ACTION_TIME		                        5
#define kSMTP_PORT                                      465
#define kIMAP_PORT                                      993
#define kUSER_NAME_KEY                                  @"user_name";
#define kPASSWORD_KEY                                   @"password";
#define kHOST_NAME_KEY                                  @"imap.gmail.com"
#define kSMTP_HOST_NAME_KEY                             @"smtp.gmail.com"
#define kKEY_COUNT                                      @"key_Count"
#define kFETCH_COUNT                                    @"fetch_Count"
#define kSENT_FETCH_COUNT                               @"sent_fetch_Count"
#define kTRASH_FETCH_COUNT                              @"trash_fetch_Count"
#define kARCHIVE_FETCH_COUNT                            @"archive_fetch_Count"
#define kDRAFT_FETCH_COUNT                              @"deaft_fetch_Count"
#define kSELECTED_ACCOUNT                               @"selected_acCount"
#define kTHREAD_DEC                                     @"decimal_threadId"
#define kIS_DATA_PRELOADED                              @"isPreloaded"
#define isDRAFT_SAVED_ON_SERVER                         @"isDraftSavedOnServer"
#define kNO_SUBJECT_MESSAGE                             @"(no subject)"
#define kPROFILE_API_BASE                               @"http://picasaweb.google.com/data/entry/api/user/"
#define kBASE_URL                                       @"https://simpleemailapp.com/index.php/"
#define kMARK_COMPLETE_THREAD                           @"markCompleteThread"
#define kUSE_DEFAULT                                    @"kUseDefault"
#define kUSE_SENDLATER_DEFAULT                          @"kUseSendLaterDefault"
#define kSNOOZE_PREFERENCE_FIREBASE_ID                  @"snoozePreferenceFirebaseId"

#define kUSER_DEFAULTS_EMAIL_COMPOSED                   @"user_defaults_email_composed"

//NSString *kReachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";
#define kDEVICE_TOKEN                                   @"device_token"

#define kSECRET                                         @"78rwrh87687r6w4h687i687er687ewr867wqr7etiysfgtewqr6"
#define kMAIL_FOLDER                                    @"mailFolder"
#define kIMG_ACCOUNT                                    @"IMG_acCount_"
#define kFETCHING_EMAILS                                @"Fetching Emails"
#define kFETCHING_DRAFTS                                @"Fetching Drafts"
#define kACCOUNT_NAME                                   @"NAME_OF_acCount_"

#define kFOLDER_INBOX                                   @"INBOX"
#define kFOLDER_TRASH_MAILS                             @"[Gmail]/Trash"
#define kFOLDER_SPAM                                    @"[Gmail]/Spam"
#define kFOLDER_DRAFT_MAILS                             @"[Gmail]/Drafts"
#define kFOLDER_ALL_MAILS                               @"[Gmail]/All Mail"
#define kFOLDER_SENT_MAILS                              @"[Gmail]/Sent Mail"
#define kFOLDER_FAVORITE_MAILS                          @"[Gmail]/Favorite"
#define kHIDE_EMAIL                                     @"hideEmail"
#define kUNREAD_MAIL                                    @"mailUNREAD"
#define kFAVORITE_MAIL                                  @"mailFAVOTITE"
#define kYESTERDAY_MAIL                                 @"mailYESTERDAY"
#define kOBSERVER_SNOOZED_NOTIFICATION                  @"com.simple_email_snozzed_notification"
#define kUNIQUE_IDENTIFIER                              @"SIMPLEEMAILuniqueIdentifier"

#define kIMAGE_UPLOADED                                 @"NSNotificationCenter_imageUploaded"
#define kNSNOTIFICATIONCENTER_QUICKREPONSE              @"NSNotificationCenter_QuickResponse"
#define kNSNOTIFICATIONCENTER_FAVORITE                  @"NSNotificationCenter_Favorite"
#define kNSNOTIFICATIONCENTER_NEW_EMAIL                 @"NSNotificationCenter_New_EmailListener"
#define kNSNOTIFICATIONCENTER_UPDATE_CALL               @"NSNotificationCenter_UPDATE_CALL"
#define kNSNOTIFICATIONCENTER_SNOOZE                    @"NSNotificationCenter_Snooze"
#define kNSNOTIFICATIONCENTER_SNOOZE_PREFERENCE         @"NSNotificationCenter_Snooze_preference"
#define kNSNOTIFICATIONCENTER_SEND_LATER                @"NSNotificationCenter_Send_Later"
#define kNSNOTIFICATIONCENTER_LOGOUT                    @"NSNotificationCenter_LOGOUT"
#define kEDITOR_ACTIVE                                  @"simple_email_text_editor_is_active"
#define kINTERNET_AVAILABLE                             @"NSNotificationCenter_INTERNET_AVAILABLE"
#define kNEW_EMAIL_NOTIFICATION                         @"NSNotificationCenter_new_email"
#define kATTACHMENT_DOWNLOADED                          @"AttachmentDownloaded"

#define kNO_DRAFT_AVAILABLE_MESSAGE                     @"You don't have any saved drafts."
#define kNO_TRASH_AVAILABLE_MESSAGE                     @"You don't have any trash emails."
#define kNO_FAVORITE_AVAILABLE_MESSAGE                  @"You don't have any favorite emails."
#define kNO_SENT_AVAILABLE_MESSAGE                      @"You don't have any sent emails."
#define kNO_SNOOZED_AVAILABLE_MESSAGE                   @"You don't have any snoozed emails."
#define kNO_UNREAD_AVAILABLE_MESSAGE                    @"You don't have any unread emails."
#define kEMPTY_INBOX_MESSAGE                            @"Inbox is empty."
#define kNO_RESULTS_MESSAGE                             @"No Results"

// Core Data
/* History Enitity START */
#define kENTITY_HISTORY                                 @"History"
#define kHISTORY_TITLE                                  @"title"
#define kHISTORY_ISRECENT                               @"isRecent"
#define kPRIORITY                                       @"priority"
#define kHISTORY_DATE                                   @"date"

/* User Enitity START */
#define kENTITY_USER                                    @"User"

#define kUSER_ID                                        @"userId"
#define kUSER_NAME                                      @"userName"
#define kUSER_EMAIL                                     @"userEmail"
#define kEXPIRE_DATE                                    @"expireDate"
#define kUSER_IMAGE_URL                                 @"userImageUrl"
#define kREFRESH_TOKEN                                  @"refreshToken"
#define kUSER_OAUTH_ACCESS_TOKEN                        @"userOAuthAccessToken"
#define kUSER_KEYCHANIN_ITEM_NAME                       @"userKeychainItemName"
#define kACCOUNT_TITLE                                  @"accountTitle"
#define kNOTIFICATION_PREFERENCES                       @"notificcationPreference"
#define kNOTIFICATION_SEND_LATER                        @"notificcationSEND_LATER"
/* User Enitity END */

/* Attachments Enitity Start */
#define kENTITY_ATTACHMENTS                             @"Attachments"
#define kATTACHMENT_PATHS                               @"attachmentPaths"
/* EmailInfo Enitity End */



/* EmailInfo Enitity START */
#define kENTITY_EMAIL_INFO                              @"EmailInfo"
/* EmailInfo Enitity END */
#define kENTITY_CONTACTS                                @"Contacts"
#define kENTITY_THREAD                                  @"Thread"
#define kENTITY_SEARCH_EMAIL                            @"SearchEmail"
/* Email Enitity START */
#define kENTITY_EMAIL                                   @"Email"

#define kIS_TRASH_EMAIL                                 @"isTrashEmail"
#define kIS_SENT_EMAIL                                  @"isSentEmail"
#define kIS_Inbox_EMAIL                                 @"isInboxEmail"
#define kEMAIL_DATE                                     @"emailDate"
#define kLATEST_EMAIL_DATE                              @"latestEmailDate"
#define kLATEST_TRASH_EMAIL_DATE                        @"latestTrashEmailDate"
#define kLATEST_SENT_EMAIL_DATE                         @"latestSentEmailDate"
#define kLATEST_DRAFT_EMAIL_DATE                        @"latestDraftEmailDate"
#define kEMAIL_ID                                       @"emailId"
#define kEMAIL_PREVIEW                                  @"emailPreview"
#define kEMAIL_HTML_PREVIEW                             @"messageHtmlBody"
#define kEMAIL_SUBJECT                                  @"emailSubject"
#define kEMAIL_TITLE                                    @"emailTitle"
#define kIS_ATTACHMENT_AVAILABLE                        @"isAttachementAvailable"
#define kIS_FAVORITE                                    @"isFavorite"
#define kIS_SNOOZED                                     @"isSnoozed"
#define kIS_DRAFT                                       @"isDraft"
#define kIS_ARCHIVE                                     @"isArchive"
#define kSENDER_ID                                      @"senderId"
#define kSENDER_IMAGE_URL                               @"senderImageUrl"
#define kNOT_FOUND                                      @"00"
#define kSENDER_NAME                                    @"senderName"
#define kSNOOZED_DATE                                   @"snoozedDate"
#define kSNOOZED_MARKED_AT                              @"snoozedMarkedAt"
#define kSNOOZED_ONLY_IF_NO_REPLY                       @"snoozeIfNoReply"
#define kUNREAD_COUNT                                   @"unreadCount"
#define kTOTAL_UNREAD_THREAD_COUNT                      @"totalUnreadThreadCount"
#define kEMAIL_THREAD_ID                                @"emailThreadId"
#define kIS_THREAD_TOP_EMAIL                            @"isThreadTopEmail"
#define kEMAIL_UNIQUE_ID                                @"emailUniqueId"
#define kEMAIL_BODY                                     @"emailBody"
#define kMESSAGE_INSTANCE                               @"messageInstance"
#define kIS_CONVERSATION                                @"isConversation"
#define kTO_ADDRESSES                                   @"toAddresses"
#define kBCC_ADDRESSES                                  @"bccAddresses"
#define kCC_ADDRESSES                                   @"ccAddresses"
#define kFROM_ADDRESS                                   @"fromAddress"
#define kMAIL_FLAGS                                     @"mailFlags"
#define kFIREBASE_ID                                    @"firebaseId"
#define kSNOOZED_FIREBASE_ID                            @"snoozedFirebaseId"
#define kFAVORITE_FIREBASE_ID                           @"favoriteFirebaseId"
#define kIS_COMPLETE_THREAD_FAVORITE                    @"isCompleteThreadFavorite"
#define kIS_COMPLETE_THREAD_SNOOZED                     @"isCompleteThreadSnoozed"
#define kIS_FAKE_DRAFT                                  @"isFakeDraft"
#define kCC                                             @"Cc:"
#define kBCC                                            @"Bcc:"
#define kCLONE_ID                                       @"cloneId"
#define kDISPLAY_NAME                                   @"displayName"
#define kMAIL_BOX                                       @"mailbox"
#define kATTACHMENT_COUNT                               @"attachmentCount"
/* Email Enitity END */


/* QuickResponse Enitity START */
#define kENTITY_QUICK_RESPONSE                          @"QuickResponse"

#define kQUICK_REPONSE_ID                               @"quickResponseId"
#define kQUICK_REPONSE_Title                            @"quickResponseTitle"
#define kQUICK_REPONSE_Text                             @"quickResponseText"
#define kQUICK_REPONSE_HTML                             @"quickResponseHtml"
#define kQUICK_REPONSE_ATTACHMENT_PATH                  @"quickResponseAttachmentPath"
#define kQUICK_REPONSE_ATTACHMENT_AVAILABLE             @"quickResponseAttachmentAvailable"
/* QuickResponse Enitity END */

/* SnoozePreference Enitity START */
#define kENTITY_SNOOZE_PREFERENCE                       @"SnoozePreference"

#define kSNOOZE_DATE                                    @"snoozeDate"
#define kSNOOZE_TITLE                                   @"snoozeTitle"
#define kIS_PREFERENCE_ACTIVE                           @"isPreferenceActive"
#define kSNOOZE_MINUTE_COUNT                            @"snoozeMinuteCount"
#define kSNOOZE_HOUR_COUNT                              @"snoozeHourCount"
#define kSNOOZE_TIME_PERIOD                             @"timePeriod"
#define kSNOOZE_IS_DEFAULT                              @"isDefault"
#define kPREFERENCE_ID                                  @"preferenceId"
#define kTIME_STRING                                    @"timeString"
#define kIMAGE                                          @"image"

/* SnoozePreference Enitity END */

/* SendLaterPreferences Enitity START */
#define kENTITY_SEND_LATER_PREFERENCES                  @"SendLaterPreferences"
#define kSEND_PREFERENCES_FIREBASEID                    @"sendPreferenceFirebaseId"
#define kSEND_MINUTE_COUNT                              @"sendMinuteCount"
#define kSEND_LATER_TITLE                               @"sendLaterTitle"
#define kSEND_HOUR_COUNT                                @"sendHourCount"
#define kSEND_DATE                                      @"sendDate"
/* SendLaterPreferences Enitity END */


// Colors

#define kCOLOR_SWIPE_CELL_ARCHIVE       [UIColor colorWithRed:64.0f/255.0f green:179.0f/255.0f blue:79.0f/255.0 alpha:1.0f]
#define kCOLOR_SWIPE_CELL_DELETE        [UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f]
#define kCOLOR_SWIPE_CELL_FAVOURITE     [UIColor colorWithRed:82.0f/255.0f green:195.0f/255.0 blue:240.0f/255.0 alpha:1.0f]
#define kCOLOR_SWIPE_CELL_SNOOZE        [UIColor colorWithRed:245.0f/255.0f green:147.0f/255.0f blue:49.0f/255.0f alpha:1.0f]
#define kCOLOR_SWIPE_CELL_READ          [UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f]
#define kCOLOR_SWIPE_CELL_UNREAD        [UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f]
#define kCOLOR_SWIPE_CELL_INBOX         [UIColor colorWithRed:167.0f/255.0f green:102.0f/255.0f blue:166.0f/255.0f alpha:1.0f]

// Images

#define kIMAGE_SWIPE_CELL_ARHIEVE       [UIImage imageNamed:@"btn_swipe_archive"]
#define kIMAGE_SWIPE_CELL_DELETE        [UIImage imageNamed:@"btn_swipe_delete"]
#define kIMAGE_SWIPE_CELL_FAVOURITE     [UIImage imageNamed:@"btn_swipe_favorite"]
#define kIMAGE_SWIPE_CELL_SNOOZE        [UIImage imageNamed:@"btn_swipe_snooze"]
#define kIMAGE_SWIPE_CELL_READ          [Utilities createImageWithText:@"Read" andColor:kCOLOR_SWIPE_CELL_READ]
#define kIMAGE_SWIPE_CELL_UNREAD        [Utilities createImageWithText:@"Unread" andColor:kCOLOR_SWIPE_CELL_UNREAD]
#define kIMAGE_SWIPE_CELL_INBOX         [Utilities createImageWithText:@"Inbox" andColor:kCOLOR_SWIPE_CELL_INBOX]

enum
{
    kSnoozeToday=0,
    kSnoozeTomorrow,
    kSnoozeNextWeek,
    kSnoozeSomeDay,
    kSnoozeInWeek,
    kSnoozePickDate,
};


enum
{
    kFolderAllMail=0,
    kFolderInboxMail,
    kFolderSentMail,
    kFolderTrashMail,
    kFolderDraftMail,
    kFolderArchiveMail,
    kFolderSnoozeMail,
};
enum
{
    kTypeFavorite=0,
    kTypeSnoozed,
    kTypeQuickResponse,
    kTypeSendLater,

};
enum
{
    kActionInsert=0,
    kActionDelete,
    kActionEdit,
    kActionOnce,
    kActionInsertAttachment,
    kActionDeleteAttachment
};
enum
{
    kNewEmail=0,
    kReply,
    kReplyAll,
    kForward,
    kDraft,
};
enum
{
    kMORE_VIEW_TYPE_MSG=0,
    kMORE_VIEW_TYPE_THRD,
};
static NSString * mainJavascript = @"\
var imageElements = function() {\
var imageNodes = document.getElementsByTagName('img');\
return [].slice.call(imageNodes);\
};\
\
var findCIDImageURL = function() {\
var images = imageElements();\
\
var imgLinks = [];\
for (var i = 0; i < images.length; i++) {\
var url = images[i].getAttribute('src');\
if (url.indexOf('cid:') == 0 || url.indexOf('x-mailcore-image:') == 0)\
imgLinks.push(url);\
}\
return JSON.stringify(imgLinks);\
};\
\
var replaceImageSrc = function(info) {\
var images = imageElements();\
\
for (var i = 0; i < images.length; i++) {\
var url = images[i].getAttribute('src');\
if (url.indexOf(info.URLKey) == 0) {\
images[i].setAttribute('src', info.LocalPathKey);\
break;\
}\
}\
};\
";

static NSString * mainStyle = @"\
body {\
font-family: Helvetica;\
font-size: 14px;\
word-wrap: break-word;\
-webkit-text-size-adjust:none;\
-webkit-nbsp-mode: space;\
}\
\
pre {\
white-space: pre-wrap;\
}\
";



#endif /* Constants_h */
