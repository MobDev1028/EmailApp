//
//  InboxViewController.m
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "InboxViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "SmartInboxTableViewCell.h"
#import "MoreButtonTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "MailThreadViewController.h"
#import "EmailDetailViewController.h"
#import "Utilities.h"
#import "SnoozeView.h"
#import "CustomizeSnoozesViewController.h"
#import "ComposeQuickResponseViewController.h"
#import "DatePickerView.h"
#import "Constants.h"
#import "CoreDataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "WebServiceManager.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import "EmailComposerViewController.h"
#import "CellConfigureManager.h"
#import "SharedInstanceManager.h"
#import "EmailListenerManager.h"
#import "ArchiveManager.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "UnreadFetchManager.h"
#import "SyncManager.h"
#import "MBProgressHUD.h"
#import "SideMenuViewController.h"
#import "ArchiveViewController.h"
#import "SnoozedViewController.h"
#import "SearchHistoryView.h"
#import "SVPullToRefresh.h"

static const int fixedFetchLimit = 10;
BOOL startTableViewUpdate;
@interface InboxViewController () <JZSwipeCellDelegate, UITextFieldDelegate>

@end

@implementation InboxViewController {
    SnoozeView *snoozeView;
    DatePickerView * datePickerView;
    BOOL isSearching;
    long favoriteMoreRows;
    long favoriteOffset;
    BOOL addMoreRowForFavorite;
    NSIndexPath * didSelectIndexPath;
    BOOL snoozedOnlyIfNoReply;
    BOOL isFetchingEmails;
    BOOL isFirstFetchCall;
    NSMutableDictionary * contentFetcherDictionary;
    NSMutableDictionary * tableViewLastSate;
    int totalResponseCount;
    NSManagedObject * snoozeObject;
    SyncManager * inboxSync;
    SyncManager * sentSync;
    MBProgressHUD *hud;
    SearchHistoryView * searchHistoryView;
    BOOL isSearchingEmails;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    totalResponseCount = 0;
    undoThreadId = nil;
    isSearchingEmails = NO;
    [self.txtSearchField addTarget:self action:@selector(startContentSearch:) forControlEvents:UIControlEventEditingChanged];
    [self contentFetcherWithBool:YES];
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    __weak InboxViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.tableview addPullToRefreshWithActionHandler:^{
        
        [weakSelf fetchEmails];
    }];
    
    // setup infinite scrolling
    [self.tableview addInfiniteScrollingWithActionHandler:^{
        
        [weakSelf scrollingFinish];
    }];
    
    self.txtSearchField.text = @"";
    heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    if (tableViewLastSate == nil) {
        tableViewLastSate = [[NSMutableDictionary alloc] init];
    }
    [self fetchMailsFromDB];
    [self setUpView];
    [self initfetchedResultsController];
    isFirstFetchCall = YES;
    self.inboxManagers = [NSMutableArray new];
    self.unreadFetchManagers = [NSMutableDictionary new];
    NSMutableArray * users = [CoreDataManager fetchAllUsers];
    BOOL showProgressDialog = NO;
    for (NSManagedObject * userObject in users) {
        long usrId = [[userObject valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        NSString * mail = [userObject valueForKey:kUSER_EMAIL];
        
        UnreadFetchManager * unreadFetchManager = [[UnreadFetchManager alloc] init];
        unreadFetchManager.currentLoginMailAddress = mail;
        unreadFetchManager.folderType = kFolderInboxMail;
        unreadFetchManager.strFolderName = kFOLDER_INBOX;
        unreadFetchManager.delegate = self;
        [unreadFetchManager createSessionForUser:strUid];
        [self.unreadFetchManagers setObject:unreadFetchManager forKey:mail];
        
        totalResponseCount++;
        InboxManager *inManager = [[InboxManager alloc] init];
        inManager.userId = strUid;
        inManager.currentLoginMailAddress = mail;
        inManager.totalNumberOfMessagesInDB = [Utilities getInboxLastFetchCount:strUid];
        isFetchingEmails = NO;
        inManager.delegate = self;
        inManager.fetchMessages = NO;
        
        NSError *error;
        NSFetchedResultsController *fetchedController = [CoreDataManager fetchedRegularEmailsForController:nil forUser:usrId isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:YES  entity:kENTITY_EMAIL];
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
        [self.tableview triggerPullToRefresh];
    }
    else {
        totalResponseCount = 0;
    }
    [self refreshServices];
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
    
    [self.tableview.pullToRefreshView stopAnimating];
    [self.tableview.infiniteScrollingView stopAnimating];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (isSearchingEmails) {
        return;
    }
    startTableViewUpdate = YES;
    if (didSelectIndexPath != nil) {
        //[Utilities reloadTableViewRows:self.tableview forIndexArray:[NSArray arrayWithObjects:didSelectIndexPath, nil] withAnimation:UITableViewRowAnimationRight];
        didSelectIndexPath = nil;
        [self updateTableView];
    }
}
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
-(void)pushViewOnStack:(id)object {
    int row = 3;
    if ([object isKindOfClass:[SnoozedViewController class]]) {
        row = 2;
    }
    SWRevealViewController *revealController = [self revealViewController];
    UINavigationController * sideMenuNav = (UINavigationController*) revealController.rearViewController;
    
    /* Remove delagtes */
    SideMenuViewController * sideMenu = [[sideMenuNav viewControllers] objectAtIndex:0];
    [sideMenu setPresentedRow:row andSection:0];
    UINavigationController * frontNav = (UINavigationController*)revealController.frontViewController;
    UIViewController * vc = [frontNav.viewControllers lastObject];
    [Utilities removeDelegatesForViewController:vc];
    
    NSArray* tempVCA = [(UINavigationController*) revealController.frontViewController viewControllers];
    /* remove last vc from stack */
    for(UIViewController *tempVC in tempVCA)
    {
        if([tempVC isKindOfClass:[InboxViewController class]]) {
            [tempVC removeFromParentViewController];
            break;
        }
    }
    
    /* push new vc */
    [revealController pushFrontViewController:[[UINavigationController alloc] initWithRootViewController:object] animated:YES];
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
#pragma - mark Private Methods
-(void)searchStringLocally:(NSString *)txt {
    if ([Utilities isValidString:txt]) {
        
        /* fetch 'x' unread emails */
        isSearching = YES;
        int indexToUpdate = 0;
        for (int i = 0; i< self.loginAcounts.count; ++i) {
            NSManagedObject * obj = [self.loginAcounts objectAtIndex:i];
            long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
            NSString * email = [obj valueForKey:kUSER_EMAIL];
            indexToUpdate = i;
            [self.allUserEmailsData replaceObjectAtIndex:indexToUpdate withObject:[self fetchUnreadEmailsWithLimit:20 offSet:0 isSearching:YES forString:txt userId:usrId userEmail:email]];
        }
        
        for (int i = 0; i< self.loginAcounts.count; ++i) {
            /* fetch 'x' users favorite emails */
            NSManagedObject * obj = [self.loginAcounts objectAtIndex:i];
            long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
            NSString * email = [obj valueForKey:kUSER_EMAIL];
            indexToUpdate+=1;
            [self.allUserEmailsData replaceObjectAtIndex:indexToUpdate withObject:[self fetchFavoriteEmailsWithLimit:20 offSet:0 isSearching:YES forString:txt userID:usrId userEmail:email]];
        }
        //        for (int i = 0; i< self.loginAcounts.count; ++i) {
        //            /* fetch 'x' users yesterday emails */
        //            NSManagedObject * obj = [self.loginAcounts objectAtIndex:i];
        //            long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        //            NSString * email = [obj valueForKey:kUSER_EMAIL];
        //            indexToUpdate+=1;
        //            [self.allUserEmailsData replaceObjectAtIndex:indexToUpdate withObject:[self fetchYesterdayEmailsWithLimit:20 offSet:0 isSearching:YES forString:txt andUserId:usrId email:email]];
        //        }
    }
    else {
        [self.allUserEmailsData removeAllObjects];
        [self fetchMailsFromDB];
    }
    [self.tableview reloadData];
}

- (void)refreshTableView {
    
    [self.allUserEmailsData removeAllObjects];
    [self fetchMailsFromDB];
    [self.tableview reloadData];
}


- (void)startContentSearch:(id)sender {
    //NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    //[self searchString:txt];
}
-(void)updateTableView {
    [self searchStringLocally:nil];
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
-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil userId:@"1" entity:kENTITY_EMAIL];
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        //[Utilities updateLastFetchCount:0];
        // [self showProgressHudWithTitle:kFETCHING_EMAILS];
    }
}
-(void)fetchUnreadEmails {
    [self refreshServices];
    
    //[self setActivityIndicatorViewConstant:30.0f];
    if (self.unreadFetchManagers != nil) {
        for (NSString* email in self.unreadFetchManagers) {
            UnreadFetchManager * unreadManager = [self.unreadFetchManagers objectForKey:email];
            if (unreadManager != nil) {
                if (!unreadManager.isFetchCallMade) {
                    if (unreadManager.imapSession == nil) {
                        NSLog(@"session was null");
                        [unreadManager createSessionForUser:unreadManager.user];
                    }
                    else if (unreadManager.messages == nil || unreadManager.messages.count == 0) {
                        NSLog(@"fetchAllUnread made");
                        [unreadManager fetchAllUnread];
                    }
                    
                    else {
                        NSLog(@"call made for fetchMoreEmails");
                        unreadManager.strFolderName = kFOLDER_INBOX;
                        unreadManager.folderType = kFolderInboxMail;
                        unreadManager.delegate = self;
                        [unreadManager fetchMoreEmails];
                    }
                }
            }
        }
    }
}
-(void)fetchResultsFromDbForString:(NSString *)text userId:(NSString *)userId entity:(NSString *)entity {
    if ([entity isEqualToString:kENTITY_EMAIL]) {
        isSearchingEmails = NO;
    }
    else {
        isSearchingEmails = YES;
    }
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        [self.fetchedResultsController setDelegate:self];
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedRegularEmailsForController:self.fetchedResultsController forUser:-1 isSearching:YES searchText:text fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:YES entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        //[self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    }
    else {
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedRegularEmailsForController:self.fetchedResultsController forUser:-1 isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:NO isSent:NO isInbox:YES isConversation:YES isTrash:NO isSnoozed:NO fetchReadOnly:YES entity:entity];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
    }
    [self.tableview reloadData];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}
- (void)updateSectionWithUserInfo:(NSNotification *)notification {
    NSString * strId = [notification.userInfo valueForKey:kUSER_ID];
    long longUserId = [strId longLongValue];
    
    for (int i = 0; i<self.allUserEmailsData.count; ++i) {
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:i];
        long userId = [[sectionArray objectAtIndex:6] longLongValue];
        NSString * email = [sectionArray objectAtIndex:5];
        NSString * tag = [sectionArray objectAtIndex:7];
        if ([tag isEqualToString:@"new"]) {
            if (userId == longUserId) {
                long limit = 2;
                NSMutableArray * limits = [tableViewLastSate objectForKey:strId];
                if (limits.count>0) {
                    limit = [[limits objectAtIndex:0] intValue];
                }
                [self.allUserEmailsData replaceObjectAtIndex:i withObject:[self fetchUnreadEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil userId:userId userEmail:email]];
                [Utilities reloadSection:i forTableView:self.tableview withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
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

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    
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
    //[self fetchResultsFromDbForString:self.txtSearchField.text];
    if (!isFetchingEmails) {
        if (isSearchingEmails) {
            [self fetchSearchEmails];
        }
        else {
            [self fetchEmails];
        }
    }
    if ([self.fetchedResultsController fetchedObjects].count>0) {
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
    if (searchHistoryView) {
        searchHistoryView.delegate = nil;
        searchHistoryView = nil;
    }
    
    [self contentFetcherWithBool:NO];
    //[self emailListnerDelegateWithBool:NO];
    if (self.inboxManagers != nil) {
        for (int i = 0; i<self.inboxManagers.count; ++i) {
            InboxManager * manager = [self.inboxManagers objectAtIndex:i];
            manager.delegate = nil;
            manager = nil;
        }
    }
    if (self.unreadFetchManagers != nil) {
        NSMutableArray * users = [CoreDataManager fetchAllUsers];
        for (NSManagedObject * userObject in users) {
            NSString * email = [userObject valueForKey:kUSER_EMAIL];
            UnreadFetchManager * manager = [self.unreadFetchManagers objectForKey:email];
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
    if (snoozeView) {
        snoozeView.delegate = nil;
    }
    if (datePickerView) {
        datePickerView.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_SNOOZE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_FAVORITE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_NEW_EMAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
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
    NSArray *visiblePaths = [self.tableview indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        if (indexPath.section>self.allUserEmailsData.count-1) {
            NSLog(@"Object from fetched controller");
            NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
            
            NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
            
            NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
            if (imgUrl == nil) {
                // Avoid the app icon download if the app already has an icon
                [self getUserProfileForEmail:[emailData valueForKey:kEMAIL_TITLE] object:emailData indexPath:path];
            }
            if (messagePreview == nil) {
                long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
                NSString * strUid = [Utilities getStringFromLong:usrId];
                NSString * messageId = [emailData valueForKey:kEMAIL_ID];
                NSString * folder = [emailData valueForKey:kMAIL_FOLDER];
                MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
                if (contentFetchManager != nil) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [contentFetchManager startFetchOpWithFolder:folder andMessageId:[messageId intValue] forNSManagedObject:emailData nsindexPath:path needHtml:NO];
                    });
                }
            }
        }
        else {
            NSLog(@"Object from MORE");
        }
    }
}
-(void)fetchMailsFromDB {
    
    if (self.allUserEmailsData == nil) {
        self.allUserEmailsData = [[NSMutableArray alloc] init];
    }
    /* get total users ids in userIds array */
    self.loginAcounts = [CoreDataManager fetchAllUsers];
    
    /* loop through all userIds */
    for (int x = 0; x < self.loginAcounts.count; ++x) {
        /* fetch 'x' users unread emails */
        NSManagedObject * obj = [self.loginAcounts objectAtIndex:x];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        int limit = 2;
        
        NSMutableArray * limits = [tableViewLastSate objectForKey:strUid];
        if (limits == nil) {
            NSMutableArray *state = [[NSMutableArray alloc] init];
            [state insertObject:[Utilities getStringFromInt:limit] atIndex:0];
            [tableViewLastSate setObject:state forKey:strUid];
        }
        else {
            if (limits.count>0) {
                limit = [[limits objectAtIndex:0] intValue];
            }
        }
        NSString * email = [obj valueForKey:kUSER_EMAIL];
        [self.allUserEmailsData addObject:[self fetchUnreadEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil userId:usrId userEmail:email]];
    }
    
    for (int x = 0; x < self.loginAcounts.count; ++x) {
        /* fetch 'x' users favorite emails*/
        NSManagedObject * obj = [self.loginAcounts objectAtIndex:x];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        int limit = 2;
        
        NSMutableArray * limits = [tableViewLastSate objectForKey:strUid];
        if (limits == nil) {
        }
        else {
            if (limits.count>1) {
                limit = [[limits objectAtIndex:1] intValue];
            }
            else {
                [limits insertObject:[Utilities getStringFromInt:limit] atIndex:1];
                [tableViewLastSate setObject:limits forKey:strUid];
            }
        }
        
        NSString * email = [obj valueForKey:kUSER_EMAIL];
        [self.allUserEmailsData addObject:[self fetchFavoriteEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil userID:usrId userEmail:email]];
    }
    
    //    for (int x = 0; x < self.loginAcounts.count; ++x) {
    //        /* fetch 'x' users yesterday emails */
    //        NSManagedObject * obj = [self.loginAcounts objectAtIndex:x];
    //        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
    //        NSString * strUid = [Utilities getStringFromLong:usrId];
    //        int limit = 2;
    //
    //        NSMutableArray * limits = [tableViewLastSate objectForKey:strUid];
    //        if (limits == nil) {
    //        }
    //        else {
    //            if (limits.count>2) {
    //                limit = [[limits objectAtIndex:2] intValue];
    //            }
    //            else {
    //                [limits insertObject:[Utilities getStringFromInt:limit] atIndex:2];
    //                [tableViewLastSate setObject:limits forKey:strUid];
    //            }
    //        }
    //
    //        NSString * email = [obj valueForKey:kUSER_EMAIL];
    //        [self.allUserEmailsData addObject:[self fetchYesterdayEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil andUserId:usrId email:email]];
    //    }
    NSLog(@"%@", tableViewLastSate);
    // }
    
}
-(NSArray *)fetchUnreadEmailsWithLimit:(long)fetchLimit offSet:(long)fetchOffSet isSearching:(BOOL)searching forString:(NSString *)string userId:(long)userID userEmail:(NSString *)email {
    
    long totalRowCount = 0;
    BOOL addMoreRow = NO;
    if (searching == NO) {
        totalRowCount = [CoreDataManager fetchUnreadCountForUserId:userID];
        
        if (totalRowCount>fetchLimit) {
            addMoreRow = YES;
            totalRowCount -=fetchLimit;
        }
    }
    NSMutableArray * unreadMails = [CoreDataManager fetchUnreadEmailsForUserId:userID fetchLimit:fetchLimit andFetchOffset:fetchOffSet isSearching:searching text:string];
    
    fetchOffSet = fetchLimit;
    
    NSArray * unreadEmailData = [[NSArray alloc] initWithObjects:
                                 [NSString stringWithFormat:@"%ld",totalRowCount],[NSNumber numberWithBool:addMoreRow],
                                 [NSString stringWithFormat:@"%ld",fetchOffSet],unreadMails,kUNREAD_MAIL,email,[NSString stringWithFormat:@"%ld",userID],
                                 @"new",nil];
    return unreadEmailData;
}
-(NSArray *)fetchFavoriteEmailsWithLimit:(long)fetchLimit offSet:(long)offset isSearching:(BOOL)searching forString:(NSString *)string userID:(long)useriD userEmail:(NSString *)email {
    long totalRowCount = 0;
    BOOL addMoreRow = NO;
    
    /* fetch 'x' favorite emails*/
    if (searching == NO) {
        totalRowCount  = [CoreDataManager fetchFavoriteCountUserId:useriD];
        
        if (totalRowCount>fetchLimit) {
            addMoreRow = YES;
            totalRowCount -=fetchLimit;
        }
    }
    NSMutableArray * fvrtMails = [CoreDataManager fetchFavoriteEmailsForUserId:useriD withFetchLimit:fetchLimit andFetchOffset:offset isSearching:searching searchingString:string];
    
    offset = fetchLimit;
    NSArray * favoriteEmailData = [[NSArray alloc] initWithObjects:
                                   [NSString stringWithFormat:@"%ld",totalRowCount],
                                   [NSNumber numberWithBool:addMoreRow],
                                   [NSString stringWithFormat:@"%ld",offset],
                                   fvrtMails,
                                   kFAVORITE_MAIL,email,[NSString stringWithFormat:@"%ld",useriD],@"fav", nil];
    return favoriteEmailData;
}

-(NSArray *)fetchYesterdayEmailsWithLimit:(long)fetchLimit offSet:(long)offset isSearching:(BOOL)searching forString:(NSString *)string andUserId:(long)userID email:(NSString *)email {
    long totalRowCount = 0;
    BOOL addMoreRow = NO;
    
    NSDate *yesterdayDate = [[NSDate date] dateByAddingTimeInterval:-((24*60*60)*1)];
    NSDate * startDate = [Utilities resetTimeForGivenDate:yesterdayDate hours:0 minutes:0 seconds:0];
    
    NSDate * endDate = [Utilities resetTimeForGivenDate:yesterdayDate hours:23 minutes:59 seconds:59];
    if (searching == NO) {
        totalRowCount = [CoreDataManager fetchEmailsCountForGivenStartDate:startDate endDate:endDate andUserId:userID];
        if (totalRowCount>fetchLimit) {
            addMoreRow = YES;
            totalRowCount -=fetchLimit;
        }
    }
    NSMutableArray * yesterdayMails = [CoreDataManager fetchEmailsForGivenStartDate:startDate endDate:endDate andUserId:userID ithFetchLimit:fetchLimit andFetchOffset:offset isSearching:searching text:string];
    
    offset = fetchLimit;
    NSArray * yesterdayEmailData = [[NSArray alloc] initWithObjects:
                                    [NSString stringWithFormat:@"%ld",totalRowCount],
                                    [NSNumber numberWithBool:addMoreRow],
                                    [NSString stringWithFormat:@"%ld",offset],
                                    yesterdayMails,
                                    kYESTERDAY_MAIL,
                                    email,
                                    [NSString stringWithFormat:@"%ld",userID,@"yester"],
                                    nil];
    return yesterdayEmailData;
}

-(void)updateFavoriteEmailSectionForIndexPath:(NSIndexPath *)indexPath email:(NSString *)email {
    /* remove more cell first */
    BOOL addMoreRow = NO;
    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    long offset = [[sectionArray objectAtIndex:2] longLongValue];
    long moreRowCount = [[sectionArray objectAtIndex:0] longLongValue];
    NSMutableArray * emailsArray = [sectionArray objectAtIndex:3];
    NSString * userId = [sectionArray objectAtIndex:6];
    NSString * tag = [sectionArray objectAtIndex:7];
    NSArray * favoriteEmailData = [[NSArray alloc] initWithObjects:
                                   [NSString stringWithFormat:@"%ld",moreRowCount],
                                   [NSNumber numberWithBool:addMoreRow],
                                   [NSString stringWithFormat:@"%ld",offset],
                                   emailsArray,
                                   kFAVORITE_MAIL,email,userId,
                                   tag,
                                   nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:favoriteEmailData];
    
    NSInteger totalRowsInSection = [self.tableview numberOfRowsInSection:indexPath.section];
    if (indexPath.row<=totalRowsInSection-1) {
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [Utilities removeTableViewRows:self.tableview forIndexArray:indexArray withAnimation:UITableViewRowAnimationBottom];
    }
    /* here calclulate next fetch count
     if favorite more rows are greater than 10, make addMoreRow falg true
     an specify fetch limit 10
     */
    long fetchLimit = moreRowCount;
    if (moreRowCount>fixedFetchLimit) {
        addMoreRow = YES;
        fetchLimit = fixedFetchLimit;
    }
    
    /* fetch new record from db as calculated above */
    [emailsArray addObjectsFromArray:[CoreDataManager fetchFavoriteEmailsForUserId:[userId longLongValue] withFetchLimit:fetchLimit andFetchOffset:offset isSearching:NO searchingString:nil]];
    /* update last favoriteOffset with adding new fetch limit */
    offset += fetchLimit;
    NSMutableArray * limits = [tableViewLastSate objectForKey:userId];
    [limits replaceObjectAtIndex:1 withObject:[Utilities getStringFromLong:offset]];
    [tableViewLastSate setObject:limits forKey:userId];
    /* decrement favorite more row count */
    moreRowCount -= fetchLimit;
    
    favoriteEmailData = [[NSArray alloc] initWithObjects:
                         [NSString stringWithFormat:@"%ld",moreRowCount],
                         [NSNumber numberWithBool:addMoreRow],
                         [NSString stringWithFormat:@"%ld",offset],
                         emailsArray,
                         kFAVORITE_MAIL,email,userId,@"fav",
                         nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:favoriteEmailData];
    
    /* update table view with inserting new cells */
    [Utilities insertTableViewRows:self.tableview forIndexArray:[NSArray arrayWithArray:[self insertIndexPath:indexPath forInsertingNumberOfRows:offset withMoreCellInsertionFlag:addMoreRow]] withAnimation:UITableViewRowAnimationTop];
}
-(void)updateNewEmailSectionForIndexPath:(NSIndexPath *)indexPath email:(NSString *)email {
    /* remove more cell first */
    BOOL addMoreRow = NO;
    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    long offset = [[sectionArray objectAtIndex:2] longLongValue];
    long moreRow = [[sectionArray objectAtIndex:0] longLongValue];
    NSMutableArray * emailsArray = [sectionArray objectAtIndex:3];
    NSString * userId = [sectionArray objectAtIndex:6];
    NSString * tag = [sectionArray objectAtIndex:7];
    NSArray * unreadEmailData = [[NSArray alloc] initWithObjects:
                                 [NSString stringWithFormat:@"%ld",moreRow],
                                 [NSNumber numberWithBool:addMoreRow],
                                 [NSString stringWithFormat:@"%ld",offset],
                                 emailsArray,
                                 kUNREAD_MAIL,email,userId,tag,
                                 nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:unreadEmailData];
    
    NSInteger totalRowsInSection = [self.tableview numberOfRowsInSection:indexPath.section];
    if (indexPath.row<=totalRowsInSection-1) {
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [Utilities removeTableViewRows:self.tableview forIndexArray:indexArray withAnimation:UITableViewRowAnimationBottom];
    }
    /* here calclulate next fetch count
     if favorite more rows are greater than 10, make addMoreRow falg true
     and specify fetch limit 10
     */
    long fetchLimit = moreRow;
    if (moreRow>fixedFetchLimit) {
        addMoreRow = YES;
        fetchLimit = fixedFetchLimit;
    }
    
    /* fetch new record from db as calculated above */
    
    [emailsArray addObjectsFromArray:[CoreDataManager fetchUnreadEmailsForUserId:[userId longLongValue] fetchLimit:fetchLimit andFetchOffset:offset isSearching:NO text:nil]];
    
    /* decrement new more row count */
    moreRow -= emailsArray.count - offset;
    /* update last newOffset with adding new fetch limit */
    offset = emailsArray.count;
    
    NSMutableArray * limits = [tableViewLastSate objectForKey:userId];
    [limits replaceObjectAtIndex:0 withObject:[Utilities getStringFromLong:offset]];
    [tableViewLastSate setObject:limits forKey:userId];
    
    unreadEmailData = [[NSArray alloc] initWithObjects:
                       [NSString stringWithFormat:@"%ld",moreRow],
                       [NSNumber numberWithBool:addMoreRow],
                       [NSString stringWithFormat:@"%ld",offset],
                       emailsArray,
                       kUNREAD_MAIL,
                       email,userId,@"new",
                       nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:unreadEmailData];
    [Utilities insertTableViewRows:self.tableview forIndexArray:[NSArray arrayWithArray:[self insertIndexPath:indexPath forInsertingNumberOfRows:offset withMoreCellInsertionFlag:addMoreRow]] withAnimation:UITableViewRowAnimationTop];
    
}
-(void)updateYesterdayEmailSectionForIndexPath:(NSIndexPath *)indexPath email:(NSString *)email {
    /* remove more cell first */
    BOOL addMoreRow = NO;
    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    long offset = [[sectionArray objectAtIndex:2] longLongValue];
    long moreRowCount = [[sectionArray objectAtIndex:0] longLongValue];
    NSMutableArray * emailsArray = [sectionArray objectAtIndex:3];
    NSString * userId = [sectionArray objectAtIndex:6];
    
    NSArray * yesterdayEmailData = [[NSArray alloc] initWithObjects:
                                    [NSString stringWithFormat:@"%ld",moreRowCount],
                                    [NSNumber numberWithBool:addMoreRow],
                                    [NSString stringWithFormat:@"%ld",offset],
                                    emailsArray,
                                    kYESTERDAY_MAIL,email,userId,@"yester",
                                    nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:yesterdayEmailData];
    
    NSInteger totalRowsInSection = [self.tableview numberOfRowsInSection:indexPath.section];
    if (indexPath.row<=totalRowsInSection-1) {
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [Utilities removeTableViewRows:self.tableview forIndexArray:indexArray withAnimation:UITableViewRowAnimationBottom];
    }
    
    /* here calclulate next fetch count
     if favorite more rows are greater than 10, make addMoreRow falg true
     an specify fetch limit 10
     */
    long fetchLimit = moreRowCount;
    if (moreRowCount>fixedFetchLimit) {
        addMoreRow = YES;
        fetchLimit = fixedFetchLimit;
    }
    NSDate *yesterdayDate = [[NSDate date] dateByAddingTimeInterval:-((24*60*60)*1)];
    NSDate * startDate = [Utilities resetTimeForGivenDate:yesterdayDate hours:0 minutes:0 seconds:0];
    
    NSDate * endDate = [Utilities resetTimeForGivenDate:yesterdayDate hours:23 minutes:59 seconds:59];
    
    
    /* fetch new record from db as calculated above */
    [emailsArray addObjectsFromArray:[CoreDataManager fetchEmailsForGivenStartDate:startDate endDate:endDate andUserId:[userId longLongValue] ithFetchLimit:fetchLimit andFetchOffset:offset isSearching:NO text:nil]];
    
    /* update last yesterdayOffset with adding new fetch limit */
    offset += fetchLimit;
    
    NSMutableArray * limits = [tableViewLastSate objectForKey:userId];
    [limits replaceObjectAtIndex:2 withObject:[Utilities getStringFromLong:offset]];
    [tableViewLastSate setObject:limits forKey:userId];
    
    
    /* decrement yesterday more row count */
    moreRowCount -= fetchLimit;
    
    yesterdayEmailData = [[NSArray alloc] initWithObjects:
                          [NSString stringWithFormat:@"%ld",moreRowCount],
                          [NSNumber numberWithBool:addMoreRow],
                          [NSString stringWithFormat:@"%ld",offset],
                          emailsArray,
                          kYESTERDAY_MAIL,email,userId,@"yester",
                          nil];
    [self.allUserEmailsData replaceObjectAtIndex:indexPath.section withObject:yesterdayEmailData];
    
    
    /* update table view with inserting new cells */
    [Utilities insertTableViewRows:self.tableview forIndexArray:[NSArray arrayWithArray:[self insertIndexPath:indexPath forInsertingNumberOfRows:offset withMoreCellInsertionFlag:addMoreRow]] withAnimation:UITableViewRowAnimationTop];
}

-(NSMutableArray *)insertIndexPath:(NSIndexPath *)indexPath forInsertingNumberOfRows:(long)rows withMoreCellInsertionFlag:(BOOL)addMoreCell {
    /* add index paths in array to insert new cells in tableview */
    NSMutableArray * cellArray = [[NSMutableArray alloc] init];
    for (int x = (int)indexPath.row; x < rows; ++x) {
        NSIndexPath *moreRow = [NSIndexPath indexPathForRow:x inSection:indexPath.section];
        [cellArray addObject:moreRow];
    }
    
    /* add an extra cell if flag is true for More(x) button cell */
    if (addMoreCell) {
        [cellArray addObject:[NSIndexPath indexPathForRow:rows inSection:indexPath.section]];
    }
    return cellArray;
}


-(void)setUpView {
    [self setActivityIndicatorViewConstant:0.0f];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchUnreadEmails) name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshServices)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView) name:kNSNOTIFICATIONCENTER_SNOOZE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView) name:kNSNOTIFICATIONCENTER_FAVORITE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSectionWithUserInfo:) name:kNSNOTIFICATIONCENTER_NEW_EMAIL object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:kNSNOTIFICATIONCENTER_LOGOUT object:nil];
    //[self emailListnerDelegateWithBool:YES];
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.tableview setBackgroundView:nil];
    [self.tableview setBackgroundColor:[UIColor clearColor]];
    //SWRevealViewController *revealController = [self revealViewController];
    
    //[self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
    self.title = @"Smart Inbox";
    
    UIBarButtonItem * btnNavClock=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_clock"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(btnNavSnoozeAction:)];
    
    UIBarButtonItem * btnNavDrawer=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_drawer"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavArchiveAction:)];
    UIBarButtonItem * btnNavSearch=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavSearchAction:)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnNavSearch,btnNavDrawer,btnNavClock, nil ];
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[self revealViewController]
                                                             action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    
    if ([self.txtSearchField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor colorWithRed:127.0f/255.0f green:128.0f/255.0f blue:133.0f/255.0f alpha:1.0f];
        self.txtSearchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: color}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
        // TODO: Add fall-back code to set placeholder color.
    }
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}
-(void)emailListnerDelegateWithBool:(BOOL)setListner {
    NSMutableArray * allUsers = [CoreDataManager fetchAllUsers];
    NSMutableDictionary * listnersDictionary = [[SharedInstanceManager sharedInstance] sharedEmailListners];
    for (NSManagedObject * obj in allUsers) {
        long intId = [[obj valueForKey:kUSER_ID] integerValue];
        NSLog(@"id = %ld",intId);
        EmailListenerManager * manager = [listnersDictionary objectForKey:[NSString stringWithFormat:@"%ld",intId]];
        if (manager != nil) {
            if (setListner) {
                manager.delegate = self;
            }
            else {
                manager.delegate = nil;
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
            MCOIMAPFetchContentOperationManager * contentFetchManager = [[MCOIMAPFetchContentOperationManager alloc] init];
            contentFetchManager.delegate = self;
            [contentFetchManager createFetcherWithUserId:strId];
            [contentFetcherDictionary setObject:contentFetchManager forKey:strId];
        }
        else {
            MCOIMAPFetchContentOperationManager * contentFetchManager = [contentFetcherDictionary objectForKey:strId];
            if (contentFetchManager != nil) {
                contentFetchManager.delegate = nil;
                [contentFetcherDictionary removeObjectForKey:strId];
                contentFetchManager = nil;
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
        
        NSManagedObject * object = nil;
        if (self.swipeIndexPath.section<=self.allUserEmailsData.count-1) {
            NSArray * dataArray = [self.allUserEmailsData objectAtIndex:self.swipeIndexPath.section];
            NSMutableArray * emailArray = [dataArray objectAtIndex:3];
            object = [emailArray objectAtIndex:self.swipeIndexPath.row];
        }
        else {
            NSIndexPath * path = [NSIndexPath indexPathForRow:self.swipeIndexPath.row inSection:0];
            object = [self.fetchedResultsController objectAtIndexPath:path];
        }
        snoozeObject = object;
        long intId = [[object valueForKey:kUSER_ID] integerValue];
        NSString * userId = [NSString stringWithFormat:@"%ld",intId];
        NSString * email = [Utilities getEmailForId:userId];
        if([Utilities isValidString:email]) {
            NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:email]];
            
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
}
-(void)onLongPress:(UILongPressGestureRecognizer*)pGesture {
    if (pGesture.state == UIGestureRecognizerStateRecognized) {
        //Do something to tell the user!
    }
    if (pGesture.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"Handle the long press on row");
        UITableView* tableView = self.tableview;
        CGPoint touchPoint = [pGesture locationInView:self.view];
        NSIndexPath* indexPath = [tableView indexPathForRowAtPoint:touchPoint];
        if (indexPath != nil) {
            [self showSubView];
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
            
            //            NSInteger totalRowsInSection = [self.tableview numberOfRowsInSection:indexPath.section];
            //            if (indexPath.row<=totalRowsInSection-1) {
            //                NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
            //                [Utilities reloadTableViewRows:self.tableview forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
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
-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
-(void)syncDeleteActionToFirebaseWithObject:(NSManagedObject *)object userId:(NSString *)userId {
    NSString * firebaseFavoriteId = [object valueForKey:kFAVORITE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseFavoriteId]) {
        [Utilities syncToFirebase:nil syncType:[FavoriteEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kFAVORITE_FIREBASE_ID]];
    }
    
    NSString * firebaseSnoozedId = [object valueForKey:kSNOOZED_FIREBASE_ID];
    if ([Utilities isValidString:firebaseSnoozedId]) {
        [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:userId performAction:kActionDelete firebaseId:[object valueForKey:kSNOOZED_FIREBASE_ID]];
    }
}
-(void)btnSwipeMarkMessageAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    [self setActivityIndicatorViewConstant:30.0f];
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
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
-(void)markMessageLocally:(NSMutableArray *)array markCount:(int)markCount {
    for (NSManagedObject * obj in array) {
        [obj setValue:[NSNumber numberWithLong:markCount] forKey:kUNREAD_COUNT];
        [CoreDataManager updateData];
    }
    [self updateTableView];
}
-(void)markMessageOnServer:(NSMutableDictionary *)undoDictionary {
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
    [self updateTableView];
}
-(void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
    [self setActivityIndicatorViewConstant:30.0f];
    long intId = [[object valueForKey:kUSER_ID] integerValue];
    NSString * userId = [NSString stringWithFormat:@"%ld",intId];
    
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId: [userId longLongValue] folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
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
    [self updateTableView];
}

-(void)markSnoozeActionAtIndexPath:(NSIndexPath *)indexPath {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
    
    [self setActivityIndicatorViewConstant:30.0f];
    //NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
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


-(void)markDeleteMessageLocally:(NSMutableArray*)messages flag:(BOOL)flag {
    for (NSManagedObject * object in messages) {
        [object setValue:[NSNumber numberWithBool:flag] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
    }
}
-(void)markDeleteOnServer:(NSMutableArray*)messages{
    for (NSManagedObject * obj in messages) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_TRASH_EMAIL];
        [CoreDataManager updateData];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        NSString * entity = [obj entity].name;
        if (imapSession != nil) {
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:kFOLDER_TRASH_MAILS completionBlock:^(id response) {
                
                NSIndexSet * ind = indexSet.nsIndexSet;
                uint64_t emailUid = ind.firstIndex;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:emailUid userId:usrId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [self syncDeleteActionToFirebaseWithObject:object userId:strUid];
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
                [self updateTableView];
            }];
        }
    }
    [self updateTableView];
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
-(void)btnSwipeArchiveActionAtIndexPath:(NSIndexPath *)indexPath {
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
    
    long intId = [[object valueForKey:kUSER_ID] integerValue];
    NSString * userId = [NSString stringWithFormat:@"%ld",intId];
    NSEntityDescription * des = [object entity];
    NSString * strThreadId = [object valueForKey:kEMAIL_THREAD_ID];
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId: [userId longLongValue] folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:des.name];
    
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
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:userId];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailExist:[userId longLongValue] emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:userId markArchive:NO threadId:[strThreadId longLongValue] entity:des.name];
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
                        [self updateTableView];
                        [self showAlertWithTitle:@"Cannot Archive Email!" andMessage:[NSString stringWithFormat:@"Please try again."] withDelegate:nil];
                    }];
                }
            }
        }
    }
    [self updateTableView];
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}
-(void)markArchiveMessageLocally:(NSMutableArray*)messages {
    for (NSManagedObject * objc in messages) {
        [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
        [CoreDataManager updateData];
    }
}
-(void)markArchiveOnServer:(NSMutableArray*)messages {
    
    for (NSManagedObject * obj in messages) {
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        uint64_t longThreadId = [[obj valueForKey:kEMAIL_THREAD_ID] longLongValue];
        NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
        
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[strThreadId longLongValue] entity:[obj entity].name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:usrId];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        if (response != nil) {
                            for (NSManagedObject * object in messages) {
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
                        for (NSManagedObject * objc in messages) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
                            [CoreDataManager updateData];
                        }
                        [self updateTableView];
                        [self showAlertWithTitle:@"Cannot Archive Email!" andMessage:[NSString stringWithFormat:@"Please try again."] withDelegate:nil];
                    }];
                }
            }
        }
    }
    [self updateTableView];
}

-(void)markArchiveOnServerWithoutDeletingSnooze:(NSMutableArray*)messages {
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
                        
                        for (NSManagedObject * object in messages) {
                            //[CoreDataManager deleteObject:object];
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


-(void)btnSwipeFavoriteActionAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
    
    long intId = [[object valueForKey:kUSER_ID] integerValue];
    NSString * userId = [NSString stringWithFormat:@"%ld",intId];
    
    if ([[object valueForKey:kIS_FAVORITE] boolValue]) {
        //[self showToastWithMessage:@"✰✰ Already Marked Favorite ✰✰"];
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
        NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:intId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:[object entity].name];
        NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
        [undoDictionary setObject:@"mark_favorite" forKey:@"actiontype"];
        [undoDictionary setObject:emailIdArray forKey:@"messages"];
        [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
        [self.undoArray addObject:undoDictionary];
        
        NSString * email = [Utilities getEmailForId:userId];
        if([Utilities isValidString:email]) {
            NSMutableDictionary * dictionary = [Utilities getDictionaryFromObject:object email:email isThread:YES dictionaryType:kTypeFavorite nsdate:0];
            [Utilities syncToFirebase:dictionary syncType:[FavoriteEmailSyncManager class] userId:userId performAction:kActionInsert firebaseId:nil];
        }
        self.lblUndo.text = @"Favorite marked";
        [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    }
}
-(void)fetchEmails {
    [self showProgressHudWithTitle:kFETCHING_EMAILS];
    for (InboxManager * inManager in self.inboxManagers) {
        inManager.totalNumberOfMessagesInDB = [Utilities getInboxLastFetchCount:inManager.userId];
        isFetchingEmails = YES;
        inManager.strFolderName = kFOLDER_INBOX;
        inManager.folderType = kFolderInboxMail;
        inManager.entityName = kENTITY_EMAIL;
        [inManager loadLastNMessages:kNUMBER_OF_MESSAGES_TO_LOAD];
        inManager.delegate = self;
    }
}

-(MoreButtonTableViewCell *)configureBtnMoreCell:(MoreButtonTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withRemainingItems:(long)items {
    
    if (cell == nil) {
        NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"MoreButtonTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString * btnMoreTitle = [NSString stringWithFormat:@"More (%ld)",items];
    cell.btnMore.tag = indexPath.row;
    [cell.btnMore setTitle:btnMoreTitle forState:UIControlStateNormal];
    [cell.btnMore addTarget:self action:@selector(btnMoreAction:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}
-(SmartInboxTableViewCell *)configureCell:(SmartInboxTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *emailData = nil;
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SmartInboxTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    NSMutableArray * emailArray = [dataArray objectAtIndex:3];
    emailData = [emailArray objectAtIndex:indexPath.row];
    
    long intId = [[emailData valueForKey:kUSER_ID] integerValue];
    NSString * strId = [NSString stringWithFormat:@"%ld",intId];
    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
    if (imgUrl != nil && ![imgUrl isEqualToString:kNOT_FOUND]) {
        [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    }
    else {
        cell.imgProfile.image = [UIImage imageNamed:@"profile_image_placeholder"];
    }
    
    MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strId];
    cell = [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:contentFetchManager view:self.view atIndexPath:indexPath isSent:NO];
    
    cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_ARHIEVE, kIMAGE_SWIPE_CELL_SNOOZE, kIMAGE_SWIPE_CELL_FAVOURITE);
    cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_ARCHIVE, kCOLOR_SWIPE_CELL_SNOOZE, kCOLOR_SWIPE_CELL_FAVOURITE);
    
    cell.delegate = self;
    //cell.allowsOppositeSwipe = NO;
    //cell.allowsMultipleSwipe = YES;
    
    return  cell;
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
-(void)hideUndoBar {
    NSLog(@"hide");
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
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
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_favorite"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    for (NSManagedObject * object in messages) {
                        [self syncDeleteActionToFirebaseWithObject:object];
                    }
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
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_archive"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markArchiveMessageLocally:messages];
                    [self.undoArray removeObject:dic];
                }
                else if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_delete"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    [self markDeleteMessageLocally:messages flag:NO];
                    [self.undoArray removeObject:dic];
                }
                
                [self refreshTableView];
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

#pragma - mark User Actions
-(IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}
-(IBAction)btnMoreAction:(id)sender {
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableview];
    NSIndexPath *indexPath = [self.tableview indexPathForRowAtPoint:touchPoint];
    
    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    NSString * emailsType = [sectionArray objectAtIndex:4];
    NSString * email = [sectionArray objectAtIndex:5];
    
    if ([emailsType isEqualToString:kUNREAD_MAIL]) {
        if ([Utilities isInternetActive]) {
            //[self setActivityIndicatorViewConstant:30.0f];
            if (self.unreadFetchManagers != nil) {
                UnreadFetchManager * unreadManager = [self.unreadFetchManagers objectForKey:email];
                if (!unreadManager.isFetchCallMade) {
                    unreadManager.strFolderName = kFOLDER_INBOX;
                    unreadManager.folderType = kFolderInboxMail;
                    unreadManager.delegate = self;
                    [unreadManager fetchMoreEmails];
                }
            }
        }
        [self updateNewEmailSectionForIndexPath:indexPath email:email];
    }
    else if ([emailsType isEqualToString:kFAVORITE_MAIL]) {
        [self updateFavoriteEmailSectionForIndexPath:indexPath email:email];
    }
    else if ([emailsType isEqualToString:kYESTERDAY_MAIL]) {
        [self updateYesterdayEmailSectionForIndexPath:indexPath email:email];
    }
}
-(IBAction)btnNavSnoozeAction:(id)sender {
    SnoozedViewController *snoozedViewController = [[SnoozedViewController alloc] init];
    [self pushViewOnStack:snoozedViewController];
}
-(IBAction)btnNavArchiveAction:(id)sender {
    ArchiveViewController *archiveViewController = [[ArchiveViewController alloc] init];
    [self pushViewOnStack:archiveViewController];
}

-(IBAction)btnAddAction:(id)sender {
    [self.view endEditing:YES];
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @"Compose";
    emailComposerViewController.isDraft = NO;
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}
-(IBAction)btnHeaderAction:(id)sender {
    UIButton * btnHeader = (UIButton *)sender;
    NSString * nextControllerNavTtile = nil;
    
    if (btnHeader.tag == 0) {
        nextControllerNavTtile = @"john_doe@gmail.com";
    }
    else if (btnHeader.tag == 1) {
        nextControllerNavTtile = @"arla_desilva@gmail.com";
    }
    else {
        nextControllerNavTtile = @"";
    }
    MailThreadViewController * mailThreadViewController = [[MailThreadViewController alloc] initWithNibName:@"MailThreadViewController" bundle:nil];
    mailThreadViewController.navigationBarTitle = nextControllerNavTtile;
    [self.navigationController pushViewController:mailThreadViewController animated:YES];
}
-(IBAction)btnNavSearchAction:(id)sender {
    UIBarButtonItem * btn = (UIBarButtonItem *)sender;
    float delay = 0;
    if([snoozeView isDescendantOfView:self.view]) {
        [snoozeView removeFromSuperview];
    }
    if (heightSearchBar.constant == 43.0) {
        [self.allUserEmailsData removeAllObjects];
        [self fetchMailsFromDB];
        heightSearchBar.constant = 0.0f;
        self.txtSearchField.text = @"";
        [self fetchResultsFromDbForString:nil userId:@"" entity:kENTITY_EMAIL];
        [btn setImage:[UIImage imageNamed:@"menu_search"]];
        [self hideHistoryView];
    }
    else {
        [self.allUserEmailsData removeAllObjects];
        heightSearchBar.constant = 43.0f;
        delay = 0.25f;
        self.fetchedResultsController.fetchRequest.predicate =
        [NSPredicate predicateWithValue:NO];
        [self.fetchedResultsController performFetch:nil];
        self.fetchedResultsController.delegate = nil;
        [btn setImage:[UIImage imageNamed:@"btn_cross"]];
        [self fetchResultsFromDbForString:nil userId:@"" entity:kENTITY_SEARCH_EMAIL];
        [self showHistoryView];
    }
    
    [self.view.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view.superview layoutIfNeeded];
    }];
    
    
    /*if([snoozeView isDescendantOfView:self.view]) {
     [snoozeView removeFromSuperview];
     }
     
     if (heightSearchBar.constant == 43.0) {
     heightSearchBar.constant = 0.0f;
     //[self.view endEditing:YES];
     self.txtSearchField.text = @"";
     [self searchString:nil];
     }
     else {
     heightSearchBar.constant = 43.0f;
     ///[self.txtSearchField becomeFirstResponder];
     }
     [self.view setNeedsUpdateConstraints];
     
     [UIView animateWithDuration:0.25f animations:^{
     [self.view layoutIfNeeded];
     }];*/
}
-(IBAction)btnSideMenuAction:(id)sender {
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
    
    //    NSManagedObject * selectedMailData = nil;
    //    if (self.swipeIndexPath.section<=self.allUserEmailsData.count-1) {
    //        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:self.swipeIndexPath.section];
    //        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
    //        selectedMailData = [emailArray objectAtIndex:self.swipeIndexPath.row];
    //    }
    //    else {
    //        NSIndexPath * path = [NSIndexPath indexPathForRow:self.swipeIndexPath.row inSection:0];
    //        selectedMailData = [self.fetchedResultsController objectAtIndexPath:path];
    //    }
    
    if (snoozeObject == nil) {
        return;
    }
    long intId = [[snoozeObject valueForKey:kUSER_ID] integerValue];
    NSString * userId = [NSString stringWithFormat:@"%ld",intId];
    NSString * email = [Utilities getEmailForId:userId];
    if (![Utilities isValidString:email]) {
        return;
    }
    if ([Utilities isValidString:email]) {
        
        int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
        BOOL isDeafult = NO;
        if (value == 1) {
            isDeafult = YES;
        }
        
        NSMutableArray * array = [CoreDataManager fetchActiveSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:email]];
        NSManagedObject * object = [array objectAtIndex:Index];
        int preferenceId = [[object valueForKey:kPREFERENCE_ID] intValue];
        int hour = [[object valueForKey:kSNOOZE_HOUR_COUNT] intValue];
        int minutes = [[object valueForKey:kSNOOZE_MINUTE_COUNT] intValue];
        
        if(preferenceId == 9) { /* open picker */
            [self openPickerViewForIndex:5];
            return;
        }
        [Utilities calculateDateWithHours:hour minutes:minutes preferenceId:preferenceId currentEmail:email userId:userId emailData:snoozeObject onlyIfNoReply:snoozedOnlyIfNoReply viewType:[view getTableViewType]];
        
        [self markSnoozeActionAtIndexPath:self.swipeIndexPath];
    }
}

#pragma - mark DatePickerViewDelegate
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    if (snoozeObject == nil) {
        return;
    }
    
    long intId = [[snoozeObject valueForKey:kUSER_ID] integerValue];
    NSString * userId = [NSString stringWithFormat:@"%ld",intId];
    NSString * email = [Utilities getEmailForId:userId];
    if (![Utilities isValidString:email]) {
        return;
    }
    [Utilities setEmailToSnoozeTill:date withObject:snoozeObject currentEmail:email onlyIfNoReply:snoozedOnlyIfNoReply userId:userId];
    
}
- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section>self.allUserEmailsData.count-1 || isSearchingEmails) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
        
        return [sectionInfo numberOfObjects];
    }
    else {
        
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:section];
        BOOL addMoreRow = [[sectionArray objectAtIndex:1] boolValue];
        NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
        
        if (addMoreRow) {
            return emailsData.count+1;
        }
        
        NSLog(@"Section : %lu Size : %lu ", (unsigned long) section, (unsigned long) emailsData.count);
        
        return emailsData.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section>self.allUserEmailsData.count-1 || isSearchingEmails) {
        static NSString *tableIdentifier = @"SmartInboxCell";
        SmartInboxTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SmartInboxTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        
        NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
        
        if (imgUrl != nil && ![imgUrl isEqualToString:kNOT_FOUND]) {
            [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
        }
        else {
            cell.imgProfile.image = [UIImage imageNamed:@"profile_image_placeholder"];
        }
        
        cell = [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:nil view:self.view atIndexPath:indexPath isSent:NO];
        
        cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_ARHIEVE, kIMAGE_SWIPE_CELL_SNOOZE, kIMAGE_SWIPE_CELL_FAVOURITE);
        cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_ARCHIVE, kCOLOR_SWIPE_CELL_SNOOZE, kCOLOR_SWIPE_CELL_FAVOURITE);
        
        cell.delegate = self;
        //cell.allowsOppositeSwipe = NO;
        //cell.allowsMultipleSwipe = YES;
        
        return  cell;
    }
    else {
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        long moreRowCount = [[sectionArray objectAtIndex:0] longLongValue];
        BOOL addMoreRow = [[sectionArray objectAtIndex:1] boolValue];
        NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
        
        if (addMoreRow && indexPath.row >= emailsData.count && moreRowCount>0) {
            static NSString *tableIdentifier = @"MoreButtonCell";
            MoreButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
            return  [self configureBtnMoreCell:cell atIndexPath:indexPath withRemainingItems:moreRowCount];
        }
        else {
            static NSString *tableIdentifier = @"SmartInboxCell";
            SmartInboxTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
            return [self configureCell:cell atIndexPath:indexPath];
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section>self.allUserEmailsData.count-1 || isSearchingEmails) {
        
    }
    else {
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        long moreRowCount = [[sectionArray objectAtIndex:0] longLongValue];
        BOOL addMoreRow = [[sectionArray objectAtIndex:1] boolValue];
        NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
        
        if (addMoreRow && indexPath.row >= emailsData.count && moreRowCount>0) {
            return 32.0f;
        }
        else {
            return 97.0f;
        }
    }
    return 97.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    /* +1 for inbox emails */
    return self.allUserEmailsData.count+1;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString * email = @"";
    NSString * headerTitle = @"";
    if (section>self.allUserEmailsData.count-1 || isSearchingEmails) {
        headerTitle = @"Inbox";
    }
    else {
        NSArray * array = [self.allUserEmailsData objectAtIndex:section];
        
        email = [array objectAtIndex:5];
        headerTitle = [array objectAtIndex:4];
        
        if ([headerTitle isEqualToString:kUNREAD_MAIL]) {
            headerTitle = @"New";
        }
        else if([headerTitle isEqualToString:kFAVORITE_MAIL]) {
            headerTitle = @"Favorite";
        }
        else if([headerTitle isEqualToString:kYESTERDAY_MAIL])   {
            headerTitle = @"Yesterday";
        }
    }
    static NSString *tableIdentifier = @"InboxSectionHeader";
    
    InboxHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"InboxHeaderTableViewCell" owner:self options:nil];
        cell      = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.lbHeaderlEmail.text = email;
    cell.lbHeaderlTitle.text = headerTitle;
    cell.btnHeader.tag = section;
    //[cell.btnHeader addTarget:self action:@selector(btnHeaderAction:) forControlEvents:UIControlEventTouchUpInside];
    return  cell.contentView;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (isSearchingEmails) {
        return 0.0f;
    }
    if (section>self.allUserEmailsData.count-1) {
        
    }
    else {
        
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:section];
        NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
        if (emailsData.count<=0) {
            return 0.0f;
        }
    }
    return 29.0f;
}
#pragma - mark UITableView Delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    startTableViewUpdate = NO;
    didSelectIndexPath = indexPath;
    
    if (indexPath.section>self.allUserEmailsData.count-1 || isSearchingEmails) {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        [CellConfigureManager didTapOnEmail:emailData folderType:kFolderInboxMail];
        return;
    }
    
    NSManagedObject *emailData;
    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
    if (indexPath.row>= emailsData.count) {
        return;
    }
    emailData = [emailsData objectAtIndex:indexPath.row];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderInboxMail];
}


#pragma mark MGSwipeTableCellDelegate

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction;
{
    return YES;
}

-(NSArray*)swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
            swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    
    __weak typeof(self) weakSelf = self;
    NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:cell];
    NSManagedObject * object = nil;
    if (indexPath.section<=self.allUserEmailsData.count-1) {
        NSArray * dataArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
        NSMutableArray * emailArray = [dataArray objectAtIndex:3];
        object = [emailArray objectAtIndex:indexPath.row];
    }
    else {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        object = [self.fetchedResultsController objectAtIndexPath:path];
    }
    NSString * folder = [object valueForKey:kMAIL_FOLDER];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[object valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder] entity:[object entity].name];
    NSString * title = @"Unread";
    if (unreadCount>0) {
        title = @"Read";
    }
    
    if (direction == MGSwipeDirectionLeftToRight) {
        
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeArchive = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_archive"] backgroundColor:[UIColor colorWithRed:64.0f/255.0f green:179.0f/255.0f blue:79.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
                
            }
            
            return YES;
        }];
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            return YES;
        }];
        return @[btnSwipeArchive,btnSwipeDelete];
    }
    else {
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeFavorite = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_favorite"] backgroundColor:[UIColor colorWithRed:82.0f/255.0f green:195.0f/255.0 blue:240.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeFavoriteActionAtIndexPath:indexPath];
            }
            return YES;
        }];
        /*MGSwipeButton * btnSwipeSnooze = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_snooze"] backgroundColor:[UIColor colorWithRed:245.0f/255.0f green:147.0f/255.0f blue:49.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
         NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:sender];
         weakSelf.swipeIndexPath = indexPath;
         
         if (weakSelf.swipeIndexPath != nil) {
         [weakSelf showSubView];
         }
         
         return YES;
         }];*/
        
        MGSwipeButton * btnSwipeUnread = [MGSwipeButton buttonWithTitle:title icon:nil backgroundColor:[UIColor colorWithRed:74.0f/255.0f green:180.0f/255.0f blue:248.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.tableview indexPathForCell:sender];
            if (indexPath != nil) {
                [weakSelf btnSwipeMarkMessageAtIndexPath:indexPath];
            }
            
            return YES;
        }];
        return @[btnSwipeFavorite,btnSwipeUnread];
    }
    return nil;
}

-(void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
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
#pragma mark EmailListenerManagerDelegate
- (void)emailListenerManager:(EmailListenerManager*)manager didReceiveNewEmailWithId:(long)usrId {
    
    long loopCount = self.allUserEmailsData.count / [CoreDataManager fetchUserCount];
    
    int indexToUpdate = -1;
    /* loop through all sections to find which section need to update */
    for (int i = 0; i < loopCount; ++i) {
        
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:i];
        long userId = [[sectionArray objectAtIndex:6] longLongValue];
        if (userId == usrId) {
            indexToUpdate = i;
            break;
        }
    }
    NSLog(@"section to update: %d",indexToUpdate);
    /* if found, update section  */
    
    if (indexToUpdate>=0) {
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexToUpdate];
        NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
        long userId = [[sectionArray objectAtIndex:6] longLongValue];
        NSString * email = [sectionArray objectAtIndex:5];
        long limit = 2;
        if (emailsData.count>1) {
            limit = emailsData.count;
        }
        [self.allUserEmailsData replaceObjectAtIndex:indexToUpdate withObject:[self fetchUnreadEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil userId:userId userEmail:email]];
        
        [Utilities reloadSection:indexToUpdate forTableView:self.tableview withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    //    NSManagedObject * obj = nil;
    //    NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:indexPath.section];
    //    NSMutableArray * emailsData = [sectionArray objectAtIndex:3];
    //
    //    obj = [emailsData objectAtIndex:indexPath.row];
    //
    //
    //    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_BODY];
    //
    //    if ([messagePreview length]>=50) {
    //        messagePreview = [messagePreview substringToIndex:50];
    //    }
    //    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    //    [obj setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    //    [CoreDataManager updateData];
    
    NSInteger totalRowsInSection = [self.tableview numberOfRowsInSection:indexPath.section];
    if (indexPath.row<=totalRowsInSection-1) {
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [Utilities reloadTableViewRows:self.tableview forIndexArray:indexArray withAnimation:UITableViewRowAnimationNone];
    }
}

-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}

-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.tableview reloadData];
}
#pragma - mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableview beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    
    NSIndexPath * newPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:self.allUserEmailsData.count];
    NSIndexPath * oldPath = [NSIndexPath indexPathForRow:indexPath.row inSection:self.allUserEmailsData.count];
    UITableView *tableView = self.tableview;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
        {
            NSLog(@"Section : %lu Row : %lu ", newPath.section, newPath.section);
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newPath] withRowAnimation:UITableViewRowAnimationNone];
        }
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:oldPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:oldPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableview insertSections:[NSIndexSet indexSetWithIndex:self.allUserEmailsData.count] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableview deleteSections:[NSIndexSet indexSetWithIndex:self.allUserEmailsData.count] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableview endUpdates];
}
#pragma - mark InboxManagerDelegate

- (void)inboxManager:(InboxManager *)manager didReceiveEmails:(NSArray *)emails {
    [self loadImagesForOnscreenRows];
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        totalResponseCount = 0;
        [self hideProgressHud];
        //[self setActivityIndicatorViewConstant:0.0f];
        if (self.fetchedResultsController.fetchedObjects.count < 50 || isFirstFetchCall) {
            isFirstFetchCall = NO;
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
    totalResponseCount++;
    if (totalResponseCount>=self.inboxManagers.count) {
        isFetchingEmails = NO;
        totalResponseCount = 0;
        //[self setActivityIndicatorViewConstant:0.0f];
        [self hideProgressHud];
    }
}
#pragma - mark UnreadFetchManagerDelegate
- (void)unreadFetchManager:(UnreadFetchManager *)manager didReceiveEmails:(NSArray *)emails userId:(NSString *)userId {
    //[self setActivityIndicatorViewConstant:0.0f];
    long usrId = [userId longLongValue];
    
    for (int i = 0; i<self.allUserEmailsData.count; ++i) {
        NSArray * sectionArray = [self.allUserEmailsData objectAtIndex:i];
        long userId = [[sectionArray objectAtIndex:6] longLongValue];
        NSString * email = [sectionArray objectAtIndex:5];
        NSString * tag = [sectionArray objectAtIndex:7];
        if ([tag isEqualToString:@"new"]) {
            if (userId == usrId) {
                long limit = 2;
                NSMutableArray * limits = [tableViewLastSate objectForKey:[Utilities getStringFromLong:usrId]];
                if (limits.count>0) {
                    limit = [[limits objectAtIndex:0] intValue];
                }
                [self.allUserEmailsData replaceObjectAtIndex:i withObject:[self fetchUnreadEmailsWithLimit:limit offSet:0 isSearching:NO forString:nil userId:userId userEmail:email]];
                [Utilities reloadSection:i forTableView:self.tableview withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
}
- (void)unreadFetchManager:(UnreadFetchManager *)manager didReceiveError:(NSError *)error {
}
- (void)unreadFetchManager:(UnreadFetchManager *)manager noEmailsToFetchForId:(int)userId {
    NSLog(@"NO MORE UNREAD EMAILS");
    //[self setActivityIndicatorViewConstant:0.0f];
}
- (void)unreadFetchManager:(UnreadFetchManager *)manager unreadCountForUser:(long)userId unreadCount:(long)count {
    NSLog(@"count delegate fire = %ld", count);
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

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType
{
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.tableview indexPathForCell:cell];
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

- (void)swipeCell:(JZSwipeCell *)cell swipeTypeChangedFrom:(JZSwipeType)from to:(JZSwipeType)to
{
    // perform custom state changes here
    NSLog(@"Swipe Changed From (%d) To (%d)", from, to);
}


-(void)dealloc {
    NSLog(@"dealloc : InboxViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
