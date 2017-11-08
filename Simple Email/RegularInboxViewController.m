//
//  RegularInboxViewController.m
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "RegularInboxViewController.h"

#import "Utilities.h"
#import "Constants.h"
#import "SnoozeView.h"
#import "SyncManager.h"
#import "AppDelegate.h"
#import "InboxManager.h"
#import "MBProgressHUD.h"
#import "ArchiveManager.h"
#import "SearchHistoryView.h"
#import "DatePickerView.h"
#import "CoreDataManager.h"
#import "WebServiceManager.h"
#import "CellConfigureManager.h"
#import "SharedInstanceManager.h"
#import "MCOIMAPSessionManager.h"
#import "MailCoreServiceManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SWRevealViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "FavoriteEmailSyncManager.h"
#import "LocalNotificationManager.h"
#import "EmailComposerViewController.h"
#import "CustomizeSnoozesViewController.h"
#import "CustomizeSnoozesViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "MailThreadViewController.h"
#import "SVPullToRefresh.h"

@interface RegularInboxViewController () <JZSwipeCellDelegate, InboxManagerDelegate, MCOIMAPFetchContentOperationManagerDelegate, SnoozeViewDelegate, SearchHistoryViewDelegate,  UIGestureRecognizerDelegate, DatePickerViewDelegate>

@end

@implementation RegularInboxViewController {
    BOOL isSearching;
    NSString * userId;
    MBProgressHUD *hud;
    BOOL isFirstFetchCall;
    BOOL isFetchingEmails;
    NSString * currentEmail;
    SnoozeView * snoozeView;
    BOOL snoozedOnlyIfNoReply;
    InboxManager * inboxManager;
    int totalResponseCount;
    SyncManager * inboxSync;
    SyncManager * sentSync;
    NSManagedObject * snoozeObject;
    NSIndexPath* didSelectIndexPath;
    DatePickerView * datePickerView;
    SearchHistoryView * searchHistoryView;
    NSMutableDictionary * contentFetcherDictionary;
    LocalNotificationManager * localNotificationManager;
    BOOL isSearchingEmails;
    NSString * undoThreadId;
    NSTimer                 *populateDataTimer;
    NSDate                  *lastReloadDate;
    NSInteger               itemCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    undoThreadId = nil;
    [self refreshServices];
    totalResponseCount = 0;
    isSearchingEmails = NO;
    itemCount = 0;
    __weak RegularInboxViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.regularInboxTableView addPullToRefreshWithActionHandler:^{
        
        if(isFetchingEmails == NO) {
            [weakSelf fetchEmails];
        }
    }];
    
    // setup infinite scrolling
    [self.regularInboxTableView addInfiniteScrollingWithActionHandler:^{
        
        [weakSelf scrollingFinish];
    }];
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    if (self.renderView) {
        [self contentFetcherWithBool:YES];
        isSearching = NO;
        [self initfetchedResultsController];
        NSMutableArray * users = nil;
        if (self.fetchMultipleAccount) {
            users = [CoreDataManager fetchAllUsers];
        }
        else {
            users = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
        }
        BOOL showProgressDialog = NO;
        self.inboxManagers = [NSMutableArray new];
        for (NSManagedObject * userObject in users) {
            long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
            NSString * strUid = [Utilities getStringFromLong:usrId];
            NSString * mail = [userObject valueForKey:kUSER_EMAIL];
            
            InboxManager *inManager = [[InboxManager alloc] init];
            inManager.userId = strUid;
            inManager.isSearchingExpression = NO;
            inManager.currentLoginMailAddress = mail;
            inManager.totalNumberOfMessagesInDB = [Utilities getInboxLastFetchCount:strUid];
            isFetchingEmails = NO;
            totalResponseCount++;
            inManager.delegate = self;
            
            NSError *error;
            NSFetchedResultsController *fetchedController = [CoreDataManager fetchedRegularEmailsForController:nil forUser:usrId isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:NO entity:kENTITY_EMAIL];
            if (![fetchedController performFetch:&error]) {
                // Update to handle the error appropriately.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                exit(-1);  // Fail
            }
            inManager.fetchMessages = NO;
            fetchedController.delegate = nil;
            if (fetchedController.fetchedObjects.count == 0) {
                inManager.fetchMessages = YES;
                showProgressDialog = YES;
                isFetchingEmails = YES;
                totalResponseCount--;
            }
            inManager.entityName = kENTITY_EMAIL;
            fetchedController = nil;
            [inManager startFetchingMessagesForFolder:kFOLDER_INBOX andType:kFolderInboxMail];
            [self.inboxManagers addObject:inManager];
        }
        if (showProgressDialog) {
            [self showProgressHudWithTitle:kFETCHING_EMAILS];
            [self.regularInboxTableView triggerPullToRefresh];
        }
        else {
            totalResponseCount = 0;
        }
    }

    isFirstFetchCall = YES;
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    [self setUpView];
    [self createSearchManagers];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
}

-(void)createSearchManagers {
    self.inboxSearchManagers = [NSMutableArray new];
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [userObject valueForKey:kUSER_EMAIL];
        InboxManager *inManager = [[InboxManager alloc] init];
        inManager.userId = strUid;
        inManager.currentLoginMailAddress = mail;
        inManager.isSearchingExpression = YES;
        isFetchingEmails = NO;
        inManager.delegate = self;
        inManager.fetchMessages = NO;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager startFetchingMessagesForFolder:kFOLDER_INBOX andType:kFolderInboxMail];
        [self.inboxSearchManagers addObject:inManager];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!isFirstFetchCall) {
        [self showNotFoundLabelWithText:kEMPTY_INBOX_MESSAGE];
    }
}

-(void) receiveNotification:(NSNotification*)notification {
    if ([notification.name isEqualToString:kNSNOTIFICATIONCENTER_LOGOUT]) {
        NSDictionary* userInfo = notification.userInfo;
        NSString* total = userInfo[kUSER_ID];
        if (self.inboxManagers != nil) {
            for (int i = 0; i<self.inboxManagers.count; ++i) {
                InboxManager * manager = [self.inboxManagers objectAtIndex:i];
                if ([manager.userId isEqualToString:total]) {
                    NSLog(@"fetching stop");
                    manager.stopSaving = YES;
                    manager.delegate = nil;
                    manager = nil;
                }
            }
        }
    }
}

-(void)removeDelegates {
    if (inboxSync != nil) {
        inboxSync.invalidateTimer = YES;
        inboxSync = nil;
    }
    
    if (sentSync != nil) {
        sentSync.invalidateTimer = YES;
        sentSync = nil;
    }
    
    [self contentFetcherWithBool:NO];
    if (self.inboxManagers != nil) {
        for (int i = 0; i<self.inboxManagers.count; ++i) {
            InboxManager * manager = [self.inboxManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    if (self.inboxSearchManagers != nil) {
        for (int i = 0; i<self.inboxSearchManagers.count; ++i) {
            InboxManager * manager = [self.inboxSearchManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kINTERNET_AVAILABLE
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    inboxManager.delegate = nil;
    [inboxManager.imapSession cancelAllOperations];
    inboxManager.imapSession  = nil;
    if (snoozeView) {
        snoozeView.delegate = nil;
    }
    if (searchHistoryView) {
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
    if (datePickerView) {
        datePickerView.delegate = nil;
    }
    inboxManager = nil;
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenRows];
}

- (void)loadImagesForOnscreenRows {
    NSArray *visiblePaths = [self.regularInboxTableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
        NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
        if (imgUrl == nil) {
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

#pragma mark - Private Methods

-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil entity:kENTITY_EMAIL];
    [self checkEmailCount];
    NSLog(@"checkEmailCount = %lu",self.fetchedResultsController.fetchedObjects.count);
}

-(void)checkEmailCount {
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        long count = [CoreDataManager fetchInboxEmailsCountForUserId:usrId isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO];
        NSLog(@"checkEmailCount = %ld",count);
        if (count == 0) {
            [Utilities updateInboxLastFetchCount:0 userId:strUid];
        }
    }
}

-(void)searchString:(NSString *)string {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_INBOX;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager inboxSearchString:string];
        inManager.delegate = self;
    }
}

-(void)fetchSearchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_INBOX;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager fetchNextModuleOfSearchedEmails];
        inManager.delegate = self;
        
    }
}

-(void)fetchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxManagers) {
        inManager.totalNumberOfMessagesInDB = [Utilities getInboxLastFetchCount:inManager.userId];
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_INBOX;
        inManager.folderType = kFolderInboxMail;
        [inManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        inManager.delegate = self;
    }
}

-(void)setUpView {
    [self setActivityIndicatorViewConstant:0.0f];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    [self.regularInboxTableView addGestureRecognizer:lpgr];
    
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshServices)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(receiveNotification:) name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    [self.navigationController.navigationBar setHidden:NO];
    [self.regularInboxTableView setBackgroundView:nil];
    [self.regularInboxTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Inbox";
    UIBarButtonItem * btnNavSearch = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
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
    [self.txtSearchField addTarget:self action:@selector(updateTableContentsOfTextField:) forControlEvents:UIControlEventEditingChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVisibleRows:) name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
}

- (void)updateVisibleRows:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}

- (void)fetchResultsFromDbForString:(NSString *)text entity:(NSString *)entity {
    if ([entity isEqualToString:kENTITY_EMAIL]) {
        isSearchingEmails = NO;
    } else {
        isSearchingEmails = YES;
    }
    
    long usr = [userId longLongValue];
    if (self.fetchMultipleAccount) {
        usr = -1;
    }
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        [self.fetchedResultsController setDelegate:self];
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedRegularEmailsForController:self.fetchedResultsController forUser:usr isSearching:YES searchText:text fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:NO entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    } else {
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedRegularEmailsForController:self.fetchedResultsController forUser:usr isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:NO entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
    }
    [self.regularInboxTableView reloadData];
}

- (void)showNotFoundLabelWithText:(NSString *)text {
    self.lblNoEmailFoundMessage.text = text;
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        [self.lblNoEmailFoundMessage setHidden:NO];
    }
    else {
        [self.lblNoEmailFoundMessage setHidden:YES];
    }
}

- (void)showProgressHudWithTitle:(NSString *)title {
    /*hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
     */
}

- (void)hideProgressHud {
    [self.regularInboxTableView.pullToRefreshView stopAnimating];
    [self.regularInboxTableView.infiniteScrollingView stopAnimating];
}

- (void)reloadAfterFetchingResults {
    CGSize beforeContentSize;
    CGSize afterContentSize;
    
    CGPoint afterContentOffset;
    CGPoint newContentOffset;
    
    beforeContentSize   = self.regularInboxTableView.contentSize;
    
    [self.regularInboxTableView reloadData];
    
    afterContentSize = self.regularInboxTableView.contentSize;
    afterContentOffset = self.regularInboxTableView.contentOffset;
    
    newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
    
    self.regularInboxTableView.contentOffset = newContentOffset;
}

- (void)contentFetcherWithBool:(BOOL)createFetchers {
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

- (void)hideHistoryView {
    if([searchHistoryView isDescendantOfView:self.view]) {
        [searchHistoryView removeFromSuperview];
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
}

- (void)showHistoryView {
    if(![searchHistoryView isDescendantOfView:self.view]) {
        searchHistoryView = [[[NSBundle mainBundle] loadNibNamed:@"SearchHistoryView" owner:self options:nil] objectAtIndex:0];
        searchHistoryView.delegate = self;
        [self.view addSubview:searchHistoryView];
        [searchHistoryView setUpView];
        searchHistoryView.translatesAutoresizingMaskIntoConstraints = NO;
        [Utilities setLayoutConstarintsForEditorView:searchHistoryView parentView:self.view fromBottomView:self.view bottomSpace:0.0f topView:self.view topSpace:43.0f leadingSpace:0.0f trailingSpace:0.0f];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    /*CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 10;
    if(y > h + reload_distance) {
        [self scrollingFinish];
    }*/
}
- (void)scrollingFinish {
    if (!isFetchingEmails) {
        if (isSearchingEmails) {
            [self fetchSearchEmails];
        }
        else {
            [self fetchEmails];
        }
    }
    if ([self.fetchedResultsController fetchedObjects].count > 0) {
        //[self setActivityIndicatorViewConstant:30.0f];
    }
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

-(void)getUserProfileForEmail:(NSString *)email object:(NSManagedObject *)object  indexPath:(NSIndexPath*)indexPath {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            NSString * strUrl = [[Utilities parseProfile:response] objectAtIndex:1];
            if (object != nil) {
                [object setValue:strUrl forKey:kSENDER_IMAGE_URL];
            }
            [CoreDataManager updateData];
        }
    } onError:^( NSString *resultMessage , int erorrCode) {
        if (erorrCode == -1011) {
            [object setValue:kNOT_FOUND forKey:kSENDER_IMAGE_URL];
            [CoreDataManager updateData];
        }
    }];
}

- (void)showToastWithMessage:(NSString *)message {
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

- (void)refreshServices {
    if (inboxSync != nil) {
        inboxSync.invalidateTimer = YES;
        inboxSync = nil;
    }
    
    if (sentSync != nil) {
        sentSync.invalidateTimer = YES;
        sentSync = nil;
    }
    
    inboxSync = [[SyncManager alloc] init];
    [inboxSync syncEmailForFolder:kFOLDER_INBOX];
    
    sentSync = [[SyncManager alloc] init];
    [sentSync syncEmailForFolder:@"SENT"];
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object {
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

- (void)btnSwipeMarkMessageAtIndexPath:(NSIndexPath *)indexPath {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [object valueForKey:kMAIL_FOLDER];
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

- (void)markMessageLocally:(NSMutableArray *)array markCount:(int)markCount {
    for (NSManagedObject * obj in array) {
        [obj setValue:[NSNumber numberWithLong:markCount] forKey:kUNREAD_COUNT];
        [CoreDataManager updateData];
    }
}

- (void)markMessageOnServer:(NSMutableDictionary *)undoDictionary {
    NSLog(@"marking on server: %@",undoDictionary);
    NSMutableArray * messages = [undoDictionary objectForKey:@"messages"];
    int markCount = [[undoDictionary objectForKey:@"mark_count"] intValue];
    for (NSManagedObject * obj in messages) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (searchHistoryView != nil && [textField.text length]>0) {
        NSError * error = [CoreDataManager deleteAllEntities:kENTITY_SEARCH_EMAIL];
        if (error == nil) {
            [searchHistoryView saveHistory:textField.text isSaved:NO];
            [self hideHistoryView];
            [self searchString:textField.text];
        }
    }
    [textField endEditing:YES];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self showHistoryView];
}

- (void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    
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

- (void)markDeleteMessageLocally:(NSMutableArray*)messages flag:(BOOL)flag {
    for (NSManagedObject * object in messages) {
        [object setValue:[NSNumber numberWithBool:flag] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
    }
}

- (void)markDeleteOnServer:(NSMutableArray*)messages {
    for (NSManagedObject * obj in messages) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
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
                NSLog(@"cannot delete error: %@", error.localizedDescription);
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

- (void)btnSwipeArchiveActionAtIndexPath:(NSIndexPath *)indexPath {
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
    
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:[object entity].name];
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
    
    for (NSManagedObject * obj in emailIdArray) {
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:NO threadId:[strThreadId longLongValue] entity:[object entity].name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:[userId longLongValue]];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        if (response != nil) {
                            for (NSManagedObject * object in emailIdArray) {
                                /* change folder name to [Gmail]/All Mail if email belong to INBOX */
                                NSString * folderName = [object valueForKey:kMAIL_FOLDER];
                                if ([folderName isEqualToString:kFOLDER_INBOX]) {
                                    [object setValue:kFOLDER_ALL_MAILS forKey:kMAIL_FOLDER];
                                }
                                [self syncDeleteActionToFirebaseWithObject:object];
                            }
                            [CoreDataManager updateData];
                        }
                    } onError:^( NSError * error) {
                        for (NSManagedObject * objc in emailIdArray) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
                            [CoreDataManager updateData];
                        }
                        //[self updateTableView];
                        [self showAlertWithTitle:@"Cannot Archive Email!" andMessage:[NSString stringWithFormat:@"Please try again."] withDelegate:nil];
                    }];
                }
            }
        }
    }
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}

- (void)markSnoozeActionAtIndexPath:(NSIndexPath *)indexPath {
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
    
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:[object entity].name];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_snooze" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Snooze marked";
    
    for (NSManagedObject * obj in emailIdArray) {
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            //fetch email from server with Inbox
            // Folder and save it locally
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[strThreadId longLongValue] entity:[object entity].name];
            }
        }
    }
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}

- (void)markArchiveMessageLocally:(NSMutableArray*)messages {
    for (NSManagedObject * objc in messages) {
        [objc setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
    }
}

- (void)markArchiveOnServer:(NSMutableArray*)messages {
    for (NSManagedObject * object in messages) {
        long usrId = [[object valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        uint64_t uniqueId = [[object valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
        NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
        
        if (imapSession != nil) {
            [object setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[strThreadId longLongValue] entity:[object entity].name];
            } else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:usrId];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        
                        for (NSManagedObject * object in messages) {
                            [self syncDeleteActionToFirebaseWithObject:object];
                            [CoreDataManager deleteObject:object];
                        }
                        [CoreDataManager updateData];
                    } onError:^( NSError * error) {
                        for (NSManagedObject * objc in messages) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                            [CoreDataManager updateData];
                        }
                    }];
                }
            }
        }
    }
}

- (void)markArchiveOnServerWithoutDeletingSnooze:(NSMutableArray*)messages {
    for (NSManagedObject * object in messages) {
        long usrId = [[object valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        uint64_t uniqueId = [[object valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
        NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
        
        if (imapSession != nil) {
            [object setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[strThreadId longLongValue] entity:[object entity].name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:usrId];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        [CoreDataManager updateData];
                    } onError:^( NSError * error) {
                        for (NSManagedObject * objc in messages) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                            [CoreDataManager updateData];
                        }
                    }];
                }
            }
        }
    }
}

- (void)btnSwipeFavoriteActionAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail = [Utilities getEmailForId:strUid];
    if ([[object valueForKey:kIS_FAVORITE] boolValue]) {
        [self showToastWithMessage:@"✰✰ Already Marked Favorite ✰✰"];
    }
    else {
        [self setActivityIndicatorViewConstant:30.0f];
        
        uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
        NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
        if (self.undoArray == nil) {
            self.undoArray = [[NSMutableArray alloc] init];
        }
        else {
            [self performActions:NO];
        }
        undoThreadId = strThreadId;
        long usrId = [[object valueForKey:kUSER_ID] longLongValue];
        NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
        NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
        [undoDictionary setObject:@"mark_favorite" forKey:@"actiontype"];
        [undoDictionary setObject:emailIdArray forKey:@"messages"];
        [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
        [self.undoArray addObject:undoDictionary];
        
        NSMutableDictionary * dictionary = [Utilities getDictionaryFromObject:object email:mail isThread:YES dictionaryType:kTypeFavorite nsdate:0];
        [Utilities syncToFirebase:dictionary syncType:[FavoriteEmailSyncManager class] userId:strUid performAction:kActionInsert firebaseId:nil];
        self.lblUndo.text = @"Favorite marked";
        [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    }
}

#pragma mark - SnoozeViewDelegate
- (void)snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply {
    if (viewType == 1) {
        snoozedOnlyIfNoReply = ifNoReply;
        CustomizeSnoozesViewController * customizeSnoozesViewController = [[CustomizeSnoozesViewController alloc] initWithNibName:@"CustomizeSnoozesViewController" bundle:nil];
        [self.navigationController pushViewController:customizeSnoozesViewController animated:YES];
    }
}

- (void)snoozeView:(SnoozeView*)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
    snoozedOnlyIfNoReply = ifNoReply;
    
    if (snoozeObject == nil) {
        return;
    }
    
    long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail =  [Utilities getEmailForId:strUid];
    if (![Utilities isValidString:mail]) {
        return;
    }
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

    [self markSnoozeActionAtIndexPath:self.swipeIndexPath];
}

#pragma mark - DatePickerViewDelegate

- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    if (snoozeObject == nil) {
        return;
    }
    long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail = [Utilities getEmailForId:strUid];
    if (![Utilities isValidString:mail]) {
        return;
    }
    [Utilities setEmailToSnoozeTill:date withObject:snoozeObject currentEmail:mail onlyIfNoReply:snoozedOnlyIfNoReply userId:strUid];
}

- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    int n = [sectionInfo numberOfObjects];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

    cell = [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:nil view:self.view atIndexPath:indexPath isSent:NO];
    
    [self setupSwipeCellOptionsFor:cell];

    return  cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 97.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    static NSString *tableIdentifier = @"InboxSectionHeader";
    
    InboxHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"InboxHeaderTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.lbHeaderlEmail.text = @"sheri@gmail.com";
    cell.lbHeaderlTitle.text = @"Title";
    cell.btnHeader.tag = section;
    return  nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return  nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    didSelectIndexPath = indexPath;
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderInboxMail];
}

#pragma mark - UserActions

- (IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}

- (void)updateTableContentsOfTextField:(id)sender {
    //NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    //[self fetchResultsFromDbForString:txt];
}

- (IBAction)btnSaveHistoryAction:(id)sender {
    if (searchHistoryView != nil && [self.txtSearchField.text length]>0) {
        [searchHistoryView saveHistory:self.txtSearchField.text isSaved:YES];
    }
}

- (IBAction)btnNavigationSearchAction:(id)sender {
    UIBarButtonItem * btn = (UIBarButtonItem *)sender;
    float delay = 0;
    if([snoozeView isDescendantOfView:self.view]) {
        [snoozeView removeFromSuperview];
    }
    if (self.heightSearchBar.constant == 43.0) {
        self.heightSearchBar.constant = 0.0f;
        self.txtSearchField.text = @"";
        [self fetchResultsFromDbForString:nil entity:kENTITY_EMAIL];
        [btn setImage:[UIImage imageNamed:@"menu_search"]];
        [self hideHistoryView];
    }
    else {
        self.heightSearchBar.constant = 43.0f;
        delay = 0.25f;
        self.fetchedResultsController.fetchRequest.predicate =
        [NSPredicate predicateWithValue:NO];
        [self.fetchedResultsController performFetch:nil];
        self.fetchedResultsController.delegate = nil;
        [btn setImage:[UIImage imageNamed:@"btn_cross"]];
        [self fetchResultsFromDbForString:nil entity:kENTITY_SEARCH_EMAIL];
        [self showHistoryView];
    }
    
    [self.view.superview setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.25f animations:^{
        [self.view.superview layoutIfNeeded];
    }];
}

- (void)setActivityIndicatorViewConstant:(int)constant {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideUndoBar) object:nil];
    if (self.activityIndicatorHeightConstraint.constant == 30 && constant == 30) {
        return;
    }
    [self.uiactivityIndicatorView startAnimating];
    if (constant == 0) {
        [self.uiactivityIndicatorView stopAnimating];
    }
    
    self.activityIndicatorHeightConstraint.constant = constant;
    [self.view.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view.superview layoutIfNeeded];
    }];
}

- (void)performActions:(BOOL)isUndoCall {
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
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_favorite"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    for (NSManagedObject * object in messages) {
                        [self syncDeleteActionToFirebaseWithObject:object];
                    }
                    [self.undoArray removeObject:dic];
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_archive"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markArchiveMessageLocally:messages];
                    [self.undoArray removeObject:dic];
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_snooze"]) {
                    
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    for (NSManagedObject * obj in messages) {
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                        [CoreDataManager updateData];
                        [self syncDeleteActionToFirebaseWithObject:obj];
                    }
                    [self.undoArray removeObject:dic];
                    
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markDeleteMessageLocally:messages flag:NO];
                    [self.undoArray removeObject:dic];
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
            else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_snooze"]) {
                NSMutableDictionary * dictionaryCopy = [dic copy];
                NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                [self markArchiveOnServerWithoutDeletingSnooze:messages];
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

- (void)hideUndoBar {
    NSLog(@"hide");
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
}

- (IBAction)btnAddAction:(id)sender {
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @"Compose";
    emailComposerViewController.isDraft = NO;
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:self.regularInboxTableView];
        NSIndexPath *indexPath = [self.regularInboxTableView indexPathForRowAtPoint:p];
        if (indexPath == nil) {
            NSLog(@"long press on table view but not on a row");
        } else {
            UITableViewCell *cell = [self.regularInboxTableView cellForRowAtIndexPath:indexPath];
            if (cell.isHighlighted) {
                NSLog(@"long press on table view at section %ld row %ld", (long)indexPath.section, (long)indexPath.row);
                
                self.swipeIndexPath = indexPath;
                if (self.swipeIndexPath != nil) {
                    [self showSubView];
                }
            }
        }
    }
}

#pragma mark - SearchHistoryViewDelegate

- (void)actionIndexString:(NSString *)string {
    if (searchHistoryView != nil && [string length]>0) {
        NSError * error = [CoreDataManager deleteAllEntities:kENTITY_SEARCH_EMAIL];
        if (error == nil) {
            [self hideHistoryView];
            [self searchString:string];
        }
    }
    [self.txtSearchField endEditing:YES];
}

#pragma mark - InboxManagerDelegate

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    [[NSThread currentThread] isMainThread] ? NSLog(@"MAIN THREAD_didReceiveEmails") : NSLog(@"NOT MAIN THREAD_didReceiveEmails");
    [self loadImagesForOnscreenRows];
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        [self hideProgressHud];
        
        [self reloadAfterFetchingResults];
        
        totalResponseCount = 0;
        if (self.fetchedResultsController.fetchedObjects.count < 50 || isFirstFetchCall) {
            isFirstFetchCall = NO;
        }
        else {
            isFetchingEmails = NO;
            return;
        }
        isFetchingEmails = NO;
    }
}

- (void)inboxManager:(InboxManager *)manager didReceiveError:(NSError *)error {
    [[NSThread currentThread] isMainThread] ? NSLog(@"MAIN THREAD_didReceiveError") : NSLog(@"NOT MAIN THREAD_didReceiveError");
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        isFetchingEmails = NO;
        [self hideProgressHud];
    }
}

- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId {
    [[NSThread currentThread] isMainThread] ? NSLog(@"MAIN THREAD_noEmailsToFetchForId") : NSLog(@"NOT MAIN THREAD_noEmailsToFetchForId");
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        isFetchingEmails = NO;
        totalResponseCount = 0;
        [self hideProgressHud];
        [self showNotFoundLabelWithText:kEMPTY_INBOX_MESSAGE];
    }
}

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction {
    return YES;
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
            swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    __weak typeof(self) weakSelf = self;
    NSIndexPath * indexPath = [weakSelf.regularInboxTableView indexPathForCell:cell];
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
        MGSwipeButton * btnSwipeArchive = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_archive"] backgroundColor:[UIColor colorWithRed:64.0f/255.0f green:179.0f/255.0f blue:79.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.regularInboxTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            NSLog(@"btnSwipeArchive at INDEX: %@",indexPath);
            return YES;
        }];
        
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.regularInboxTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            NSLog(@"btnSwipeDelete at INDEX: %@",indexPath);
            return YES;
        }];
        return @[btnSwipeArchive,btnSwipeDelete];
    }
    else {
        
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeFavorite = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_favorite"] backgroundColor:[UIColor colorWithRed:82.0f/255.0f green:195.0f/255.0 blue:240.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.regularInboxTableView indexPathForCell:sender];
            NSLog(@"btnSwipeFavorite at INDEX: %@",indexPath);
            if (indexPath != nil) {
                [weakSelf btnSwipeFavoriteActionAtIndexPath:indexPath];
            }
            
            return YES;
        }];
        
        MGSwipeButton * btnSwipeUnread = [MGSwipeButton buttonWithTitle:title icon:nil backgroundColor:[UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.regularInboxTableView indexPathForCell:sender];
            NSLog(@"btnSwipeUnread at INDEX: %@",indexPath);
            if (indexPath != nil) {
                [weakSelf btnSwipeMarkMessageAtIndexPath:indexPath];
            }
            
            return YES;
        }];
        return @[btnSwipeFavorite,btnSwipeUnread];
    }
    return nil;
}

- (void)swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    NSString * str;
    switch (state) {
        case MGSwipeStateNone: str = @"None"; break;
        case MGSwipeStateSwippingLeftToRight: str = @"SwippingLeftToRight"; break;
        case MGSwipeStateSwippingRightToLeft: str = @"SwippingRightToLeft"; break;
        case MGSwipeStateExpandingLeftToRight: str = @"ExpandingLeftToRight"; break;
        case MGSwipeStateExpandingRightToLeft: str = @"ExpandingRightToLeft"; break;
    }
}

#pragma mark - MCOIMAPFetchContentOperationManagerDelegate

- (void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    if (isSearching == NO) {
        //[Utilities reloadTableViewRows:self.regularInboxTableView forIndexArray:[NSArray arrayWithObjects:indexPath, nil] withAnimation:UITableViewRowAnimationNone];
    }
}

- (void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    NSLog(@"aaaaa");
}

- (void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    //[self.regularInboxTableView reloadData];
    NSLog(@"aaaaa");

}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.regularInboxTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.regularInboxTableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert: {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
            
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
            [self.regularInboxTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.regularInboxTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.regularInboxTableView endUpdates];
}

- (void)dealloc {
    NSLog(@"dealloc : RegularInboxViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupSwipeCellOptionsFor:(SmartInboxTableViewCell *) cell {
    cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_ARHIEVE, kIMAGE_SWIPE_CELL_SNOOZE, kIMAGE_SWIPE_CELL_FAVOURITE);
    cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_ARCHIVE, kCOLOR_SWIPE_CELL_SNOOZE, kCOLOR_SWIPE_CELL_FAVOURITE);
    
    cell.delegate = self;
}

- (void) reloadTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.regularInboxTableView reloadData];
        NSLog(@"############### Tableview Reloaded ###############");
        [self.regularInboxTableView endUpdates];
    });
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType {
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.regularInboxTableView indexPathForCell:cell];
        if (indexPath)
        {
            if (swipeType == JZSwipeTypeLongRight) {
                [self btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeLongLeft) {
                
                [self btnSwipeFavoriteActionAtIndexPath:indexPath];
                
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

- (void)swipeCell:(JZSwipeCell *)cell swipeTypeChangedFrom:(JZSwipeType)from to:(JZSwipeType)to {
    // perform custom state changes here
    NSLog(@"Swipe Changed From (%d) To (%d)", from, to);
}

@end
