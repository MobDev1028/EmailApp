//
//  SnoozedViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SnoozedViewController.h"
#import "Utilities.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "WebServiceManager.h"
#import "CellConfigureManager.h"
#import "SnoozeEmailSyncManager.h"
#import "SWRevealViewController.h"
#import "SmartInboxTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "EmailComposerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MCOIMAPFetchContentOperationManager.h"
#import "FavoriteEmailSyncManager.h"
#import "MailCoreServiceManager.h"
#import "ArchiveManager.h"
#import "SyncManager.h"
#import "SVPullToRefresh.h"

@interface SnoozedViewController () <JZSwipeCellDelegate>

@end

@implementation SnoozedViewController {
    BOOL isSearching;
    NSString * currentAccount;
    NSMutableDictionary * contentFetcherDictionary;
    SyncManager * inboxSync;
    SyncManager * sentSync;
    NSString * undoThreadId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    
    __weak SnoozedViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.snoozedTableView addPullToRefreshWithActionHandler:^{
        
        [weakSelf initfetchedResultsController];
    }];
    
    // setup infinite scrolling
    [self.snoozedTableView addInfiniteScrollingWithActionHandler:^{
        
    }];

}

#pragma - mark Private Methods
- (void)updateVisibleRows:(NSNotification *)notification {
    NSString * strId = [notification.userInfo valueForKey:kUSER_ID];
    long longUserId = [strId longLongValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
}
-(void)setUpView {
    [self setActivityIndicatorViewConstant:0.0f];
    undoThreadId = nil;
    [self refreshServices];
    
    [self contentFetcherWithBool:YES];
    
    [self.navigationController.navigationBar setHidden:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSnoozedNotification:) name:kNSNOTIFICATIONCENTER_SNOOZE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshServices) name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVisibleRows:) name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshServices)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    [self.txtSearchField addTarget:self action:@selector(searchContentsOfTextField:) forControlEvents:UIControlEventEditingChanged];
    
    // get emails from db
    [self initfetchedResultsController];
    
    [self.snoozedTableView setBackgroundView:nil];
    [self.snoozedTableView setBackgroundColor:[UIColor clearColor]];
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Snoozed";
    
    UIBarButtonItem * btnNavSearch=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_search"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(btnNavigationSearchAction:)];
    self.navigationItem.rightBarButtonItem = btnNavSearch;
    isSearching = NO;
    self.txtSearchField.text = @"";
    self.heightSearchBar.constant = 0.0f;
    [self.view layoutIfNeeded];
    
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:revealController
                                                             action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = btnMenu;
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:NO];
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
                if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_inbox"]) {
                    NSMutableDictionary * dictionaryCopy = [dic copy];
                    NSMutableArray * messages = [dictionaryCopy objectForKey:@"messages"];
                    for (NSManagedObject * obj in messages) {
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                        [CoreDataManager updateData];
                    }
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
            }
        }
        else {
            if ([[dic objectForKey:@"actiontype"] isEqualToString:@"mark_inbox"]) {
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
- (void)searchContentsOfTextField:(id)sender {
    
    NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    [self fetchResultsFromDbForString:txt];
    
}
-(void)initfetchedResultsController {
    [self fetchResultsFromDbForString:nil];
}
-(void)fetchResultsFromDbForString:(NSString *)text {
    currentAccount = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    long userId = -1;
    if (!self.fetchMultipleAccount) {
        userId = [currentAccount longLongValue];
    }
    self.fetchedResultsController = nil;
    if ([Utilities isValidString:text]) {
        isSearching = YES;
        NSError *error;
        self.fetchedResultsController = [CoreDataManager fetchedSnoozedEmailsForController:self.fetchedResultsController forUser:userId isSearching:YES searchText:text];
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
        self.fetchedResultsController = [CoreDataManager fetchedSnoozedEmailsForController:self.fetchedResultsController forUser:userId isSearching:NO searchText:@""];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        self.fetchedResultsController.delegate = self;
        isSearching = NO;
        [self showNotFoundLabelWithText:kNO_SNOOZED_AVAILABLE_MESSAGE];
    }
    [self.snoozedTableView reloadData];
    
    [self.snoozedTableView.pullToRefreshView stopAnimating];
    [self.snoozedTableView.infiniteScrollingView stopAnimating];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadImagesForOnscreenRows];
    });
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
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:YES entity:[object entity].name];
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
-(void)btnSwipeMoveToInboxAtIndexPath:(NSIndexPath *)indexPath {
    [self setActivityIndicatorViewConstant:30.0f];
    if (self.undoArray == nil) {
        self.undoArray = [[NSMutableArray alloc] init];
    }
    else {
        [self performActions:NO];
    }
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    uint64_t longThreadId = [[object valueForKey:kEMAIL_THREAD_ID] longLongValue];
    NSString * strThreadId = [NSString stringWithFormat:@"%llu",longThreadId];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:[object entity].name];
    undoThreadId = strThreadId;
    NSMutableDictionary * undoDictionary = [[NSMutableDictionary alloc] init];
    [undoDictionary setObject:@"mark_inbox" forKey:@"actiontype"];
    [undoDictionary setObject:emailIdArray forKey:@"messages"];
    [undoDictionary setObject:strThreadId forKey:kEMAIL_THREAD_ID];
    [self.undoArray addObject:undoDictionary];
    self.lblUndo.text = @"Email moved";
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    
    for (NSManagedObject * obj in emailIdArray) {
        [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
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
        }
    }
    [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
}
-(void)markArchiveMessageLocally:(NSMutableArray*)messages {
    for (NSManagedObject * objc in messages) {
        [objc setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
    }
}
-(void)markArchiveOnServer:(NSMutableArray*)messages {
    for (NSManagedObject * obj in messages) {
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        uint64_t longThreadId = [[obj valueForKey:kEMAIL_THREAD_ID] longLongValue];
        NSString * strThreadId = [NSString stringWithFormat:@"%llud",longThreadId];
        if (imapSession != nil) {
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:usrId emailUid:uniqueId];
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
        [self performSelector:@selector(hideUndoBar) withObject:nil afterDelay:kUNDO_ACTION_TIME];
    }
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
    
    NSArray *visiblePaths = [self.snoozedTableView indexPathsForVisibleRows];
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

-(void)getUserProfileForEmail:(NSString *)email object:(NSManagedObject *)object indexPath:(NSIndexPath*)indexPath {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            NSString * strUrl = [[Utilities parseProfile:response] objectAtIndex:1];
            [object setValue:strUrl forKey:kSENDER_IMAGE_URL];
            [CoreDataManager updateData];
        }
    } onError:^( NSString *resultMessage , int erorrCode) {
        if (erorrCode == -1011) {
            [object setValue:kNOT_FOUND forKey:kSENDER_IMAGE_URL];
            [CoreDataManager updateData];
        }
    }];
}

-(void)didReceiveSnoozedNotification:(NSNotification*)notification {
    //[self updateSnoozedTable];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_SNOOZE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kINTERNET_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNOTIFICATIONCENTER_UPDATE_CALL object:nil];
    [self contentFetcherWithBool:NO];
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
-(IBAction)undoAction:(id)sender {
    [self setActivityIndicatorViewConstant:0.0f];
    [self performActions:YES];
}
-(IBAction)btnNavigationSearchAction:(id)sender {
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
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
}
-(IBAction)btnAddAction:(id)sender {
    [self.view endEditing:YES];
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @"Compose";
    emailComposerViewController.isDraft = NO;
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}

#pragma - mark UITableView Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
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
    cell.lblSubject.text = [emailData valueForKey:kEMAIL_SUBJECT];
    long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[emailData valueForKey:kMESSAGE_INSTANCE]];
    
    MCOAddress * mcoAddress = message.header.from;
    NSString * name = mcoAddress.displayName;
    if (![Utilities isValidString:name]) { // if sender name nil, set email as name
        name = [emailData valueForKey:kEMAIL_TITLE];
    }
    cell.lblSenderName.text = name;
    cell.btnAttachment.hidden = ![[emailData valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
    NSString * messagePreview = [emailData valueForKey:kEMAIL_PREVIEW];
    NSString * messageId = [emailData valueForKey:kEMAIL_ID];
    cell.tag = messageId.integerValue;
    if ([Utilities isValidString:messagePreview]) {
        cell.lblDetail.text = messagePreview;
    } else {
        cell.lblDetail.text = @" ";
    }
    NSString * imgUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
    
    if (imgUrl != nil && ![imgUrl isEqualToString:kNOT_FOUND]) {
        [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    }
    else {
        cell.imgProfile.image = [UIImage imageNamed:@"profile_image_placeholder"];
    }
    
    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[emailData valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:[emailData valueForKey:kMAIL_FOLDER]] entity:[emailData entity].name];
    
    if (unreadCount>0) {
        cell.imgNitificationCount.hidden = NO;
        cell.lblNitificationCount.text = [NSString stringWithFormat:@"%d",unreadCount];
    }
    else {
        cell.imgNitificationCount.hidden = YES;
        cell.lblNitificationCount.text = @"";
    }
    
    cell.btnFavorite.hidden = ![[emailData valueForKey:kIS_FAVORITE] boolValue];
    
    NSDate * snoozedDate = [emailData valueForKey:kSNOOZED_DATE];
    if ([[emailData valueForKey:kIS_SNOOZED] boolValue]) {
        if ([Utilities isDateInFuture:snoozedDate]) { // notification is not fired yet
            cell.contraintClockWidth.constant = 17.0f;
            cell.lblDate.text = [Utilities getStringFromDate:snoozedDate withFormat:@"MMM d,h:mm a"];
        }
        else {
            cell.contraintClockWidth.constant = 0.0f; // hide clock icon
            NSString * firebaseId = [emailData valueForKey:kSNOOZED_FIREBASE_ID];
            if ([Utilities isValidString:firebaseId]) {
                
                long usrId = [[emailData valueForKey:kUSER_ID] longLongValue];
                NSString * strUid = [Utilities getStringFromLong:usrId];
                [Utilities syncToFirebase:nil syncType:[SnoozeEmailSyncManager class] userId:strUid performAction:kActionDelete firebaseId:firebaseId];
            }
        }
    }
    else {
        cell.contraintClockWidth.constant = 0.0f;
    }
    
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
    
    [self setupSwipeCellOptionsFor:cell];
    
    return  cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 97.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

#pragma - mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [CellConfigureManager didTapOnEmail:managedObject folderType:kFolderSnoozeMail];
}

#pragma mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *obj = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_BODY];
    
    if ([messagePreview length]>=50) {
        messagePreview = [messagePreview substringToIndex:50];
    }
    
    [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    [obj setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    [CoreDataManager updateData];
}

-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    
}

-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    [self.snoozedTableView reloadData];
}

#pragma mark NSFetchedResultsController Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.snoozedTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.snoozedTableView;
    
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
            [self.snoozedTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.snoozedTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.snoozedTableView endUpdates];
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
            
            NSIndexPath * indexPath = [weakSelf.snoozedTableView indexPathForCell:sender];
            [weakSelf btnSwipeArchiveActionAtIndexPath:indexPath];
            return YES;
        }];
        MGSwipeButton * btnSwipeDelete = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_delete"] backgroundColor:[UIColor colorWithRed:208.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.snoozedTableView indexPathForCell:sender];
            [weakSelf btnSwipeDeleteActionAtIndexPath:indexPath];
            
            return YES;
        }];
        return @[btnSwipeArchive,btnSwipeDelete];
    } else {
        
        expansionSettings.fillOnTrigger = YES;
        MGSwipeButton * btnSwipeInbox = [MGSwipeButton buttonWithTitle:@"Inbox" icon:nil backgroundColor:[UIColor colorWithRed:167.0f/255.0f green:102.0f/255.0f blue:166.0f/255.0f alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            
            NSIndexPath * indexPath = [weakSelf.snoozedTableView indexPathForCell:sender];
            [weakSelf btnSwipeMoveToInboxAtIndexPath:indexPath];
            return YES;
        }];
        MGSwipeButton * btnSwipeFavorite = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"btn_swipe_favorite"] backgroundColor:[UIColor colorWithRed:82.0f/255.0f green:195.0f/255.0 blue:240.0f/255.0 alpha:1.0f] padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
            NSIndexPath * indexPath = [weakSelf.snoozedTableView indexPathForCell:sender];
            [weakSelf btnSwipeFavoriteActionAtIndexPath:indexPath];
            
            return YES;
        }];
        return @[btnSwipeInbox, btnSwipeFavorite];
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

-(void)dealloc {
    NSLog(@"dealloc - SnoozedViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupSwipeCellOptionsFor:(SmartInboxTableViewCell *) cell {

    cell.imageSet = SwipeCellImageSetMake(kIMAGE_SWIPE_CELL_DELETE, kIMAGE_SWIPE_CELL_ARHIEVE, kIMAGE_SWIPE_CELL_FAVOURITE, kIMAGE_SWIPE_CELL_INBOX);
    cell.colorSet = SwipeCellColorSetMake(kCOLOR_SWIPE_CELL_DELETE, kCOLOR_SWIPE_CELL_ARCHIVE, kCOLOR_SWIPE_CELL_FAVOURITE, kCOLOR_SWIPE_CELL_INBOX);
    
    cell.delegate = self;
}

#pragma mark - JZSwipeCellDelegate methods

- (void)swipeCell:(JZSwipeCell*)cell triggeredSwipeWithType:(JZSwipeType)swipeType {
    if (swipeType != JZSwipeTypeNone)
    {
        NSIndexPath *indexPath = [self.snoozedTableView indexPathForCell:cell];
        if (indexPath)
        {
            if (swipeType == JZSwipeTypeLongRight) {
                [self btnSwipeArchiveActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortRight) {
                [self btnSwipeDeleteActionAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeLongLeft) {
                
                [self btnSwipeMoveToInboxAtIndexPath:indexPath];
            }
            else if (swipeType == JZSwipeTypeShortLeft) {
                [self btnSwipeFavoriteActionAtIndexPath:indexPath];
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
