//
//  SentViewController.m
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SentViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "InboxManager.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "WebServiceManager.h"
#import "EmailUpdateManager.h"
#import "CellConfigureManager.h"
#import "SharedInstanceManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "MailCoreServiceManager.h"
#import "SyncManager.h"
#import "SearchHistoryView.h"
#import "SVPullToRefresh.h"

@interface SentViewController () <JZSwipeCellDelegate>

@end

@implementation SentViewController {
    BOOL isSearching;
    NSString * userId;
    MBProgressHUD * hud;
    BOOL isFirstFetchCall;
    BOOL isUpdateCallMade;
    BOOL isFetchingEmails;
    NSString * currentEmail;
    InboxManager * inboxManager;
    NSIndexPath * didSelectIndexPath;
    NSMutableDictionary * contentFetcherDictionary;
    SyncManager * inboxSync;
    SyncManager * sentSync;
    int totalResponseCount;
    SearchHistoryView * searchHistoryView;
    BOOL isSearchingEmails;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    totalResponseCount = 0;
    isSearchingEmails = NO;
    undoThreadId = nil;
    [self refreshServices];
    
    __weak SentViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.sentTableView addPullToRefreshWithActionHandler:^{
        
        [weakSelf fetchEmails];
    }];
    
    // setup infinite scrolling
    [self.sentTableView addInfiniteScrollingWithActionHandler:^{
        
        //[self fetchEmails];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    [self setUpView];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [self createSearchManagers];
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
        [inManager startFetchingMessagesForFolder:kFOLDER_SENT_MAILS andType:kFolderInboxMail];
        [self.inboxSearchManagers addObject:inManager];
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
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //    if (didSelectIndexPath !=nil ) {
    //        NSArray* indexArray = [NSArray arrayWithObjects:didSelectIndexPath, nil];
    //        [Utilities reloadTableViewRows:self.sentTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationRight];
    //        didSelectIndexPath = nil;
    //        //[self fetchResultsFromDbForString:self.txtSearchField.text];
    //    }
    if (!isFirstFetchCall) {
        [self showNotFoundLabelWithText:kNO_SENT_AVAILABLE_MESSAGE];
    }
}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
}
#pragma - mark Private Methods
-(void)setUpView {
    [self contentFetcherWithBool:YES];
    [self setActivityIndicatorViewConstant:0.0f];
    isUpdateCallMade = NO;
    isFirstFetchCall = YES;
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    
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
    //self.updateManagers = [NSMutableArray new];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [userObject valueForKey:kUSER_EMAIL];
        
        InboxManager *inManager = [[InboxManager alloc] init];
        inManager.userId = strUid;
        inManager.currentLoginMailAddress = mail;
        inManager.totalNumberOfMessagesInDB = [Utilities getSentLastFetchCountForUser:strUid];
        isFetchingEmails = NO;
        inManager.delegate = self;
        totalResponseCount++;
        
        NSError *error;
        NSFetchedResultsController *fetchedController = [CoreDataManager fetchedSentEmailsForController:nil forUser:usrId isSearching:NO searchText:nil entity:kENTITY_EMAIL];
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
        fetchedController = nil;
        inManager.entityName = kENTITY_EMAIL;
        [inManager startFetchingMessagesForFolder:kFOLDER_SENT_MAILS andType:kFolderSentMail];
        [self.inboxManagers addObject:inManager];
    }
    if (showProgressDialog) {
        [self showProgressHudWithTitle:kFETCHING_EMAILS];
    }
    else {
        totalResponseCount = 0;
    }
    
    /*else {
     userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
     NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
     NSManagedObject * object = [userArray lastObject];
     
     currentEmail = [object valueForKey:kUSER_EMAIL];
     if (inboxManager == nil) {
     inboxManager = [[InboxManager alloc] init];
     }
     inboxManager.userId = userId;
     inboxManager.currentLoginMailAddress = currentEmail;
     inboxManager.totalNumberOfMessagesInDB = [Utilities getSentLastFetchCountForUser:userId];
     isFetchingEmails = YES;
     inboxManager.delegate = (id)self;
     [inboxManager startFetchingMessagesForFolder:kFOLDER_SENT_MAILS andType:kFolderSentMail];
     }*/
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    [self.txtSearchField addTarget:self action:@selector(textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.navigationController.navigationBar setHidden:NO];
    [self.sentTableView setBackgroundView:nil];
    [self.sentTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Sent";
    
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
-(void)fetchSearchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_SENT_MAILS;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager fetchNextModuleOfSearchedEmails];
        inManager.delegate = self;
    }
}
-(void)searchString:(NSString *)string {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_SENT_MAILS;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager inboxSearchString:string];
        inManager.delegate = self;
    }
}
- (void)updateVisibleRows:(NSNotification *)notification {
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
    
    NSArray *visiblePaths = [self.sentTableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
        
        NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
        // if (imgUrl == nil) {
        // Avoid the app icon download if the app already has an icon
        //[self getUserProfileForEmail:[emailData valueForKey:kEMAIL_TITLE] object:emailData indexPath:indexPath];
        //}
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
-(void)hideHistoryView {
    if([searchHistoryView isDescendantOfView:self.view]) {
        [searchHistoryView removeFromSuperview];
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
}
-(void)showHistoryView {
    if(![searchHistoryView isDescendantOfView:self.view]) {
        searchHistoryView = [[[NSBundle mainBundle] loadNibNamed:@"SearchHistoryView" owner:self options:nil] objectAtIndex:0];
        searchHistoryView.delegate = self;
        [self.view addSubview:searchHistoryView];
        [searchHistoryView setUpView];
        searchHistoryView.translatesAutoresizingMaskIntoConstraints = NO;
        [Utilities setLayoutConstarintsForEditorView:searchHistoryView parentView:self.view fromBottomView:self.view bottomSpace:0.0f topView:self.view topSpace:43.0f leadingSpace:0.0f trailingSpace:0.0f];
    }
}
-(void)refreshServices {
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
-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil entity:kENTITY_EMAIL];
    [self checkEmailCount];
    //    if (self.fetchedResultsController.fetchedObjects.count == 0) {
    //        [self showProgressHudWithTitle:kFETCHING_EMAILS];
    //    }
}
-(void)checkEmailCount {
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
        NSError *error;
        NSFetchedResultsController * fetchController = nil;
        fetchController = [CoreDataManager fetchedSentEmailsForController:fetchController forUser:usrId isSearching:NO searchText:nil entity:kENTITY_EMAIL];
        if (![fetchController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        long count = fetchController.fetchedObjects.count;
        NSLog(@"checkEmailCount = %ld",count);
        if (count == 0) {
            [Utilities updateSentLastFetchCount:0 forUser:strUid];
        }
    }
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
    
    //[self fetchResultsFromDbForString:self.txtSearchField.text];
    if (!isFetchingEmails) {
        if (isSearchingEmails) {
            [self fetchSearchEmails];
        }
        else {
            [self fetchEmails];
        }
    }
    //    if ([self.fetchedResultsController fetchedObjects].count>0) {
    //        [self setActivityIndicatorViewConstant:30.0f];
    //    }
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
-(void)setActivityIndicatorViewConstant:(int)constant {
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
-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:longThreadId andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
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
-(void)fetchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxManagers) {
        inManager.totalNumberOfMessagesInDB = [Utilities getSentLastFetchCountForUser:inManager.userId];
        isFetchingEmails = YES;
        inManager.strFolderName = kFOLDER_SENT_MAILS;
        inManager.folderType = kFolderSentMail;
        [inManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        inManager.delegate = self;
    }
    /*}
     else {
     if (inboxManager == nil) {
     inboxManager = [[InboxManager alloc] init];
     }
     inboxManager.userId = userId;
     inboxManager.currentLoginMailAddress = currentEmail;
     inboxManager.totalNumberOfMessagesInDB = [Utilities getSentLastFetchCountForUser:userId];
     isFetchingEmails = YES;
     inboxManager.strFolderName = kFOLDER_SENT_MAILS;
     inboxManager.folderType = kFolderSentMail;
     inboxManager.delegate = self;
     [inboxManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
     isFetchingEmails = YES;
     }*/
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
    }*/
    
    
    [self.sentTableView.pullToRefreshView stopAnimating];
    [self.sentTableView.infiniteScrollingView stopAnimating];
}
-(void)getUserProfileForEmail:(NSString *)email object:(NSManagedObject *)object  indexPath:(NSIndexPath*)indexPath {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            NSString * strUrl = [[Utilities parseProfile:response] objectAtIndex:1];
            [object setValue:strUrl forKey:kSENDER_IMAGE_URL];
            [CoreDataManager updateData];
            //NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
            //[Utilities reloadTableViewRows:self.sentTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
        }
    } onError:^( NSString *resultMessage , int erorrCode)
     {
         if (erorrCode == -1011) {
             [object setValue:@"NOT FOUND" forKey:kSENDER_IMAGE_URL];
             [CoreDataManager updateData];
         }
         //  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot Fetch Profile!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         //  [av show];
     }];
}
-(void)fetchResultsFromDbForString:(NSString *)text entity:(NSString *)entity {
    self.fetchedResultsController = nil;
    if ([entity isEqualToString:kENTITY_EMAIL]) {
        isSearchingEmails = NO;
    }
    else {
        isSearchingEmails = YES;
    }
    long usr = [userId longLongValue];
    if (self.fetchMultipleAccount) {
        usr = -1;
    }
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        [self.fetchedResultsController setDelegate:self];
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedSentEmailsForController:self.fetchedResultsController forUser:usr isSearching:YES searchText:text entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    }
    else {
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedSentEmailsForController:self.fetchedResultsController forUser:usr isSearching:NO searchText:nil entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self.fetchedResultsController setDelegate:self];
        isSearching = NO;
    }
    [self.sentTableView reloadData];
}
-(void)showNotFoundLabelWithText:(NSString *)text {
    self.lblNoEmailFoundMessage.text = text;
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        [self.lblNoEmailFoundMessage setHidden:NO];
    }
    else {
        [self.lblNoEmailFoundMessage setHidden:YES];
    }
}
-(void)removeDelegates {
    if (self.inboxSearchManagers != nil) {
        for (int i = 0; i<self.inboxSearchManagers.count; ++i) {
            InboxManager * manager = [self.inboxSearchManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    if (searchHistoryView) {
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    if (inboxSync != nil) {
        inboxSync.invalidateTimer = YES;
        inboxSync = nil;
    }
    
    if (sentSync != nil) {
        sentSync.invalidateTimer = YES;
        sentSync = nil;
    }
    
    inboxManager.delegate = nil;
    [inboxManager.imapSession cancelAllOperations];
    inboxManager.imapSession  = nil;
    [self contentFetcherWithBool:NO];
    if (self.inboxManagers != nil) {
        for (int i = 0; i<self.inboxManagers.count; ++i) {
            InboxManager * manager = [self.inboxManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    //    if (self.updateManagers != nil) {
    //        for (int i = 0; i<self.updateManagers.count; ++i) {
    //            EmailUpdateManager * manager = [self.updateManagers objectAtIndex:i];
    //            manager.delegate = nil;
    //            manager = nil;
    //        }
    //    }
}
- (void)textFieldContentDidChange:(id)sender {
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
    //long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    //NSString * strUid = [Utilities getStringFromLong:usrId];
    //MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
    [cell.imgProfile setImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    /*    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
     if ([Utilities isValidString:imgUrl]) {
     [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
     }
     else { // call api for fetching profile pic. if not available
     [cell.imgProfile setImage:[UIImage imageNamed:@"profile_image_placeholder"]];
     [self getUserProfileForEmail:[emailData valueForKey:kEMAIL_TITLE] object:emailData indexPath:indexPath];
     }*/
    
    [self setupSwipeCellOptionsFor:cell];
    
    //cell.delegate = self;
    //cell.allowsOppositeSwipe = NO;
    //cell.allowsMultipleSwipe = YES;
    return [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:nil view:self.view atIndexPath:indexPath isSent:YES];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    return  nil;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    didSelectIndexPath = indexPath;
    NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
    [Utilities reloadTableViewRows:self.sentTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationLeft];
    
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderSentMail];
}
-(void)performActions:(BOOL)isUndoCall {
    for (NSMutableDictionary * dic in self.undoArray) {
        if (isUndoCall) {
            if ([[dic objectForKey:kEMAIL_THREAD_ID] isEqualToString:undoThreadId]) {
                if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    if (messages == nil || messages.count == 0) {
                        [self.undoArray removeObject:dic];
                        return;
                    }
                    [self markDeleteMessageLocally:messages flag:NO];
                    [self.undoArray removeObject:dic];
                }
            }
        }
        else {
            if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
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
#pragma - mark UserActions
-(IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}
-(IBAction)btnNavigationSearchAction:(id)sender {
    UIBarButtonItem * btn = (UIBarButtonItem *)sender;
    float delay = 0;
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

#pragma - mark InboxManagerDelegate

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    [self loadImagesForOnscreenRows ];
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        [self hideProgressHud];
        totalResponseCount = 0;
        //[self setActivityIndicatorViewConstant:0.0f];
        if (self.fetchedResultsController.fetchedObjects.count < 50) {
            isFirstFetchCall = NO;
        }
        else {
            isFetchingEmails = NO;
            return;
        }
        isFetchingEmails = NO;
        //[self fetchEmails];
    }
}
- (void)inboxManager:(InboxManager *)manager didReceiveError:(NSError *)error {
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        //[self setActivityIndicatorViewConstant:0.0f];
        isFetchingEmails = NO;
        [self hideProgressHud];
    }
}
- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId {
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        //[self setActivityIndicatorViewConstant:0.0f];
        isFetchingEmails = NO;
        [self hideProgressHud];
        [self showNotFoundLabelWithText:kNO_SENT_AVAILABLE_MESSAGE];
    }
}
#pragma mark - MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.sentTableView reloadData];
}
#pragma mark - EmailUpdateManagerDelegate
- (void)emailUpdateManager:(EmailUpdateManager*)manager didReceiveNewEmailWithId:(long)userId {
    //[self fetchResultsFromDbForString:self.txtSearchField.text];
}
#pragma mark NSFetchedResultsController Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.sentTableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.sentTableView;
    
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
            [self.sentTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.sentTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.sentTableView endUpdates];
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
    if (direction == MGSwipeDirectionLeftToRight) {
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.sentTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            return YES;
        }];
        return @[btnSwipeDelete];
    }
    else {
        
        expansionSettings.fillOnTrigger = YES;
        return nil;
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
}
#pragma - mark SearchHistoryViewDelegate
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
#pragma mark - UITextFieldDelegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
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
-(void)dealloc {
    NSLog(@"dealloc - SentViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupSwipeCellOptionsFor:(SmartInboxTableViewCell *) cell {
    
    cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_DELETE, nil, nil);
    cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_DELETE, nil, nil);
    
    cell.delegate = self;
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType
{
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.sentTableView indexPathForCell:cell];
        if (indexPath)
        {
            if (swipeType == JZSwipeTypeLongRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeLongLeft) {
                

            }
            else if (swipeType == JZSwipeTypeShortLeft) {

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
