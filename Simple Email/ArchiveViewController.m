//
//  ArchiveViewController.m
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ArchiveViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "Constants.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import "WebServiceManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MBProgressHUD.h"
#import "CellConfigureManager.h"
#import "InboxManager.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SnoozeView.h"
#import "DatePickerView.h"
#import "CustomizeSnoozesViewController.h"
#import "SyncManager.h"
#import "ArchiveManager.h"
#import "SVPullToRefresh.h"

@interface ArchiveViewController () <JZSwipeCellDelegate>

@end

@implementation ArchiveViewController {
    BOOL isSearching;
    NSMutableDictionary * contentFetcherDictionary;
    MBProgressHUD * hud;
    NSIndexPath * didSelectIndexPath;
    InboxManager * inboxManager;
    BOOL isFetchingEmails;
    NSString * userId;
    NSManagedObject * snoozeObject;
    BOOL snoozedOnlyIfNoReply;
    SnoozeView * snoozeView;
    DatePickerView * datePickerView;
    SyncManager * archiveSync;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak ArchiveViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.archiveTableView addPullToRefreshWithActionHandler:^{
        
        [weakSelf fetchResultsFromDbForString:nil];
    }];
    
    // setup infinite scrolling
    [self.archiveTableView addInfiniteScrollingWithActionHandler:^{
        
        [weakSelf fetchResultsFromDbForString:nil];
    }];
    
    
    [self setUpView];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //    if (didSelectIndexPath !=nil ) {
    //        NSArray* indexArray = [NSArray arrayWithObjects:didSelectIndexPath, nil];
    //        [Utilities reloadTableViewRows:self.archiveTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationRight];
    //        didSelectIndexPath = nil;
    //    }
}
#pragma - mark Private Methods
-(void)setUpView {
    [self setActivityIndicatorViewConstant:0.0f];
    undoThreadId = nil;
    [self refreshServices];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshServices)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    
    snoozeView  =   [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    /* [self startFetchingTrashMails]; */
    [self contentFetcherWithBool:YES];
    [self fetchResultsFromDbForString:nil];
    
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    
    //[self.txtSearchField addTarget:self action:@selector(searchTextFieldContent:) forControlEvents:UIControlEventEditingChanged];
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.archiveTableView setBackgroundView:nil];
    [self.archiveTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Archive";
    
    UIBarButtonItem * btnNavSearch=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavigationSearchAction:)];
    
    self.navigationItem.rightBarButtonItem = btnNavSearch;
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:revealController
                                                             action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVisibleRows:) name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
}
- (void)updateVisibleRows:(NSNotification *)notification {
    NSString * strId = [notification.userInfo valueForKey:kUSER_ID];
    long longUserId = [strId longLongValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
}
-(void)addUndoActionForSnooze {
    [self setActivityIndicatorViewConstant:30.0f];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    self.lblUndo.text = @"Marked snoozed";
    uint64_t longThreadId = [[snoozeObject valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_snooze" forKey:@"actiontype"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}
-(void)refreshServices {
    if (archiveSync != nil) {
        archiveSync.invalidateTimer = YES;
        archiveSync = nil;
    }
    
    archiveSync = [[SyncManager alloc] init];
    [archiveSync syncEmailForFolder:@"ARCHIVE"];
}
-(void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object {
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
-(void)contentFetcherWithBool:(BOOL)createFetchers {
    NSMutableArray * allUsers = [CoreDataManager fetchAllUsers];
    if (contentFetcherDictionary == nil) {
        contentFetcherDictionary = [[NSMutableDictionary alloc] init];
    }
    for (NSManagedObject * obj in allUsers) {
        long intId = [[obj valueForKey:kUSER_ID] integerValue];
        NSString * strId = [NSString stringWithFormat:@"%ld",intId];
        if (createFetchers) {
            MCOIMAPFetchContentOperationManager * contentFetcher = [[MCOIMAPFetchContentOperationManager alloc] init];
            contentFetcher.delegate = self;
            [contentFetcher createFetcherWithUserId:strId];
            [contentFetcherDictionary setObject:contentFetcher forKey:strId];
        }
        else {
            MCOIMAPFetchContentOperationManager * contentFetcher = [contentFetcherDictionary objectForKey:strId];
            if (contentFetcher != nil) {
                contentFetcher.delegate = nil;
                [contentFetcherDictionary removeObjectForKey:strId];
                contentFetcher = nil;
            }
        }
    }
}
-(void)startFetchingTrashMails {
    if (inboxManager == nil) {
        inboxManager = [[InboxManager alloc] init];
    }
    inboxManager.userId = userId;
    inboxManager.totalNumberOfMessagesInDB = [Utilities getArchiveLastFetchCountForUser:userId];
    isFetchingEmails = YES;
    [inboxManager startFetchingMessagesForFolder:kFOLDER_ALL_MAILS andType:kFolderArchiveMail];
    inboxManager.delegate = self;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}
- (void)loadImagesForOnscreenRows {
    
    NSArray *visiblePaths = [self.archiveTableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
        
        NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
        if (imgUrl == nil) {
            // Avoid the app icon download if the app already has an icon
            [self getUserProfileForEmail:[emailData valueForKey:kEMAIL_TITLE] object:emailData indexPath:indexPath];
        }
        if (messagePreview == nil) {
            long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
            NSString * strUid = [Utilities getStringFromLong:usrId];
            NSString * messageId = [emailData valueForKey:kEMAIL_ID];
            NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
            MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
            if (contentFetchManager != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [contentFetchManager startFetchOpWithFolder:folder andMessageId:[messageId intValue] forNSManagedObject:emailData nsindexPath:indexPath needHtml:NO];
                });
            }
        }
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
        snoozeObject = [self.fetchedResultsController objectAtIndexPath:self.swipeIndexPath];
        long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [Utilities getEmailForId:strUid];
        
        NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:mail]];
        
        /* calculate date for evening
         if date/time of evening is in past
         dont bother yourself to show it in list*/
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

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
-(void)openPickerViewForIndex:(int)index {
    if (datePickerView == nil) {
        datePickerView = [[[NSBundle mainBundle] loadNibNamed:@"DatePickerView" owner:self options:nil] objectAtIndex:0];
        datePickerView.showHoursPicker = NO;
        [datePickerView setupViewWithTitle:@"Pick Date/Time"];
        datePickerView.delegate = self;
    }
    if (index>1) {
        [datePickerView setDatePickerMode:UIDatePickerModeDateAndTime ];
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
-(void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_delete" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Delete marked";
    [self markDeleteMessageLocally:emailIdArray flag:YES];
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    
}
-(void)markDeleteMessageLocally:(NSMutableArray*)messages flag:(BOOL)flag {
    for (NSManagedObject * object in messages) {
        [object setValue:[NSNumber numberWithBool:flag] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
    }
}
-(void)markDeleteOnServer:(NSMutableArray*)messages {
    for (NSManagedObject * obj in messages) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
        NSString * entityName = [obj entity].name;
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:kFOLDER_TRASH_MAILS completionBlock:^(id response) {
                NSIndexSet * ind = indexSet.nsIndexSet;
                uint64_t emailUid = ind.firstIndex;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:emailUid userId:usrId entity:entityName];
                
                for (NSManagedObject * object in email) {
                    [self syncDeleteActionToFirebaseWithObject:object];
                    [CoreDataManager deleteObject:object];
                    [CoreDataManager updateData];
                }
            } onError:^( NSError * error) {
                NSIndexSet * ind = indexSet.nsIndexSet;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:ind.firstIndex userId:usrId entity:entityName];
                
                for (NSManagedObject * object in email) {
                    [object setValue:[NSNumber numberWithBool:NO] forKey:kIS_TRASH_EMAIL];
                    [CoreDataManager updateData];
                }
            }];
        }
    }

}
-(void)btnSwipeMarkMessageAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [object valueForKey:kMAIL_FOLDER];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[object valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[object entity].name];
    int markCount = 1;
    if (unreadCount>0) {
        markCount = 0;
    }
    if (markCount == 0) { /* MARK UNREAD HERE */
        self.lblUndo.text = @"Read marked";
    }
    else { /* MARK READ HERE */
        self.lblUndo.text = @"Unread marked";
    }
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
    undoThreadId = strThreadId;
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        for (NSMutableDictionary * dic in self.undoArray) {
            if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_message"]) {
                if ([[dic objectForKey:kEMAIL_THREAD_ID] isEqualToString:strThreadId]) {
                    [self.undoArray removeObject:dic];
                }
            }
        }
        [self performActions:NO];
    }
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_message" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [undoDictionary setObject:[NSString stringWithFormat:@"%d",markCount] forKey:@"mark_count"];
    [self.undoArray addObject:undoDictionary];
    [self markMessageLocally:emailIdArray markCount:markCount];
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}
-(void)markMessageLocally:(NSMutableArray *)array markCount:(int)markCount {
    for (NSManagedObject * obj in array) {
        [obj setValue:[NSNumber numberWithLong:markCount] forKey:kUNREAD_COUNT];
        [CoreDataManager updateData];
    }
}
-(void)markMessageOnServer:(NSMutableDictionary *)undoDictionary {
    NSLog(@"marking on server: %@",undoDictionary);
    NSMutableArray * messages = [undoDictionary objectForKey:@"messages"];
    int markCount = [[undoDictionary objectForKey:@"mark_count"] intValue];
    for (NSManagedObject * obj in messages) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
        [obj setValue:[NSNumber numberWithLong:markCount] forKey:kUNREAD_COUNT];
        [CoreDataManager updateData];
        
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            MCOIMAPStoreFlagsRequestKind req = MCOIMAPStoreFlagsRequestKindAdd;
            if (markCount == 0) { /* MARK UNREAD HERE */
            }
            else { /* MARK READ HERE */
                req = MCOIMAPStoreFlagsRequestKindRemove;
            }
            [[MailCoreServiceManager sharedMailCoreServiceManager] markMessage:indexSet fromFolder:folderName withSessaion:imapSession requestKind:req flagType:MCOMessageFlagSeen completionBlock:^(void) {
            }onError:^(NSError * error) {
                
            }];
        }
    }
}
-(void)btnSwipeArchiveActionAtIndexPath:(NSIndexPath *)indexPath {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSEntityDescription * des = [object entity];
    
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:des.name];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_archive" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Archive marked";
    [self markArchiveMessageLocally:emailIdArray flag:YES];
    
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    
}
-(void)markArchiveMessageLocally:(NSMutableArray*)messages flag:(BOOL)flag {
    for (NSManagedObject * objc in messages) {
        [objc setValue:[NSNumber numberWithBool:flag] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
    }
}
-(void)markArchiveOnServer:(NSMutableArray*)messages {
    
    for (NSManagedObject * obj in messages) {
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            NSArray * array =  [Utilities getIndexSetFromObject:obj];
            MCOIndexSet * indexSet = [array objectAtIndex:1];
            NSString * entity = [obj entity].name;
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:kFOLDER_ALL_MAILS withSessaion:imapSession toFolder:kFOLDER_INBOX completionBlock:^(id response) {
                NSIndexSet * ind = indexSet.nsIndexSet;
                uint64_t emailUid = ind.firstIndex;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:emailUid userId:usrId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [self syncDeleteActionToFirebaseWithObject:object];
                    [CoreDataManager deleteObject:object];
                    
                }
                [CoreDataManager updateData];
            } onError:^( NSError * error) {
                NSLog(@"cannot delete error: %@", error.localizedDescription);
                NSIndexSet * ind = indexSet.nsIndexSet;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:ind.firstIndex userId:usrId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [object setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                    [CoreDataManager updateData];
                }
            }];
        }
    }

}
-(void)fetchResultsFromDbForString:(NSString *)text {

    long usrId = -1;
    
    NSMutableArray * userArray = [[NSMutableArray alloc] init];
    
    if (self.fetchMultipleAccount) {
        userArray = [CoreDataManager fetchAllUsers];
    }
    else {
        userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    }
    
    if (!self.fetchMultipleAccount) {
        usrId = [userId longLongValue];
    }
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager initArchiveFetchedResultsController:self.fetchedResultsController forUser:usrId isSearching:YES searchText:text fetchArchive:YES fetchDraft:NO];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self.fetchedResultsController setDelegate:self];
    }
    else {
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager initArchiveFetchedResultsController:self.fetchedResultsController forUser:usrId isSearching:NO searchText:@"" fetchArchive:YES fetchDraft:NO];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
    }
    
    [self.archiveTableView.pullToRefreshView stopAnimating];
    [self.archiveTableView.infiniteScrollingView stopAnimating];
    
    [self.archiveTableView reloadData];
}
-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 10;
    if(y > h + reload_distance) {
        [self scrollingFinish];
    }
}
- (void)scrollingFinish {
    [self fetchResultsFromDbForString:self.txtSearchField.text];
}

-(void)showProgressHudWithTitle:(NSString *)title {
    /*hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
     */
}
-(void)hideProgressHud {
    /*if (hud) {
        [hud hideAnimated:YES];
    }
    */
    
    [self.archiveTableView.pullToRefreshView stopAnimating];
    [self.archiveTableView.infiniteScrollingView stopAnimating];
}
-(void)getUserProfileForEmail:(NSString *)email object:(NSManagedObject *)object  indexPath:(NSIndexPath*)indexPath {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            /*NSManagedObjectContext *context = [CoreDataManager getManagedObjectContext];
             NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
             temporaryContext.parentContext = context;
             
             [temporaryContext performBlock:^{*/
            NSString * strUrl = [[Utilities parseProfile:response] objectAtIndex:1];
            [object setValue:strUrl forKey:kSENDER_IMAGE_URL];
            [CoreDataManager updateData];
            //            NSInteger totalRowsInSection = [self.archiveTableView numberOfRowsInSection:indexPath.section];
            //            if (indexPath.row<=totalRowsInSection-1) {
            //                NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
            //                [Utilities reloadTableViewRows:self.archiveTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
            //            }
            
        }
    } onError:^( NSString *resultMessage , int erorrCode)
     {
         if (erorrCode == -1011) {
             [object setValue:kNOT_FOUND forKey:kSENDER_IMAGE_URL];
             [CoreDataManager updateData];
         }
         //  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot Fetch Profile!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         //  [av show];
     }];
}
-(void)removeDelegates {
    if (archiveSync != nil) {
        archiveSync.invalidateTimer = YES;
        archiveSync = nil;
    }
    
    [self contentFetcherWithBool:NO];
    inboxManager.delegate = nil;
    [inboxManager.imapSession cancelAllOperations];
    inboxManager.imapSession  = nil;
    if (snoozeView) {
        snoozeView.delegate = nil;
    }
    if (datePickerView) {
        datePickerView.delegate = nil;
    }
    /*if (contentFetchManager) {
     contentFetchManager.delegate = nil;
     }
     contentFetchManager = nil;*/
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNSNOTIFICATIONCENTER_FAVORITE
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kINTERNET_AVAILABLE
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    inboxManager = nil;
}
#pragma mark - UserAction
- (void)searchTextFieldContent:(id)sender {
    
    NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    [self fetchResultsFromDbForString:txt];
    
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"SmartInboxCell";
    
    SmartInboxTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SmartInboxTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
    
    if (imgUrl != nil && ![imgUrl isEqualToString:kNOT_FOUND]) {
        [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    }
    else {
        cell.imgProfile.image = [UIImage imageNamed:@"profile_image_placeholder"];
    }
    
    //NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
    //MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
    cell = [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:nil view:self.view atIndexPath:indexPath isSent:NO];
    
    [self setupSwipeCellOptionsFor: cell indexPath:indexPath];

    return  cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 97.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    /*    NSString * email = nil;
     NSString * headerTitle = nil;
     if (section == 0) {
     headerTitle = @"New";
     }
     static NSString *tableIdentifier = @"InboxSectionHeader";
     
     InboxHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
     
     if (cell == nil) {
     NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"InboxHeaderTableViewCell" owner:self options:nil];
     cell      = [nib objectAtIndex:0];
     cell.selectionStyle = UITableViewCellSelectionStyleNone;
     }
     cell.lbHeaderlEmail.text = email;
     cell.lbHeaderlTitle.text = headerTitle;
     cell.btnHeader.tag = section;*/
    return  nil;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //return 29.0f;
    return 0.0f;
}
#pragma - mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    didSelectIndexPath = indexPath;
    NSInteger totalRowsInSection = [self.archiveTableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row<=totalRowsInSection-1) {
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [Utilities reloadTableViewRows:self.archiveTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationLeft];
    }
    
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderArchiveMail];
    
}

-(void)setActivityIndicatorViewConstant:(int)constant {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideUndoBar) object:nil];
    if (self.activityIndicatorHeightConstraint.constant == 30 && constant == 30) {
        return;
    }
//    [self.uiactivityIndicatorView startAnimating];
//    if (constant == 0) {
//        [self.uiactivityIndicatorView stopAnimating];
//    }
    
    self.activityIndicatorHeightConstraint.constant = constant;
    [self.view.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view.superview layoutIfNeeded];
    }];
}
-(void)performActions:(BOOL)isUndoCall {
    for (NSMutableDictionary * dic in self.undoArray) {
        if (isUndoCall) {
            if ([[dic objectForKey:kEMAIL_THREAD_ID] isEqualToString:undoThreadId]) {
                if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_message"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    int markCount = [[dictionaryCopy objectForKey:@"mark_count"] intValue];
                    if (markCount == 1) {
                        markCount = 0;
                    }
                    else {
                        markCount = 1;
                    }
                    [self markMessageLocally:messages markCount:markCount];
                    [self.undoArray removeObject:dic];
                    break;
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_archive"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markArchiveMessageLocally:messages flag:NO];
                    [self.undoArray removeObject:dic];
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markDeleteMessageLocally:messages flag:NO];
                    [self.undoArray removeObject:dic];
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_snooze"]) {
                    if (snoozeObject != nil) {
                        [self syncDeleteActionToFirebaseWithObject:snoozeObject];
                        snoozeObject = nil;
                    }
                }
            }
        }
        else {
            if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_message"]) {
                NSMutableDictionary * dictionaryCopy = [dic copy];
                [self markMessageOnServer:dictionaryCopy];
                [self.undoArray removeObject:dic];
            }
            else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_archive"]) {
                NSMutableDictionary * dictionaryCopy = [dic copy];
                NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                [self markArchiveOnServer:messages];
                [self.undoArray removeObject:dic];
            }
            else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
                NSMutableDictionary * dictionaryCopy = [dic copy];
                NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                [self markDeleteOnServer:messages];
                [self.undoArray removeObject:dic];
            }
        }
    }
}

-(void)hideUndoBar {
    NSLog(@"hide");
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
}
#pragma - mark User Actions
-(IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}
-(IBAction)btnNavigationSearchAction:(id)sender {
    if (self.heightSearchBar.constant == 43.0) {
        self.heightSearchBar.constant = 0.0f;
        self.txtSearchField.text = @"";
        [self fetchResultsFromDbForString:nil];
        if (isSearching) {
            [self fetchResultsFromDbForString:nil];
        }
    }
    else {
        //self.txtSearchField.text = @"";
        self.heightSearchBar.constant = 43.0f;
    }
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}
#pragma mark MCOIMAPFetchContentOperationManager Delegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    if (isSearching == NO) {
        NSInteger totalRowsInSection = [self.archiveTableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row<=totalRowsInSection-1) {
            NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
            [Utilities reloadTableViewRows:self.archiveTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
        }
    }
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.archiveTableView reloadData];
}
#pragma mark - SnoozeViewDelegate
- (void) snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply {
    if (viewType == 1) {
        snoozedOnlyIfNoReply = ifNoReply;
        //[self openPickerViewForIndex:5];
        CustomizeSnoozesViewController * customizeSnoozesViewController = [[CustomizeSnoozesViewController alloc] initWithNibName:@"CustomizeSnoozesViewController" bundle:nil];
        [self.navigationController pushViewController:customizeSnoozesViewController animated:YES];
    }
}
- (void) snoozeView:(SnoozeView*)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
    snoozedOnlyIfNoReply = ifNoReply;
    
    if (snoozeObject == nil) {
        return;
    }
    
    long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail = [Utilities getEmailForId:strUid];
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
    BOOL isDeafult = NO;
    if (value == 1) {
        isDeafult = YES;
    }
    
    NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:mail]];
    NSManagedObject * object = [array objectAtIndex:Index];
    int preferenceId = [[object valueForKey:kPREFERENCE_ID] intValue];
    int hour = [[object valueForKey:kSNOOZE_HOUR_COUNT] intValue];
    int minutes = [[object valueForKey:kSNOOZE_MINUTE_COUNT] intValue];
    if(preferenceId == 9) { /* open picker */
        [self openPickerViewForIndex:5];
        return;
    }

    [Utilities calculateDateWithHours:hour minutes:minutes preferenceId:preferenceId currentEmail:mail userId:strUid emailData:snoozeObject onlyIfNoReply:snoozedOnlyIfNoReply viewType:[view getTableViewType]];
    [self addUndoActionForSnooze];
}

#pragma - mark DatePickerViewDelegate
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    if (snoozeObject == nil) {
        return;
    }
    long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail = [Utilities getEmailForId:strUid];
    [self setActivityIndicatorViewConstant:30.0f];
    [Utilities setEmailToSnoozeTill:date withObject:snoozeObject currentEmail:mail onlyIfNoReply:snoozedOnlyIfNoReply userId:strUid];
    [self addUndoActionForSnooze];
}
- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
    
}

#pragma mark NSFetchedResultsController Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.archiveTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.archiveTableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.archiveTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.archiveTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.archiveTableView endUpdates];
}
#pragma - mark InboxManagerDelegate

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        [self fetchResultsFromDbForString:self.txtSearchField.text];
    }
    [self hideProgressHud];
    
    if (inboxManager == nil) {
        inboxManager = [[InboxManager alloc] init];
    }
    
    
    inboxManager.userId = userId;
    
    inboxManager.totalNumberOfMessagesInDB = [Utilities getArchiveLastFetchCountForUser:userId];
    isFetchingEmails = YES;
    inboxManager.strFolderName = kFOLDER_ALL_MAILS;
    inboxManager.folderType = kFolderArchiveMail;
    [inboxManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
    
    inboxManager.delegate = self;
    
    isFetchingEmails = YES;
}
- (void)inboxManager:(InboxManager *)manager didReceiveError:(NSError *)error {
    isFetchingEmails = NO;
    [self hideProgressHud];
}
- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId {
    isFetchingEmails = NO;
    [self hideProgressHud];
}
#pragma mark MGSwipeTableCellDelegate

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction {
    return YES;
}

-(NSArray*)swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
            swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    
    __weak typeof(self) weakSelf = self;
    NSIndexPath * indexPath = [weakSelf.archiveTableView indexPathForCell:cell];
    NSManagedObject *emailData = [weakSelf.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
    long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[emailData valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[emailData entity].name];
    NSString * title = @"Unread";
    if (unreadCount>0) {
        title = @"Read";
    }
    
    if (direction == MGSwipeDirectionLeftToRight) {
        
        expansionSettings.fillOnTrigger = YES;
        
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.archiveTableView indexPathForCell:sender];
            [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            return YES;
        }];
        MGSwipeButton * btnSwipeUnread = [MGSwipeButton buttonWithTitle:title icon:nil backgroundColor:[UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.archiveTableView indexPathForCell:sender];
            [weakSelf btnSwipeMarkMessageAtIndexPath:indexPath];
            
            return YES;
        }];
        return @[btnSwipeUnread, btnSwipeDelete];
    }
    else {
        
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeSnooze = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_snooze"] backgroundColor:[UIColor colorWithRed:245.0f/255.0f green:147.0f/255.0f blue:49.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.archiveTableView indexPathForCell:sender];
            weakSelf.swipeIndexPath = indexPath;
            
            if (weakSelf.swipeIndexPath != nil) {
                [weakSelf showSubView];
            }
            return YES;
        }];
        
        MGSwipeButton * btnSwipeInbox = [MGSwipeButton buttonWithTitle:@"Inbox" icon:nil backgroundColor:[UIColor colorWithRed:167.0f/255.0f green:102.0f/255.0f blue:166.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.archiveTableView indexPathForCell:sender];
            [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
            return YES;
        }];
        return @[btnSwipeInbox,btnSwipeSnooze];
    }
    return nil;
}

-(void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    NSString * str;
    switch (state) {
        case MGSwipeStateNone: str = @"None"; break;
        case MGSwipeStateSwippingLeftToRight: str = @"SwippingLeftToRight"; break;
        case MGSwipeStateSwippingRightToLeft: str = @"SwippingRightToLeft"; break;
        case MGSwipeStateExpandingLeftToRight: str = @"ExpandingLeftToRight"; break;
        case MGSwipeStateExpandingRightToLeft: str = @"ExpandingRightToLeft"; break;
    }
    //NSLog(@"Swipe state: %@ ::: Gesture: %@", str, gestureIsActive ? @"Active" : @"Ended");
    //    id button = cell.rightButtons[0];
    //    UIButton *pressedBtn = button;
    //    [pressedBtn setTitle:@"Less" forState:UIControlStateNormal];
}
//-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion
//{
//
//    //if (direction == MGSwipeDirectionRightToLeft && index == 1) {
//        NSLog(@"more pressed");
//        id button = cell.rightButtons[index];
//        UIButton *pressedBtn = button;
//        [pressedBtn setTitle:@"Less" forState:UIControlStateNormal];
//        NSLog(@"pressedBtn title: %@",pressedBtn.titleLabel.text);
//
//    //}
//    return YES;
//}

-(void)dealloc {
    NSLog(@"dealloc : ArchiveViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *) getReadUnReadImageForCell:(NSIndexPath *) indexPath {
    
    __weak typeof(self) weakSelf = self;

    NSManagedObject *emailData = [weakSelf.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
    long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[emailData valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[emailData entity].name];
    
    if (unreadCount>0) {
        return kIMAGE_SWIPE_CELL_READ;
    }
    else{
        return kIMAGE_SWIPE_CELL_UNREAD;
    }
}

- (UIColor *) getReadUnReadColorForCell:(NSIndexPath *) indexPath {
    
    __weak typeof(self) weakSelf = self;
    NSManagedObject *emailData = [weakSelf.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
    long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[emailData valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[emailData entity].name];
    
    if (unreadCount>0) {
        return kCOLOR_SWIPE_CELL_READ;
    }
    else{
        return kCOLOR_SWIPE_CELL_UNREAD;
    }
}

- (void) setupSwipeCellOptionsFor:(SmartInboxTableViewCell *) cell indexPath:(NSIndexPath *) indexPath{
    cell.imageSet = SwipeCellImageSetMake([self getReadUnReadImageForCell:indexPath], kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_SNOOZE, kIMAGE_SWIPE_CELL_INBOX);
    cell.colorSet = SwipeCellColorSetMake([self getReadUnReadColorForCell:indexPath] ,kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_SNOOZE, kCOLOR_SWIPE_CELL_INBOX);
    
    cell.delegate = self;
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType
{
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.archiveTableView indexPathForCell:cell];
        if (indexPath)
        {
            if (swipeType == JZSwipeTypeLongRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortRight) {
                
                [self btnSwipeMarkMessageAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeLongLeft) {
                

                [self btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortLeft) {

                self.swipeIndexPath = indexPath;
                
                if (self.swipeIndexPath != nil) {
                    [self showSubView];
                }
                
                
            }
            
            [cell runBounceBackAnimation];
        }
    }
    
}

- (void)swipeCell:(JZSwipeCell *)cell swipeTypeChangedFrom:(JZSwipeType)from to:(JZSwipeType)to
{
    // perform custom state changes here
    NSLog(@"Swipe Changed From (%d) To (%d)", from, to);
}



@end
