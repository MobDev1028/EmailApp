//
//  DraftViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "DraftViewController.h"
#import "Constants.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import "InboxManager.h"
#import "MBProgressHUD.h"
#import "EmailUpdateManager.h"
#import "DraftTableViewCell.h"
#import "SWRevealViewController.h"
#import "EmailComposerViewController.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "MailCoreServiceManager.h"
#import "SyncManager.h"
#import "SearchHistoryView.h"

@interface DraftViewController ()

@end

@implementation DraftViewController {
    BOOL isSearching;
    NSString * userId;
    MBProgressHUD * hud;
    BOOL isFirstFetchCall;
    BOOL isUpdateCallMade;
    BOOL isFetchingEmails;
    NSString * currentEmail;
    InboxManager * inboxManager;
    NSMutableDictionary * contentFetcherDictionary;
    SyncManager * draftSync;
    int totalResponseCount;
    SearchHistoryView * searchHistoryView;
    BOOL isSearchingEmails;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isSearchingEmails = NO;
    totalResponseCount = 0;
    undoThreadId = nil;
    [self refreshServices];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    
    [self removeclones];
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
        [inManager startFetchingMessagesForFolder:kFOLDER_DRAFT_MAILS andType:kFolderInboxMail];
        [self.inboxSearchManagers addObject:inManager];
    }
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    isUpdateCallMade = NO;
    [self.draftTableView reloadData];
    if (!isFirstFetchCall) {
        // [self showNotFoundLabelWithText:kNO_DRAFT_AVAILABLE_MESSAGE];
    }
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
    
    NSArray *visiblePaths = [self.draftTableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
        
        if (messagePreview == nil) {
            long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
            NSString * strUid = [Utilities getStringFromLong:usrId];
            NSString * messageId = [emailData valueForKey:kEMAIL_ID];
            NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
            BOOL isFakeDraft = [[emailData valueForKey:kIS_FAKE_DRAFT] boolValue];
            MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
            if (contentFetchManager != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (!isFakeDraft) {
                        [contentFetchManager startFetchOpWithFolder:folder andMessageId:[messageId intValue] forNSManagedObject:emailData nsindexPath:indexPath needHtml:NO];
                    }
                });
            }
        }
    }
}

#pragma - mark Private Methods

-(void) receiveNotification:(NSNotification*)notification
{
    if ([notification.name isEqualToString:kNSNOTIFICATIONCENTER_LOGOUT])
    {
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
-(void)setUpView {
    [self contentFetcherWithBool:YES];
    [self setActivityIndicatorViewConstant:0.0f];
    isUpdateCallMade = YES;
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    [self initfetchedResultsController];
    NSMutableArray * users = nil;
    if (self.fetchMultipleAccount) {
        users = [CoreDataManager fetchAllUsers];
    }
    else {
        users = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    }
    self.inboxManagers = [NSMutableArray new];
    BOOL showProgressDialog = NO;
    self.updateManagers = [NSMutableArray new];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [userObject valueForKey:kUSER_EMAIL];
        
        InboxManager *inManager = [[InboxManager alloc] init];
        inManager.userId = strUid;
        inManager.currentLoginMailAddress = mail;
        inManager.totalNumberOfMessagesInDB = [Utilities getDarftLastFetchCountForUser:strUid];
        isFetchingEmails = NO;
        inManager.delegate = self;
        totalResponseCount++;
        
        NSError *error;
        NSFetchedResultsController *fetchedController = [CoreDataManager initFetchedResultsController:nil forUser:usrId isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:YES isSent:NO entity:kENTITY_EMAIL];
        
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
        [inManager startFetchingMessagesForFolder:kFOLDER_DRAFT_MAILS andType:kFolderDraftMail];
        [self.inboxManagers addObject:inManager];
        
        /* create update manager for every account */
        EmailUpdateManager * updateManager = [[EmailUpdateManager alloc] init];
        updateManager.folderName = kFOLDER_DRAFT_MAILS;
        updateManager.currentLoginMailAddress = mail;
        updateManager.delegate = self;
        [updateManager createUpdateSessionWithId:strUid];
        [self.updateManagers addObject:updateManager];
    }
    if (showProgressDialog) {
        [self showProgressHudWithTitle:kFETCHING_EMAILS];
    }
    else {
        totalResponseCount = 0;
    }
    /* else {
     userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
     NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
     NSManagedObject * object = [userArray lastObject];
     currentEmail = [object valueForKey:kUSER_EMAIL];
     
     if (inboxManager == nil) {
     inboxManager = [[InboxManager alloc] init];
     }
     inboxManager.entityName = kENTITY_EMAIL;
     inboxManager.userId = userId;
     inboxManager.totalNumberOfMessagesInDB = [Utilities getDarftLastFetchCountForUser:userId];
     inboxManager.delegate = self;
     [inboxManager startFetchingMessagesForFolder:kFOLDER_DRAFT_MAILS andType:kFolderDraftMail];
     }*/
    isFirstFetchCall = YES;
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.draftTableView setBackgroundView:nil];
    [self.draftTableView setBackgroundColor:[UIColor clearColor]];
    
    self.title = @"Draft";
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    [self.txtSearchField addTarget:self action:@selector(textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
    UIBarButtonItem * btnNavSearch=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavigationSearchAction:)];
    self.navigationItem.rightBarButtonItem = btnNavSearch;
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[self revealViewController]
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
-(void)refreshServices {
    if (draftSync != nil) {
        draftSync.invalidateTimer = YES;
        draftSync = nil;
    }
    draftSync = [[SyncManager alloc] init];
    [draftSync syncEmailForFolder:@"DRAFT"];
}
-(void)removeclones {
    NSMutableArray * cloneDrafts = [CoreDataManager fetchAllFakeDrafts];
    for (int x = 0; x<cloneDrafts.count; ++x) {
        NSManagedObject * cloneObject = [cloneDrafts objectAtIndex:x];
        [CoreDataManager deleteObject:cloneObject];
    }
    [CoreDataManager updateData];
}
-(void)fetchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxManagers) {
        inManager.totalNumberOfMessagesInDB = [Utilities getDarftLastFetchCountForUser:inManager.userId];
        isFetchingEmails = YES;
        inManager.strFolderName = kFOLDER_DRAFT_MAILS;
        inManager.folderType = kFolderDraftMail;
        [inManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        inManager.delegate = self;
    }
    /*else {
     if (inboxManager == nil) {
     inboxManager = [[InboxManager alloc] init];
     }
     inboxManager.userId = userId;
     inboxManager.totalNumberOfMessagesInDB = [Utilities getDarftLastFetchCountForUser:userId];
     isFetchingEmails = YES;
     inboxManager.strFolderName = kFOLDER_DRAFT_MAILS;
     inboxManager.folderType = kFolderDraftMail;
     [inboxManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
     inboxManager.delegate = self;
     isFetchingEmails = YES;*/
}
-(void)checkEmailCount {
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSError *error;
        NSFetchedResultsController * fetchController = nil;
        fetchController = [CoreDataManager initFetchedResultsController:fetchController forUser:usrId isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:YES isSent:NO entity:kENTITY_EMAIL];
        if (![fetchController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        long count = fetchController.fetchedObjects.count;
        NSLog(@"checkEmailCount = %ld",count);
        if (count == 0) {
            [Utilities updateDarftLastFetchCount:0 ForUser:strUid];
        }
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
-(void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self setActivityIndicatorViewConstant:30.0f];
    BOOL isFake = [[object valueForKey:kIS_FAKE_DRAFT] boolValue];
    if (isFake) {
        return;
    }
    
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    NSMutableArray * emailArray = [[NSMutableArray alloc] init];
    [emailArray addObject:object];
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_delete" forKey:@"actiontype"];
    [undoDictionary setObject:emailArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Delete marked";
    
    [object setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
    [CoreDataManager updateData];
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    
}
-(void)markDeleteOnServer:(NSMutableArray*)messages {
    if (messages == nil || messages.count == 0) {
        return;
    }
    NSManagedObject * object = [messages objectAtIndex:0];
    __weak typeof(self) weakSelf = self;
    long longUserId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:longUserId];
    NSArray * array =  [Utilities getIndexSetFromObject:object];
    NSString * folderName = [array objectAtIndex:0];
    MCOIndexSet * indexSet = [array objectAtIndex:1];
    
    MCOMessageFlag newflags = MCOMessageFlagDraft;
    newflags |= MCOMessageFlagDeleted;
    
    newflags |= !MCOMessageFlagFlagged;
    
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
    if (imapSession != nil) {
        [object setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
        
        MCOIMAPOperation *changeFlags = [imapSession  storeFlagsOperationWithFolder:folderName  uids:indexSet kind:MCOIMAPStoreFlagsRequestKindSet flags:newflags];
        [changeFlags start:^(NSError *error) {
            if (!error) {
                [CoreDataManager deleteObject:object];
                [CoreDataManager updateData];
                NSLog(@"\nFlag has been changed changed\n");
                MCOIMAPOperation *expungeOp = [imapSession expungeOperation:folderName];
                [expungeOp start:^(NSError *error) {
                    if (error) {
                        NSLog(@"\nExpunge Failed\n");
                    }
                    else {
                        NSLog(@"\nFolder Expunged\n");
                    }
                }];
            }
            else {
                NSLog(@"\nError with flag changing\n");
                [weakSelf showAlertWithTitle:@"error!" andMessage:[NSString stringWithFormat:@"Cannot Delete Draft."] withDelegate:nil];
                [object setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                [CoreDataManager updateData];
            }
            
        }];
        
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
    if (!isFetchingEmails) {
        if (isSearchingEmails) {
            [self fetchSearchEmails];
        }
        else {
            [self fetchEmails];
        }
    }
    if ([self.fetchedResultsController fetchedObjects].count>0) {
        // [self setActivityIndicatorViewConstant:30.0f];
    }
}
-(void)fetchSearchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_DRAFT_MAILS;
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
        inManager.strFolderName = kFOLDER_DRAFT_MAILS;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager inboxSearchString:string];
        inManager.delegate = self;
    }
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
-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil entity:kENTITY_EMAIL];
    [self checkEmailCount];
    [self.lblNoEmailFoundMessage setHidden:YES];
    //    if (self.fetchedResultsController.fetchedObjects.count == 0) {
    //        [self showProgressHudWithTitle:kFETCHING_DRAFTS];
    //    }
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
                    NSManagedObject * object = [messages objectAtIndex:0];
                    [object setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                    [CoreDataManager updateData];
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
    /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
     [self showHistoryView];
     });*/
}

- (void)textFieldContentDidChange:(id)sender {
    
}
-(void)fetchResultsFromDbForString :(NSString *)text entity:(NSString *)entity {
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
        self.fetchedResultsController = [CoreDataManager initFetchedResultsController:self.fetchedResultsController forUser:usr isSearching:YES searchText:text fetchArchive:NO fetchDraft:YES isSent:NO entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        //showNotFoundLabelWithText[self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    }
    else {
        NSError *error;
        self.fetchedResultsController = [CoreDataManager initFetchedResultsController:self.fetchedResultsController forUser:usr isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:YES isSent:NO entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self.fetchedResultsController setDelegate:self];
        isSearching = NO;
    }
    [self.draftTableView reloadData];
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

-(void)removeDelegates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    if (draftSync != nil) {
        draftSync.invalidateTimer = YES;
        draftSync = nil;
    }
    [self removeclones];
    
    if (inboxManager != nil) {
        inboxManager.delegate = nil;
        [inboxManager.imapSession cancelAllOperations];
        inboxManager.imapSession  = nil;
    }
    [self contentFetcherWithBool:NO];
    if (self.inboxManagers != nil) {
        for (int i = 0; i<self.inboxManagers.count; ++i) {
            InboxManager * manager = [self.inboxManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    
    if (self.updateManagers != nil) {
        for (int i = 0; i<self.updateManagers.count; ++i) {
            EmailUpdateManager * manager = [self.updateManagers objectAtIndex:i];
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
    if (searchHistoryView) {
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
}
#pragma - mark UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"DraftCell";
    
    DraftTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DraftTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * subject = [object valueForKey:kEMAIL_SUBJECT];
    if (![Utilities isValidString:subject]) {
        subject = kNO_SUBJECT_MESSAGE;
    }
    cell.lblSubject.text = subject;
    
    NSString * messagePreview = [object valueForKey:kEMAIL_PREVIEW];
    
    NSString * messageId = [object valueForKey:kEMAIL_ID];
    //long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    //NSString * strUid = [Utilities getStringFromLong:usrId];
    //MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
    BOOL isFakeDraft = [[object valueForKey:kIS_FAKE_DRAFT] boolValue];
    if (isFakeDraft) {
        cell.delegate = nil;
        cell.imgDraft.image = [UIImage imageNamed:@"img_warning"];
    }
    else {
        cell.imgDraft.image = [UIImage imageNamed:@"img_draft"];
        cell.delegate = self;
        cell.allowsOppositeSwipe = NO;
        cell.allowsMultipleSwipe = YES;
    }
    cell.tag = messageId.integerValue;
    if ([Utilities isValidString:messagePreview]) {
        cell.lblPreview.text = messagePreview;
    }
    else { // get message preview if not available in db
        cell.lblPreview.text = @" ";
        //if (!isFakeDraft) {
        //[contentFetchManager startFetchOpWithFolder:[object valueForKey:kMAIL_FOLDER] andMessageId:[messageId intValue] forNSManagedObject:object nsindexPath:indexPath needHtml:NO];
        //}
    }
    return  cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 99.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * draft = [self.fetchedResultsController objectAtIndexPath:indexPath];
    BOOL isFakeDraft = [[draft valueForKey:kIS_FAKE_DRAFT] boolValue];
    if (isFakeDraft) {
        return;
    }
    EmailComposerViewController * mailComposer = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    mailComposer.isDraft = YES;
    mailComposer.draftObject = draft;
    [self.navigationController pushViewController:mailComposer animated:YES];
}

-(IBAction)btnAddDraftAction:(id)sender {
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @"Compose";
    emailComposerViewController.isDraft = NO;
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}

#pragma - mark InboxManagerDelegate
- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    [self loadImagesForOnscreenRows];
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        [self hideProgressHud];
        totalResponseCount = 0;
        //[self setActivityIndicatorViewConstant:0.0f];
        if (self.fetchedResultsController.fetchedObjects.count < 50 || isFirstFetchCall) {
            isFirstFetchCall = NO;
            //[self fetchResultsFromDbForString:self.txtSearchField.text];
        }
        else {
            isFetchingEmails = NO;
            return;
        }
        isFetchingEmails = NO; /* this need to remove in order tor estore old fetch logic */
        //[self fetchEmails];
    }
}

- (void)inboxManager:(InboxManager *)manager didReceiveError:(NSError *)error {
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        isFetchingEmails = NO;
        //[self setActivityIndicatorViewConstant:0.0f];
        [self hideProgressHud];
    }
}
- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId {
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        isFetchingEmails = NO;
        //[self setActivityIndicatorViewConstant:0.0f];
        [self hideProgressHud];
        //[self showNotFoundLabelWithText:kNO_DRAFT_AVAILABLE_MESSAGE];
    }
    //});
}
#pragma mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    //    NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:indexPath];//[self.messagesArray objectAtIndex:indexPath.row];
    //
    //    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    //    [obj setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    // [CoreDataManager updateData];
    /*if (isSearching == NO) {
     NSInteger totalRowsInSection = [self.draftTableView numberOfRowsInSection:indexPath.section];
     if (indexPath.row<=totalRowsInSection-1) {
     NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
     [Utilities reloadTableViewRows:self.draftTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
     }
     }*/
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.draftTableView reloadData];
}
#pragma mark - EmailUpdateManagerDelegate
- (void)emailUpdateManager:(EmailUpdateManager*)manager didReceiveNewEmailWithId:(long)userId {
    //    updateManager.delegate = nil;
    //    updateManager = nil;
    //[self fetchResultsFromDbForString:self.txtSearchField.text];
}
#pragma - mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.draftTableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.draftTableView;
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
            [self.draftTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.draftTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.draftTableView endUpdates];
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
            NSIndexPath * indexPath = [weakSelf.draftTableView indexPathForCell:sender];
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
    // NSLog(@"Swipe state: %@ ::: Gesture: %@", str, gestureIsActive ? @"Active" : @"Ended");
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
    NSLog(@"dealloc : DraftViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
