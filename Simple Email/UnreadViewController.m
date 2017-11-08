//
//  UnreadViewController.m
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "Utilities.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "WebServiceManager.h"
#import "EmailUpdateManager.h"
#import "CellConfigureManager.h"
#import "UnreadViewController.h"
#import "SWRevealViewController.h"
#import "SWRevealViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "ArchiveManager.h"
#import "MailCoreServiceManager.h"
#import "FavoriteEmailSyncManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SnoozeView.h"
#import "DatePickerView.h"
#import "CustomizeSnoozesViewController.h"
#import "SyncManager.h"
#import "SVPullToRefresh.h"

@interface UnreadViewController () <JZSwipeCellDelegate>

@end

@implementation UnreadViewController {
    NSMutableDictionary * contentFetcherDictionary;
    NSString * userId;
    NSString * currentEmail;
    BOOL isFetchingEmails;
    MBProgressHUD * hud;
    BOOL isSearching;
    NSIndexPath * didSelectIndexPath;
    EmailUpdateManager * updateManager;
    BOOL snoozedOnlyIfNoReply;
    SnoozeView * snoozeView;
    DatePickerView * datePickerView;
    NSManagedObject * snoozeObject;
    SyncManager * inboxSync;
    SyncManager * sentSync;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak UnreadViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.unreadTableView addPullToRefreshWithActionHandler:^{
        
        [weakSelf fetchResultsFromDbForString:nil];
    }];
    
    // setup infinite scrolling
    [self.unreadTableView addInfiniteScrollingWithActionHandler:^{
        
        [weakSelf fetchResultsFromDbForString:nil];
    }];
    
    [self setUpView];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (didSelectIndexPath !=nil ) {
        //        NSArray* indexArray = [NSArray arrayWithObjects:didSelectIndexPath, nil];
        //        [Utilities reloadTableViewRows:self.unreadTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationRight];
        //        didSelectIndexPath = nil;
        [self fetchResultsFromDbForString:self.txtSearchField.text];
    }
}
#pragma - mark Private Methods
-(void)setUpView {
    undoThreadId = nil;
    [self setActivityIndicatorViewConstant:0.0f];
    [self refreshServices];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshServices)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    snoozeView  =   [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    [self contentFetcherWithBool:YES];
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    [self.txtSearchField addTarget:self action:@selector(textFieldContentDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self fetchResultsFromDbForString:self.txtSearchField.text];
    [self.navigationController.navigationBar setHidden:NO];
    [self.unreadTableView setBackgroundView:nil];
    [self.unreadTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Unread";
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
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}
- (void)loadImagesForOnscreenRows {
    
    NSArray *visiblePaths = [self.unreadTableView indexPathsForVisibleRows];
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
-(void)setActivityIndicatorViewConstant:(int)constant {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideUndoBar) object:nil];
    if (self.activityIndicatorHeightConstraint.constant == 30 && constant == 30) {
        return;
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
                    //[self markMessageLocally:messages markCount:markCount];
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
                //[self markMessageOnServer:dictionaryCopy];
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
-(IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}
-(void)fetchResultsFromDbForString:(NSString *)text {
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        [self.fetchedResultsController setDelegate:self];
        
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedUnreadEmailsForController:self.fetchedResultsController forUser:-1 isSearching:YES searchText:text];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        [self showNotFoundLabelWithText:kNO_RESULTS_MESSAGE];
    }
    else {
        
        NSError *error;
        
        self.fetchedResultsController = [CoreDataManager fetchedUnreadEmailsForController:self.fetchedResultsController forUser:-1 isSearching:NO searchText:nil];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
        [self showNotFoundLabelWithText:kNO_UNREAD_AVAILABLE_MESSAGE];
    }
    
    [self.unreadTableView.pullToRefreshView stopAnimating];
    [self.unreadTableView.infiniteScrollingView stopAnimating];
    
    [self.unreadTableView reloadData];
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
    
    if (snoozeObject == nil) {
        return;
    }
    long usrId = [[snoozeObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * mail = [Utilities getEmailForId:strUid];
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
    if (![Utilities isValidString:mail]) {
        return;
    }
    [Utilities setEmailToSnoozeTill:date withObject:snoozeObject currentEmail:mail onlyIfNoReply:snoozedOnlyIfNoReply userId:strUid];
    [self addUndoActionForSnooze];
}
- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
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
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:NO threadId:[strThreadId longLongValue] entity:[object entity].name];
            }
        }
    }
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
        long intId = [[obj valueForKey:kUSER_ID] integerValue];
        NSString * strId = [NSString stringWithFormat:@"%ld",intId];
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strId];
        uint64_t longThreadId = [[obj valueForKey:kEMAIL_THREAD_ID] longLongValue];
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:intId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strId markArchive:YES threadId:longThreadId entity:[obj entity].name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:intId];
                
                if (emailInfo.count>0) {
                    NSManagedObject * infoObject = [emailInfo lastObject];
                    
                    NSArray * array =  [Utilities getIndexSetFromObject:infoObject];
                    MCOIndexSet * indexSet = [array objectAtIndex:1];
                    
                    [[ArchiveManager sharedArchiveManager] markArchiveIndexSet:indexSet forFolder:kFOLDER_INBOX withSessaion:imapSession destinationFolder:kFOLDER_ALL_MAILS completionBlock:^(id response) {
                        for (NSManagedObject * object in messages) {
                            /* change folder name to [Gmail]/All Mail if email belong to INBOX */
                            NSString * folderName = [object valueForKey:kMAIL_FOLDER];
                            if ([folderName isEqualToString:kFOLDER_INBOX]) {
                                [object setValue:kFOLDER_ALL_MAILS forKey:kMAIL_FOLDER];
                            }
                            [self syncDeleteActionToFirebaseWithObject:object];
                        }
                        [CoreDataManager updateData];
                        
                    } onError:^( NSError * error) {
                        for (NSManagedObject * objc in messages) {
                            [objc setValue:[NSNumber numberWithBool:NO] forKey:kIS_ARCHIVE];
                            [CoreDataManager updateData];
                        }
                    }];
                }
            }
        }
    }
}
-(void)btnSwipeFavoriteActionAtIndexPath:(NSIndexPath *)indexPath {
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter ] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    if (inboxSync != nil) {
        inboxSync.invalidateTimer = YES;
        inboxSync = nil;
    }
    
    if (sentSync != nil) {
        sentSync.invalidateTimer = YES;
        sentSync = nil;
    }
    if (updateManager) {
        updateManager.delegate = nil;
    }
    [self contentFetcherWithBool:NO];
}
-(void)getUserProfileForEmail:(NSString *)email object:(NSManagedObject *)object  indexPath:(NSIndexPath*)indexPath {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            /*/NSManagedObjectContext *context = [CoreDataManager getManagedObjectContext];
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
    long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    MCOIMAPFetchContentOperationManager *contentFetchManager = [contentFetcherDictionary objectForKey:strUid];
    
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
    
    [self setupSwipeCellOptionsFor:cell];
    
    //cell.delegate = self;
    //cell.allowsOppositeSwipe = NO;
    //cell.allowsMultipleSwipe = YES;
    return [CellConfigureManager configureInboxCell:cell withData:emailData andContentFetchManager:contentFetchManager view:self.view atIndexPath:indexPath isSent:NO];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 97.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    didSelectIndexPath = indexPath;
    NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
    [Utilities reloadTableViewRows:self.unreadTableView forIndexArray:indexArray withAnimation:UITableViewRowAnimationLeft];
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:emailData folderType:kFolderInboxMail];
}


#pragma - mark User Actions
-(IBAction)btnNavigationSearchAction:(id)sender {
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        if (self.heightSearchBar.constant == 43.0) {
            self.heightSearchBar.constant = 0.0f;
            self.txtSearchField.text = @"";
            [self fetchResultsFromDbForString:nil];
            //[self.view endEditing:YES];
        }
        else {
            //self.txtSearchField.text = @"";
            self.heightSearchBar.constant = 43.0f;
            //[self.txtSearchField becomeFirstResponder];
        }
        [self.view setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25f animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}
- (void)textFieldContentDidChange:(id)sender {
    NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    [self fetchResultsFromDbForString:txt];
}
#pragma mark - MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    //    NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:indexPath];//[self.messagesArray objectAtIndex:indexPath.row];
    //
    //    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    //    [obj setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    // [CoreDataManager updateData];
    if (isSearching == NO) {
        NSInteger totalRowsInSection = [self.unreadTableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row<=totalRowsInSection-1) {
            [Utilities reloadTableViewRows:self.unreadTableView forIndexArray:[NSArray arrayWithObjects:indexPath, nil] withAnimation:UITableViewRowAnimationNone];
        }
    }
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.unreadTableView reloadData];
}
#pragma mark NSFetchedResultsController Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.unreadTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.unreadTableView;
    
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
            [self.unreadTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.unreadTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.unreadTableView endUpdates];
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
        MGSwipeButton * btnSwipeArchive = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_archive"] backgroundColor:[UIColor colorWithRed:64.0f/255.0f green:179.0f/255.0f blue:79.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.unreadTableView indexPathForCell:sender];
            [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
            
            return YES;
        }];
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.unreadTableView indexPathForCell:sender];
            [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            
            return YES;
        }];
        return @[btnSwipeArchive,btnSwipeDelete];
    }
    else {
        
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeFavorite = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_favorite"] backgroundColor:[UIColor colorWithRed:82.0f/255.0f green:195.0f/255.0 blue:240.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.unreadTableView indexPathForCell:sender];
            
            [weakSelf btnSwipeFavoriteActionAtIndexPath:indexPath];
            
            return YES;
        }];
        MGSwipeButton * btnSwipeSnooze = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_snooze"] backgroundColor:[UIColor colorWithRed:245.0f/255.0f green:147.0f/255.0f blue:49.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.unreadTableView indexPathForCell:sender];
            weakSelf.swipeIndexPath = indexPath;
            
            if (weakSelf.swipeIndexPath != nil) {
                [weakSelf showSubView];
            }
            return YES;
        }];
        return @[btnSwipeFavorite,btnSwipeSnooze];
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
-(void)dealloc {
    NSLog(@"dealloc : RegularInboxViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setupSwipeCellOptionsFor:(SmartInboxTableViewCell *) cell {
    cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_ARHIEVE, kIMAGE_SWIPE_CELL_SNOOZE, kIMAGE_SWIPE_CELL_FAVOURITE);
    cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_ARCHIVE, kCOLOR_SWIPE_CELL_SNOOZE, kCOLOR_SWIPE_CELL_FAVOURITE);
    cell.delegate = self;
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType
{
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.unreadTableView indexPathForCell:cell];
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


@end
