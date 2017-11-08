//
//  EmailDetailViewController.m
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "EmailDetailViewController.h"

#import "Utilities.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "MCOIMAPSessionManager.h"
#import "FileAttachmentTableViewCell.h"
#import "EmailComposerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "MailCoreServiceManager.h"
#import "MessageDetailView.h"
#import "SnoozeView.h"
#import "LocalNotificationManager.h"
#import "DatePickerView.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "CustomizeSnoozesViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "SharedInstanceManager.h"
#import "ArchiveManager.h"

@interface EmailDetailViewController ()

@end

@implementation EmailDetailViewController {
    NSString * userId;
    MBProgressHUD *hud;
    NSString * currentEmail;
    SnoozeView * snoozeView;
    NSURL * coreDataObjectId;
    BOOL snoozedOnlyIfNoReply;
    NSString * emailReceiverId;
    BOOL isViewDismissed;
    DatePickerView * datePickerView;
    MessageDetailView *  messageDetailView;
    MCOIMAPSessionManager * imapSessionManager;
    LocalNotificationManager * localNotificationManager;
    MCOIMAPFetchContentOperationManager * contentFetchManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isViewDismissed = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[CoreDataManager getManagedObjectContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEmailNotificationReceived:) name:kNEW_EMAIL_NOTIFICATION object:nil];
    
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    UIBarButtonItem * btnNavClock=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_clock"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(btnNaviClockAction:)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnNavClock, nil];
    [self.fileAtachmentTable setBackgroundView:nil];
    [self.fileAtachmentTable setBackgroundColor:[UIColor clearColor]];
    [self setupView];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.folderType == kFolderTrashMail) {
        self.blurImageBottom.constant =  -100.0f;
        self.blurViewBottom.constant = -100.0f;
    }
    else {
        self.blurImageBottom.constant = 0.0f;
        self.blurViewBottom.constant = 0.0f;
    }
    [self.view layoutIfNeeded];
}
-(void)setupView {
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    if (self.object != nil) {
        long uid = [[self.object valueForKey:kUSER_ID] integerValue];
        userId = [NSString stringWithFormat:@"%ld", uid];
        coreDataObjectId = [[self.object objectID] URIRepresentation];
    }
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    NSManagedObject * obj = [userArray lastObject];
    currentEmail = [obj valueForKey:kUSER_EMAIL];
    NSManagedObject * emailOwnerObj = nil;
    /* when new email notification tapped, below code will execute */
    if (self.isViewPresented && self.pushDatadictionary != nil) {
        
        [SharedInstanceManager sharedInstance].isEmailDetailOpened = YES;
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
        self.edgesForExtendedLayout = UIRectEdgeNone;
        UIBarButtonItem * btnLeftCross = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(btnLeftCrossAction:)];
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:btnLeftCross, nil];
        NSString * uid = [self.pushDatadictionary objectForKey:@"decimal_id"];
        if (![Utilities isValidString:uid]) {
            [self dismissPresentedView];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Email not found." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            return;
        }
        NSString * receiverEmail = [self.pushDatadictionary objectForKey:@"user_email"];
        NSMutableArray * allUsers = [CoreDataManager fetchAllUsers];
        /* find user id */
        for (NSManagedObject * user in allUsers) {
            NSString * userEmail = [user valueForKey:kUSER_EMAIL];
            if ([userEmail isEqualToString:receiverEmail]) {
                emailReceiverId = [user valueForKey:kUSER_ID];
                emailOwnerObj = user;
                break;
            }
        }
        uint64_t emailUniqueId = [uid longLongValue];
        /* check if app already got new email
         if yes than dont fetch new email from imap
         just fetch it from db and continue process*/
        if ([CoreDataManager isUniqueIdExist:emailUniqueId forUserId:[emailReceiverId longLongValue] entity:kENTITY_EMAIL]>0) {
            NSMutableArray * emailArray = [CoreDataManager fetchSingleEmailForUniqueId:emailUniqueId andUserId:[emailReceiverId longLongValue]];
            if (emailArray.count>0) {
                self.object = [emailArray lastObject];
                self.modelEmail = [Utilities parseEmailModelForDBdata:self.object];
                self.pushDatadictionary = nil;
                [self setEmailContent];
            }
        }
        else {
            /* this code will execute when new email arrive and it is not
             available in db, we need to fetch it from imap server */
            [self showProgressHudWithTitle:@"Fetching Email"];
        }
        long u = [[emailOwnerObj valueForKey:kUSER_ID] longLongValue];
        userId = [NSString stringWithFormat:@"%ld", u];
        currentEmail = [emailOwnerObj valueForKey:kUSER_EMAIL];
    }
    else {
        [self setEmailContent];
    }
    if (imapSessionManager == nil) {
        imapSessionManager = [[MCOIMAPSessionManager alloc] init];
    }
    imapSessionManager.delegate = self;
    if (emailOwnerObj == nil) {
        [imapSessionManager createImapSessionWithUserData:obj];
        return;
    }
    [imapSessionManager createImapSessionWithUserData:emailOwnerObj];
}
- (void)handleDataModelChange:(NSNotification *)note {
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSArray * dataArray = [deletedObjects allObjects];
    for (NSManagedObject * emailObject in dataArray) {
        if ([[[emailObject objectID] URIRepresentation] isEqual:coreDataObjectId]) {
            if (isViewDismissed == NO) {
                //UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!!" message:@"This message has been removed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //[av show];
                [self popToRoot];
            }
        }
    }
}
-(void)newEmailNotificationReceived:(NSNotification *)anote {
    self.pushDatadictionary = [anote userInfo];
    [self removeDelegates];
    [self setupView];
}
-(void)removeDelegates {
    if (contentFetchManager) {
        contentFetchManager.delegate = nil;
        contentFetchManager = nil;
    }
    if (imapSessionManager) {
        imapSessionManager.delegate = nil;
        imapSessionManager = nil;
    }
    if (snoozeView) {
        snoozeView.delegate = nil;
        snoozeView = nil;
    }
}
-(void)popToRoot {
    isViewDismissed = YES;
    if (self.isViewPresented) {
        [self dismissPresentedView];
        return;
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}
-(void)fetchEmailFromServerWithSession:(MCOIMAPSession *)session {
    NSString * uid = [self.pushDatadictionary objectForKey:@"decimal_id"];
    uint64_t mId = [uid longLongValue];
    
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:kFOLDER_INBOX expression: [MCOIMAPSearchExpression searchGmailMessageID:mId]];
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        if (error == nil) {
            if (indexSet.count>0) {
                [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:indexSet fromFolder:kFOLDER_INBOX withSessaion:session requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
                    long usrId = [userId longLongValue];
                    if (error == nil) {
                        if (messages.count>0) {
                            
                            MCOIMAPMessage *msg = [messages lastObject];
                            if ([CoreDataManager isThreadIdExist:[msg gmailThreadID] forUserId:usrId forFolder:kFolderAllMail entity:kENTITY_EMAIL]>0) {
                                NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[msg gmailThreadID] andUserId:usrId isTopEmail:NO isTrash:NO entity:kENTITY_EMAIL];
                                
                                int unreadCount = 0;
                                if ( msg.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                NSArray * typeArray = [Utilities getMessageTypes:msg userId:usrId currentEmail:currentEmail];
                                BOOL isInbox = [[typeArray objectAtIndex:0] boolValue];
                                BOOL isSent = [[typeArray objectAtIndex:1] boolValue];
                                BOOL isConvo = [[typeArray objectAtIndex:2] boolValue];
                                BOOL isThreadTop = NO;
                                
                                if (array.count>0) { /* update old top thread */
                                    
                                    NSManagedObject * obj = [array objectAtIndex:0];
                                    
                                    BOOL isDate1Later = [Utilities isDate:msg.header.date isLatestThanDate:(NSDate *)[obj valueForKey:kEMAIL_DATE]];
                                    if (isDate1Later) {
                                        
                                        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_THREAD_TOP_EMAIL];
                                    }
                                    else {
                                        isThreadTop = YES;
                                    }
                                    
                                    [CoreDataManager updateData];
                                }
                                
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:isThreadTop mailFolderName:kFOLDER_INBOX isSent:isSent isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:isConvo isInbox:isInbox userId:userId isFakeDraft:NO enitity:kENTITY_EMAIL];
                                
                                
                                [Utilities markSnoozedAndFavorite:msg userId:usrId isInboxMail:YES];
                            }
                            else { /* single email */
                                int unreadCount = 0;
                                if ( msg.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:NO mailFolderName:kFOLDER_INBOX isSent:NO isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:NO isInbox:YES userId:userId isFakeDraft:NO enitity:kENTITY_EMAIL];
                                
                                
                                [Utilities markSnoozedAndFavorite:msg userId:usrId isInboxMail:YES];
                            }
                            
                            NSMutableArray * emailArray = [CoreDataManager fetchSingleEmailForUniqueId:mId andUserId:usrId];
                            if (emailArray.count>0) {
                                self.object = [emailArray lastObject];
                                coreDataObjectId = [[self.object objectID] URIRepresentation];
                                self.modelEmail = [Utilities parseEmailModelForDBdata:self.object];
                                self.pushDatadictionary = nil;
                                [self setEmailContent];
                            }
                        }
                    }
                    else {
                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [av show];
                        [self dismissPresentedView];
                    }
                }onError:^(NSError* error) {
                }];
            }
        }
        else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            [self dismissPresentedView];
        }
    }];
}
-(void)dismissPresentedView {
    [SharedInstanceManager sharedInstance].isEmailDetailOpened = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma - mark Private Methods

-(void)setEmailContent {
    if (self.modelEmail) {
        [self.imgProfile sd_setImageWithURL:[NSURL URLWithString:self.modelEmail.senderImageUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
        MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[self.object valueForKey:kMESSAGE_INSTANCE]];
        
        MCOAddress * mcoAddress = message.header.from;
        NSString * name = mcoAddress.displayName;
        if (![Utilities isValidString:name]) { /* if sender name nil,
                                                set email as name */
            name = self.modelEmail.emailTitle;
        }
        if (self.modelEmail.isSent) {
            NSString * names = [Utilities getToNamesString:self.object];
            if (names != nil) {
                name = names;
            }
        }
        self.lblName.text = name;
        self.lblTime.text = [Utilities getStringFromDate:self.modelEmail.emailDate withFormat:@"MMMM d"];
        if ([Utilities isValidString:self.modelEmail.emailHtmlPreview]) {
            [self.object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
            [CoreDataManager updateData];
            [self loadWebViewWithHtmlContent:self.modelEmail.emailHtmlPreview];
        }
        else {
            if (contentFetchManager == nil) {
                if (!self.isViewPresented) {
                    [self showProgressHudWithTitle:@"Fetching Email Body"];
                }
                [self initBodyFetchManager];
            }
        }
    }
}

-(void)setZoomLevelForWebview:(UIWebView *)webView {
    CGSize contentSize = webView.scrollView.contentSize;
    CGSize viewSize = webView.bounds.size;
    
    float rw = viewSize.width / contentSize.width;
    
    webView.scrollView.minimumZoomScale = rw;
    webView.scrollView.maximumZoomScale = rw;
    webView.scrollView.zoomScale = rw;
    //float rw2 = viewSize.height / contentSize.height;
    // webView.scrollView.contentSize = CGSizeMake(contentSize.width, contentSize.height*rw2);
}
-(void)showToastWithMessage:(NSString *)message {
    
    UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil, nil];
    [toast show];
    int duration = 1; // duration in seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
}
-(void)loadWebViewWithHtmlContent:(NSString *)content {
    self.mailContentWebView.scalesPageToFit = YES;
    self.mailContentWebView.dataDetectorTypes = UIDataDetectorTypeAll;
    self.mailContentWebView.contentMode = UIViewContentModeScaleAspectFit;
    //[self.mailContentWebView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
    if (content == nil) {
        [self.mailContentWebView loadHTMLString:@"" baseURL:nil];
        return;
    }
    
    NSMutableString * html = [NSMutableString string];
    [html appendFormat:@"<html><head><script>%@</script><style>%@</style></head>"
     @"<body>%@</body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'>"
     @"</iframe></html>", mainJavascript, mainStyle, content];
    self.mailContentWebView.delegate = self;
    [self.mailContentWebView loadHTMLString:html baseURL:nil];
}
-(void)initBodyFetchManager {
    contentFetchManager = [[MCOIMAPFetchContentOperationManager alloc] init];
    contentFetchManager.delegate = self;
    [contentFetchManager createFetcherWithUserId:userId];
}
-(void)showProgressHudWithTitle:(NSString *)title {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
}
-(void)hideProgressHud {
    if (hud) {
        [hud hideAnimated:YES];
    }
}

-(void)openComposerWithMessageType:(int)messageType {
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @" ";
    emailComposerViewController.draftObject = self.object;
    emailComposerViewController.mailType = messageType;
    emailComposerViewController.isDraft = NO;
    
    //    if (self.isViewPresented) {
    //        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //
    //        [appDelegate.viewController.presentedViewController presentViewController:emailComposerViewController animated:YES completion:nil];
    //        return;
    //    }
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}
-(void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object {
    NSString * firebaseFavoriteId = [object valueForKey:kFAVORITE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseFavoriteId]) {
        [Utilities syncToFirebase:nil syncType:[FavoriteEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kFAVORITE_FIREBASE_ID]];
    }
    
    NSString * firebaseSnoozedId = [object valueForKey:kSNOOZED_FIREBASE_ID];
    if ([Utilities isValidString:firebaseSnoozedId]) {
        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kSNOOZED_FIREBASE_ID]];
    }
}
-(void)deleteEmail {
    NSString * folderName  = [self.object valueForKey:kMAIL_FOLDER];
    
    MCOIndexSet * indexSet = [[MCOIndexSet alloc] init];
    [indexSet addIndex:[[self.object valueForKey:kEMAIL_ID] longLongValue]];
    
    
    NSString * threadId = [self.object valueForKey:kEMAIL_THREAD_ID];
    long threadCount = [CoreDataManager isThreadIdExist:[threadId longLongValue] forUserId:[userId longLongValue] forFolder:kFolderAllMail entity:kENTITY_EMAIL];
    
    [self.object setValue:[NSNumber numberWithBool:YES] forKey:kIS_TRASH_EMAIL];
    [CoreDataManager updateData];
    if (self.isViewPresented) {
        [self dismissPresentedView];
    }
    else {
        if (threadCount>1) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        isViewDismissed = YES;
    }
    
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:userId];
    if (imapSession != nil) {
        [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:kFOLDER_TRASH_MAILS completionBlock:^(id response) {
            //[self hideProgressHud];
            dispatch_async(dispatch_get_main_queue(), ^{
                //                NSDictionary * dictionary = (NSDictionary *)response;
                
                //                NSString * oldId = [self.object valueForKey:kEMAIL_ID];
                //                long newId = [[dictionary objectForKey:oldId] longLongValue];
                //                [self.object setValue:[NSNumber numberWithLong:newId] forKey:kEMAIL_ID];
                //                [self.object setValue:[NSNumber numberWithBool:YES] forKey:kIS_TRASH_EMAIL];
                //                [self.object setValue:kFOLDER_TRASH_MAILS forKey:kMAIL_FOLDER];
                //                [CoreDataManager updateData];
                //
                
                if (threadCount>0 ) {
                    if (threadCount == 1) { /* delete from firebase only if single email*/
                        [self syncDeleteActionToFirebaseWithObject:self.object];
                    }
                    
                    NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[threadId longLongValue] andUserId:[userId longLongValue] isTopEmail:YES isTrash:NO entity:[self.object entity].name];
                    if (array.count>0) {
                        NSManagedObject *obj = [array lastObject];
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_THREAD_TOP_EMAIL];
                        [CoreDataManager updateData];
                    }
                }
                
                // delete email
                [CoreDataManager deleteObject:self.object];
                [CoreDataManager updateData];
                
            });
        } onError:^( NSError * error) {
            [self.object setValue:[NSNumber numberWithBool:NO] forKey:kIS_TRASH_EMAIL];
            [CoreDataManager updateData];
            //[self hideProgressHud];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot delete message!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        }];
    }
}

-(void)showSubView {
    if([snoozeView isDescendantOfView:self.view]) {
        [snoozeView removeFromSuperview];
    }
    else {
        int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
        BOOL isDeafult = NO;
        if (value == 1) {
            isDeafult = YES;
        }
        
        NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
        
        for (int i = 0; i<array.count; ++i) {
            NSManagedObject * object = [array objectAtIndex:i];
            int preferenceId = [[object valueForKey:kPREFERENCE_ID] intValue];
            int hour = [[object valueForKey:kSNOOZE_HOUR_COUNT] intValue];
            int minutes = [[object valueForKey:kSNOOZE_MINUTE_COUNT] intValue];
            
            if (preferenceId == 2) {
                NSDate * date = [Utilities addComponentsToDate:[NSDate date] day:0 hour:hour minute:minutes];
                BOOL is = [Utilities isDate:[NSDate date] isLatestThanDate:date];
                if (is) {
                    [array removeObjectAtIndex:i];
                }
                break;
            }
        }
        [snoozeView setDataSource:array];
        [snoozeView setButtonTitles:@"Customize" buttonTitle2:@"Cancel"];
        [snoozeView setTableViewType:1];
        [snoozeView setTableViewCellHeight:44.5f];
        [snoozeView setViewXvalue:69.5f];
        [snoozeView setViewTitle:@"Snooze Until"];
        [snoozeView setViewHeight:399.5f screenHeight:self.view.frame.size.height];
        [self.view addSubview:snoozeView];
        snoozeView.translatesAutoresizingMaskIntoConstraints = NO;
        [Utilities setLayoutConstarintsForView:snoozeView forParent:self.view topValue:0.0f];
    }
}
-(void)archiveEmails {
    if (![Utilities isInternetActive]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet error!"
                                                        message:@"Please check your internet connection and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSString * threadId = [self.object valueForKey:kEMAIL_THREAD_ID];
    NSEntityDescription * des = [self.object entity];
    
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[threadId longLongValue] andUserId:[userId longLongValue] folderType:kFolderAllMail needOnlyIds:NO entity:des.name];
    
    for (NSManagedObject * obj in emailIdArray) {
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:userId];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:[userId longLongValue] emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:userId markArchive:YES threadId:[threadId longLongValue] entity:des.name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:[userId longLongValue]];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        
                        for (NSManagedObject * object in emailIdArray) {
                            /* change folder name to [Gmail]/All Mail if email belong to INBOX */
                            NSString * folderName = [object valueForKey:kMAIL_FOLDER];
                            if ([folderName isEqualToString:kFOLDER_INBOX]) {
                                [object setValue:kFOLDER_ALL_MAILS forKey:kMAIL_FOLDER];
                            }
                            [self syncDeleteActionToFirebaseWithObject:object];
                        }
                        [CoreDataManager updateData];
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
    [self.navigationController popToRootViewControllerAnimated:YES];
    isViewDismissed = YES;
}

#pragma - mark User Actions
-(IBAction)btnNaviClockAction:(id)sender {
    [self showSubView];
    
    /* if (self.blurImageBottom.constant == 0.0f) {
     self.blurImageBottom.constant = -self.imgBlur.frame.size.height;
     self.blurViewBottom.constant = -self.imgBlur.frame.size.height;
     }
     else {
     self.blurImageBottom.constant = 0.0f;
     self.blurViewBottom.constant = 0.0f;
     }
     [self.view setNeedsUpdateConstraints];
     
     [UIView animateWithDuration:0.25f animations:^{
     [self.view layoutIfNeeded];
     }];*/
}
-(IBAction)btnArchiveAction:(id)sender {
    [self archiveEmails];
}
-(IBAction)btnLeftCrossAction:(id)sender {
    [self dismissPresentedView];
}
-(IBAction)btnReplyAction:(id)sender {
    MCOIMAPMessage * message = [Utilities getUnArchivedArrayForObject:[self.object valueForKey:kMESSAGE_INSTANCE]];
    long count = message.header.to.count + message.header.cc.count;
    
    if (count>1) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select reply type"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Reply", @"Reply All", nil];
        actionSheet.tag = 1021;
        [actionSheet showInView:self.view];
    }
    else {
        [self openComposerWithMessageType:kReply];
    }
}
-(IBAction)btnForwardAction:(id)sender {
    [self openComposerWithMessageType:kForward];
}
-(IBAction)btnDeleteAction:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete this message?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Delete anyway", nil];
    actionSheet.tag = 101;
    [actionSheet showInView:self.view];
}
-(IBAction)btnFavoriteAction:(id)sender {
    if ([[self.object valueForKey:kIS_FAVORITE] boolValue]) {
        [self showToastWithMessage:@"✰✰ Already Marked Favorite ✰✰"];
    }
    else {
        NSMutableDictionary * dictionary = [Utilities getDictionaryFromObject:self.object email:currentEmail isThread:YES dictionaryType:kTypeFavorite nsdate:0];
        
        [Utilities syncToFirebase:dictionary syncType:[FavoriteEmailSyncManager class] userId:userId performAction:kActionInsert firebaseId:nil];
        
        /* [self.object setValue:[NSNumber numberWithBool:YES] forKey:kIS_FAVORITE];
         [CoreDataManager updateData];*/
        [self showToastWithMessage:@"✰✰ Favorite Marked ✰✰"];
    }
}
-(IBAction)btnDetailAction:(id)sender {
    UIButton * btn = (UIButton *)sender;
    
    if([messageDetailView isDescendantOfView:self.view]) {
        [messageDetailView hideView];
    }
    else {
        [btn setTitle:@"Hide Detail" forState:UIControlStateNormal];
        messageDetailView = [[[NSBundle mainBundle] loadNibNamed:@"MessageDetailView" owner:self options:nil] objectAtIndex:0];
        [messageDetailView setDelegate:self];
        
        messageDetailView.dataArray = [Utilities fillArrayForMessageDetail:self.object];
        messageDetailView.date = self.modelEmail.emailDate;
        messageDetailView.profileImageUrl = [self.object valueForKey:kSENDER_IMAGE_URL];
        [messageDetailView setupView];
        [self.view addSubview:messageDetailView];
        messageDetailView.translatesAutoresizingMaskIntoConstraints = NO;
        [Utilities setLayoutConstarintsForView:messageDetailView forParent:self.view topValue:55.0f];
    }
}

#pragma - mark UITableView data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"FileAttachmentCell";
    
    FileAttachmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FileAttachmentTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.viewSep.hidden = NO;
    if (indexPath.row == 0) {
        cell.imgFile.image = [UIImage imageNamed:@"file_attach_1"];
        cell.lblFileName.text = @"Snoozed Structure.zip";
    }
    else if (indexPath.row == 1) {
        cell.imgFile.image = [UIImage imageNamed:@"file_attach_2"];
        cell.lblFileName.text = @"Snoozed_Elements.psd";
    }
    else {
        cell.imgFile.image = [UIImage imageNamed:@"file_attach_3"];
        cell.lblFileName.text = @"Timeline.xls";
        cell.viewSep.hidden = YES;
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
#pragma - mark UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
#pragma - mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    [self loadWebViewWithHtmlContent:htmlBody];
    [self.object setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_BODY];
    
    if ([messagePreview length]>=50) {
        messagePreview = [messagePreview substringToIndex:50];
    }
    [self.object setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    [self.object setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    [self.object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
    [CoreDataManager updateData];
    [self hideProgressHud];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    [self hideProgressHud];
    // UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Something went wrong!!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    // [alert show];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    if (contentFetchManager != nil) {
        [contentFetchManager startFetchOpWithFolder:self.modelEmail.emailFolderName andMessageId:(int)self.modelEmail.emailId forNSManagedObject:self.object nsindexPath:nil needHtml:YES];
    }
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
    if (self.pushDatadictionary != nil) {
        [self fetchEmailFromServerWithSession:self.imapSession];
        return;
    }
    if (self.modelEmail.unreadCount>0) {
        [self markReadUid:self.modelEmail.emailId forFolder:self.modelEmail.emailFolderName withSessaion:self.imapSession];
    }
    else{
        imapSessionManager.delegate = nil;
    }
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    [self hideProgressHud];
}

-(void)markReadUid:(long)uid forFolder:(NSString *)folderName withSessaion:(MCOIMAPSession *)session {
    MCOIMAPOperation *msgOperation = [session storeFlagsOperationWithFolder:folderName
                                                                       uids:[MCOIndexSet indexSetWithIndex:uid]
                                                                       kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
    [msgOperation start:^(NSError * error) {
        if (error == nil) {
            NSLog(@"Marked Seen.............");
            [self.object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
            [CoreDataManager updateData];
        }
        else {
            [self.object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
            [CoreDataManager updateData];
            NSLog(@"error = %@", error.localizedDescription);
        }
        imapSessionManager.delegate = nil;
    }];
}
#pragma - mark UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag == 101) { /* delete action sheet */
        if (buttonIndex == 0) { /* Delete button */
            [self deleteEmail];
        }
        else { /* Cancel button */
            
        }
    }
    else { /* reply action sheet */
        if (buttonIndex == 0) { /* Reply button */
            [self openComposerWithMessageType:kReply];
        }
        else if(buttonIndex == 1) { /* ReplyAll button */
            [self openComposerWithMessageType:kReplyAll];
        }
    }
}

#pragma - mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    //[self setZoomLevelForWebview:theWebView];
}
#pragma - mark MessageDetailViewDelegate
-(void)messageDetailViewDidRemoveFromSuperView {
    [self.btnShowDetail setTitle:@"View Detail" forState:UIControlStateNormal];
    messageDetailView = nil;
}
#pragma mark - SnoozeViewDelegate
- (void) snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply {
    if (viewType == 1) {
        snoozedOnlyIfNoReply = ifNoReply;
        CustomizeSnoozesViewController * customizeSnoozesViewController = [[CustomizeSnoozesViewController alloc] initWithNibName:@"CustomizeSnoozesViewController" bundle:nil];
        [self.navigationController pushViewController:customizeSnoozesViewController animated:YES];
        
    }
}
- (void) snoozeView:(SnoozeView*)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
    snoozedOnlyIfNoReply = ifNoReply;
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
    BOOL isDeafult = NO;
    if (value == 1) {
        isDeafult = YES;
    }
    
    NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
    NSManagedObject * object = [array objectAtIndex:Index];
    int preferenceId = [[object valueForKey:kPREFERENCE_ID] intValue];
    int hour = [[object valueForKey:kSNOOZE_HOUR_COUNT] intValue];
    int minutes = [[object valueForKey:kSNOOZE_MINUTE_COUNT] intValue];
    
    if(preferenceId == 9) { /* open picker */
        [self openPickerViewForIndex:5];
        return;
    }
    [Utilities calculateDateWithHours:hour minutes:minutes preferenceId:preferenceId currentEmail:currentEmail userId:userId emailData:self.object onlyIfNoReply:snoozedOnlyIfNoReply viewType:[view getTableViewType]];
    [self popToRoot];
}
-(void)openPickerViewForIndex:(int)index {
    if (datePickerView == nil) {
        datePickerView = [[[NSBundle mainBundle] loadNibNamed:@"DatePickerView" owner:self options:nil] objectAtIndex:0];
        datePickerView.showHoursPicker = NO;
        [datePickerView setupViewWithTitle:@"Pick Date/Time"];
        datePickerView.delegate = self;
        
    }
    if (index>1) {
        [datePickerView setDatePickerMode:UIDatePickerModeDateAndTime];
    }
    else {
        [datePickerView setDatePickerMode:UIDatePickerModeTime];
    }
    if (index == 1) {
        datePickerView.needToIncrementDay = YES;
        [datePickerView setDatePickerMinimumDate:nil];
    }
    else {
        datePickerView.needToIncrementDay = NO;
        [datePickerView setDatePickerMinimumDate:[NSDate date]];
    }
    [self.view addSubview:datePickerView];
    datePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:datePickerView forParent:self.view topValue:0.0f];
}
#pragma - mark PickerView Delegate
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    [Utilities setEmailToSnoozeTill:date withObject:self.object currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
    [self popToRoot];
}

-(void)dealloc {
    NSLog(@"dealloc : EmailDetailViewController");
    [Utilities destroyImapSession:self.imapSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNEW_EMAIL_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    
    [self removeDelegates];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
