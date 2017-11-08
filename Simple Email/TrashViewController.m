//
//  TrashViewController.m
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "TrashViewController.h"
#import "Utilities.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "InboxManager.h"
#import "MBProgressHUD.h"
#import "WebServiceManager.h"
#import "EmailUpdateManager.h"
#import "CellConfigureManager.h"
#import "SWRevealViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SyncManager.h"
#import "TrashHeaderCell.h"
#import "SearchHistoryView.h"
#import "SVPullToRefresh.h"

@interface TrashViewController () <JZSwipeCellDelegate>

@end

@implementation TrashViewController {
    BOOL isSearching;
    NSString * userId;
    MBProgressHUD * hud;
    BOOL isUpdateCallMade;
    BOOL isFetchingEmails;
    BOOL isFirstFetchCall;
    int totalResponseCount;
    SyncManager * trashSync;
    InboxManager * inboxManager;
    NSIndexPath* didSelectIndexPath;
    EmailUpdateManager * updateManager;
    NSMutableDictionary * contentFetcherDictionary;
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
    
    __weak TrashViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.trashTableView addPullToRefreshWithActionHandler:^{
        
        [weakSelf fetchEmails];
    }];
    
    // setup infinite scrolling
    [self.trashTableView addInfiniteScrollingWithActionHandler:^{
        
        //[self fetchEmails];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    [self setUpView];
    [self startFetchingTrashMails];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
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
        [inManager startFetchingMessagesForFolder:kFOLDER_TRASH_MAILS andType:kFolderInboxMail];
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
    //    if (didSelectIndexPath !=nil) {
    //        NSArray* indexArray = [NSArray arrayWithObjects:didSelectIndexPath, nil];
    //        [Utilities reloadTableViewRows:self.trashTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationRight];
    //        didSelectIndexPath = nil;
    //    }
    if (!isFirstFetchCall) {
        [self showNotFoundLabelWithText:kNO_TRASH_AVAILABLE_MESSAGE];
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
#pragma - mark Private Methods
-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil entity:kENTITY_EMAIL];
    [self checkEmailCount];
    //    if (self.fetchedResultsController.fetchedObjects.count == 0) {
    //        [self showProgressHudWithTitle:kFETCHING_EMAILS];
    //    }
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}
-(void)refreshServices {
    if (trashSync != nil) {
        trashSync.invalidateTimer = YES;
        trashSync = nil;
    }
    
    trashSync = [[SyncManager alloc] init];
    [trashSync syncEmailForFolder:@"TRASH"];
}
-(void)setUpView {
    [self contentFetcherWithBool:YES];
    [self setActivityIndicatorViewConstant:0.0f];
    isUpdateCallMade = NO;
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    [self initfetchedResultsController];
    
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    isFirstFetchCall = YES;
    [self.txtSearchField addTarget:self action:@selector(textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
    UIBarButtonItem * btnNavSearch=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavigationSearchAction:)];
    self.navigationItem.rightBarButtonItem = btnNavSearch;
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.trashTableView setBackgroundView:nil];
    [self.trashTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Trash";
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:revealController
                                                             action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVisibleRows:) name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
}
- (void)updateVisibleRows:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
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
    
    NSArray *visiblePaths = [self.trashTableView indexPathsForVisibleRows];
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
-(void)showNotFoundLabelWithText:(NSString *)text {
    self.lblNoEmailFoundMessage.text = text;
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        [self.lblNoEmailFoundMessage setHidden:NO];
    }
    else {
        [self.lblNoEmailFoundMessage setHidden:YES];
    }
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
-(void)checkEmailCount {
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
        NSError *error;
        NSFetchedResultsController * fetchController = nil;
        fetchController = [CoreDataManager fetchedTrashEmailsForController:fetchController forUser:usrId isSearching:NO searchText:@"" entity:kENTITY_EMAIL];;
        if (![fetchController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        long count = fetchController.fetchedObjects.count;
        NSLog(@"checkEmailCount = %ld",count);
        if (count == 0) {
            [Utilities updateTrashLastFetchCount:0 ForUser:strUid];
        }
    }
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
-(void)fetchResultsFromDbForString:(NSString *)text entity:(NSString *)entity {
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
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedTrashEmailsForController:self.fetchedResultsController forUser:usr isSearching:YES searchText:text entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self.fetchedResultsController setDelegate:self];
        [self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    }
    else {
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedTrashEmailsForController:self.fetchedResultsController forUser:usr isSearching:NO searchText:@"" entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
    }
    [self.trashTableView reloadData];
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

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:[object entity].name];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_inbox" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Email moved";
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
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            NSArray * array =  [Utilities getIndexSetFromObject:obj];
            MCOIndexSet * indexSet = [array objectAtIndex:1];
            NSString * entity = [obj entity].name;
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:kFOLDER_TRASH_MAILS withSessaion:imapSession toFolder:kFOLDER_INBOX completionBlock:^(id response) {
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
-(void)btnSwipeMarkMessageAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * folder = [object valueForKey:kMAIL_FOLDER];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
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
    [self setActivityIndicatorViewConstant:30.0f];
    
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
-(void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
    undoThreadId = strThreadId;
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
    
    
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
        [object setValue:[NSNumber numberWithBool:flag] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
    }
}
-(void)markDeleteOnServer:(NSMutableArray*)messages{
    __weak typeof(self) weakSelf = self;
    MCOIndexSet * finalIndexSet = [[MCOIndexSet alloc] init];
    for (NSManagedObject * obj in messages) {
        long idsz = [[obj valueForKey:kEMAIL_ID] longLongValue];
        [finalIndexSet addIndex:idsz];
    }
    
    if (finalIndexSet.count == 0) {
        return;
    }
    NSManagedObject * object = nil;
    if (messages.count>0) {
        object = [messages objectAtIndex:0];
    }
    if (object == nil) {
        return;
    }
    long longUserId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:longUserId];
    NSArray * array =  [Utilities getIndexSetFromObject:object];
    NSString * folderName = [array objectAtIndex:0];
    MCOMessageFlag newflags = MCOMessageFlagDraft;
    
    newflags |= MCOMessageFlagDeleted;
    newflags |= !MCOMessageFlagFlagged;
    
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
    if (imapSession != nil) {
        MCOIMAPOperation *changeFlags = [imapSession storeFlagsOperationWithFolder:folderName  uids:finalIndexSet kind:MCOIMAPStoreFlagsRequestKindSet flags:newflags];
        [changeFlags start:^(NSError *error) {
            if (!error) {
                for (NSManagedObject * obj in messages) {
                    [CoreDataManager deleteObject:obj];
                }
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
                for (NSManagedObject * obj in messages) {
                    [obj setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                }
                [CoreDataManager updateData];
            }
        }];
    }
}
-(void)emptyTrash {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    
    [self showProgressHudWithTitle:@"Removing Emails"];
    
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    __block int callCount = (int)users.count;
    for (int i = 0; i<users.count; ++i) {
        NSManagedObject * object = [users objectAtIndex:i];
        if (users.count>0) {
            long usrId = [[object valueForKey:kUSER_ID] longLongValue];
            NSString * strUid = [Utilities getStringFromLong:usrId];
            MCOIMAPSession * session = [Utilities getSessionForUID:strUid];
            if (session != nil) {
                [[MailCoreServiceManager sharedMailCoreServiceManager] searchTrashMails:session userId:strUid completionBlock:^(NSError * error, MCOIndexSet * indexset) {
                    if (error == nil && indexset.count>0) {
                        NSLog(@"TRASH COUNT: %u",indexset.count);
                        [[MailCoreServiceManager sharedMailCoreServiceManager] deleteIndexSet:indexset imapSession:session userId:strUid completionBlock:^(NSError * error) {
                            if (error == nil) {
                                NSLog(@"\nFlag has been changed changed\n");
                                [[MailCoreServiceManager sharedMailCoreServiceManager]expungeFolder:session userId:strUid completionBlock:^(NSError * error) {
                                    if (error != nil) {
                                        NSLog(@"\nExpunge Failed\n");
                                    }
                                    else {
                                        NSLog(@"\nFolder Expunged\n");
                                        NSLog(@"USER ID: %@",strUid);
                                        NSError * er = [CoreDataManager deleteAllTrash:strUid];
                                        if (er == nil) {
                                            
                                        }
                                    }
                                    callCount--;
                                    if (callCount<=0) {
                                        [self hideProgressHud];
                                        [self.trashTableView reloadData];
                                    }
                                }];
                            }
                            else {
                                NSLog(@"\nError with flag changing\n");
                                callCount--;
                                if (callCount<=0) {
                                    [self hideProgressHud];
                                }
                            }
                        }];
                    }
                    else {
                        callCount--;
                        if (callCount<=0) {
                            [self hideProgressHud];
                        }
                    }
                }];
            }
        }
    }
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
- (void)textFieldContentDidChange:(id)sender {
}
-(void)startFetchingTrashMails {
    BOOL showProgressDialog = NO;
    self.inboxManagers = [NSMutableArray new];
    NSMutableArray * users = nil;
    if (self.fetchMultipleAccount) {
        users = [CoreDataManager fetchAllUsers];
    }
    else {
        users = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    }
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [userObject valueForKey:kUSER_EMAIL];
        
        InboxManager *inManager = [[InboxManager alloc] init];
        inManager.userId = strUid;
        inManager.currentLoginMailAddress = mail;
        inManager.totalNumberOfMessagesInDB = [Utilities getTrashLastFetchCountForUser:strUid];
        isFetchingEmails = NO;
        inManager.delegate = self;
        totalResponseCount++;
        
        NSError *error;
        NSFetchedResultsController *fetchedController = [CoreDataManager fetchedTrashEmailsForController:nil forUser:usrId isSearching:NO searchText:@"" entity:kENTITY_EMAIL];
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
        [inManager startFetchingMessagesForFolder:kFOLDER_TRASH_MAILS andType:kFolderTrashMail];
        [self.inboxManagers addObject:inManager];
    }
    if (showProgressDialog) {
        [self showProgressHudWithTitle:kFETCHING_EMAILS];
    }
    else {
        totalResponseCount = 0;
    }
    /*    }
     else {
     if (inboxManager == nil) {
     inboxManager = [[InboxManager alloc] init];
     }
     inboxManager.entityName = kENTITY_EMAIL;
     inboxManager.userId = userId;
     inboxManager.totalNumberOfMessagesInDB = [Utilities getTrashLastFetchCountForUser:userId];
     isFetchingEmails = YES;
     [inboxManager startFetchingMessagesForFolder:kFOLDER_TRASH_MAILS andType:kFolderTrashMail];
     inboxManager.delegate = self;
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
    }
    */
    [self.trashTableView.pullToRefreshView stopAnimating];
    [self.trashTableView.infiniteScrollingView stopAnimating];
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
        //[self setActivityIndicatorViewConstant:30.0f];
    }
}
-(void)fetchSearchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxSearchManagers) {
        isFetchingEmails = YES;
        inManager.fetchMessages = YES;
        inManager.strFolderName = kFOLDER_TRASH_MAILS;
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
        inManager.strFolderName = kFOLDER_TRASH_MAILS;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_SEARCH_EMAIL;
        [inManager inboxSearchString:string];
        inManager.delegate = self;
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
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_inbox"]) {
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
            }
        }
        else {
            if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_message"]) {
                NSMutableDictionary * dictionaryCopy = [dic copy];
                [self markMessageOnServer:dictionaryCopy];
                [self.undoArray removeObject:dic];
            }
            else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_inbox"]) {
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

-(void)fetchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxManagers) {
        inManager.totalNumberOfMessagesInDB = [Utilities getTrashLastFetchCountForUser:inManager.userId];
        isFetchingEmails = YES;
        inManager.strFolderName = kFOLDER_TRASH_MAILS;
        inManager.folderType = kFolderTrashMail;
        [inManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        inManager.delegate = self;
    }
    /*}
     else {
     inboxManager.totalNumberOfMessagesInDB = [Utilities getTrashLastFetchCountForUser:userId];
     isFetchingEmails = YES;
     [inboxManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
     inboxManager.delegate = self;
     }*/
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
    if (trashSync != nil) {
        trashSync.invalidateTimer = YES;
        trashSync = nil;
    }
    
    [self contentFetcherWithBool:NO];
    if (self.inboxManagers != nil) {
        for (int i = 0; i<self.inboxManagers.count; ++i) {
            InboxManager * manager = [self.inboxManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    if (inboxManager) {
        inboxManager.delegate = nil;
    }
    if (updateManager) {
        updateManager.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
}
#pragma - mark UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //return self.messagesArray.count;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"SmartInboxCell";
    
    SmartInboxTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib= [[NSBundle mainBundle] loadNibNamed:@"SmartInboxTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    //NSString * strUid = [Utilities getStringFromLong:usrId];
    //MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
    
    //    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
    //    if ([Utilities isValidString:imgUrl]) {
    //        [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    //    }
    //    else { // call api for fetching profile pic. if not available
    //        [cell.imgProfile setImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    //        [self getUserProfileForEmail:[emailData valueForKey:kEMAIL_TITLE] object:emailData indexPath:indexPath];
    //    }
    
    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
    if (imgUrl != nil && ![imgUrl isEqualToString:kNOT_FOUND]) {
        [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    }
    else {
        cell.imgProfile.image = [UIImage imageNamed:@"profile_image_placeholder"];
    }
    
    [self setupSwipeCellOptionsFor:cell indexPath:indexPath];
    
    //cell.delegate = self;
    //cell.allowsOppositeSwipe = NO;
    //cell.allowsMultipleSwipe = YES;
    return [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:nil view:self.view atIndexPath:indexPath isSent:NO];
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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *tableIdentifier = @"TrashHeader";
    TrashHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TrashHeaderCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [cell.btnEmptyTrash addTarget:self action:@selector(btnEmptyTrashAction:) forControlEvents:UIControlEventTouchUpInside];
    return  cell.contentView;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.fetchedResultsController.fetchedObjects.count>0) {
        return 0.0f;//30.0f;
    }
    return 0.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    didSelectIndexPath = indexPath;
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderTrashMail];
}


#pragma - mark User Actions
-(void)btnEmptyTrashAction:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Trash"
                                                    message:@"Do you want to delete all trash emails permanently?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes",nil];
    [alert show];
}

#pragma - mark InboxManagerDelegate

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    totalResponseCount++;
    [self loadImagesForOnscreenRows];
    if (totalResponseCount>=self.inboxManagers.count) {
        [self hideProgressHud];
        totalResponseCount = 0;
        [self setActivityIndicatorViewConstant:0.0f];
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
        isFetchingEmails = NO;
        [self setActivityIndicatorViewConstant:0.0f];
        [self hideProgressHud];
    }
}
- (void)inboxManager:(InboxManager *)manager noEmailsToFetchForId:(int)userId {
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        isFetchingEmails = NO;
        [self setActivityIndicatorViewConstant:0.0f];
        [self hideProgressHud];
        [self showNotFoundLabelWithText:kNO_TRASH_AVAILABLE_MESSAGE];
    }
}
#pragma - mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self emptyTrash];
    }
}
#pragma mark NSFetchedResultsController Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.trashTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.trashTableView;
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
            [self.trashTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeDelete:
            [self.trashTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.trashTableView endUpdates];
}
#pragma mark  - MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    //[Utilities reloadTableViewRows:self.trashTableView forIndexArray:[NSArray arrayWithObjects:indexPath, nil] withAnimation:UITableViewRowAnimationNone];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.trashTableView reloadData];
}
#pragma mark - EmailUpdateManagerDelegate
- (void)emailUpdateManager:(EmailUpdateManager*)manager didReceiveNewEmailWithId:(long)userId {
    //[self fetchResultsFromDbForString:self.txtSearchField.text];
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
    
    NSIndexPath * indexPath = [weakSelf.trashTableView indexPathForCell:cell];
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
            
            NSIndexPath * indexPath = [weakSelf.trashTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            return YES;
        }];
        
        MGSwipeButton * btnSwipeUnread = [MGSwipeButton buttonWithTitle:title icon:nil backgroundColor:[UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.trashTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeMarkMessageAtIndexPath:indexPath];
            }
            
            return YES;
        }];
        return @[btnSwipeUnread, btnSwipeDelete];
    }
    else {
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeInbox = [MGSwipeButton buttonWithTitle:@"Inbox" icon:nil backgroundColor:[UIColor colorWithRed:167.0f/255.0f green:102.0f/255.0f blue:166.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.trashTableView indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            return YES;
        }];
        [btnSwipeInbox setButtonWidth:83];
        return @[btnSwipeInbox];
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
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    NSLog(@"dealloc - TrashViewController");
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
    cell.imageSet = SwipeCellImageSetMake([self getReadUnReadImageForCell:indexPath], kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_INBOX, kIMAGE_SWIPE_CELL_INBOX);
    cell.colorSet = SwipeCellColorSetMake([self getReadUnReadColorForCell:indexPath], kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_INBOX, kCOLOR_SWIPE_CELL_INBOX);
    cell.delegate = self;
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType
{
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.trashTableView indexPathForCell:cell];
        if (indexPath)
        {
            if (swipeType == JZSwipeTypeLongRight) {
                 [self btnSwipeMarkMessageAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeLongLeft) {
                
                [self btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortLeft) {
                [self btnSwipeArchiveActionAtIndexPath:indexPath];
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
