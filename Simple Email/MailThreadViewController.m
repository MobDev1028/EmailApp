//
//  MailThreadViewController.m
//  SimpleEmail
//
//  Created by Zahid on 19/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "MailThreadViewController.h"
#import "SmartInboxTableViewCell.h"
#import "MoreButtonTableViewCell.h"
#import "InboxHeaderTableViewCell.h"
#import "Utilities.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EmailDetailViewController.h"
#import "WebServiceManager.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import "MessageGroupCell.h"
#import "EmailComposerViewController.h"
#import "FavoriteEmailSyncManager.h"
#import "MailCoreServiceManager.h"
#import "SnoozeEmailSyncManager.h"
#import "MessageDetailView.h"
#import "ArchiveManager.h"
#import "MBProgressHUD.h"
#import "QuickReplyCell.h"
#import "SnoozeView.h"
#import "ComposeQuickResponseViewController.h"
#import "MoreActionView.h"
#import "MoveView.h"
#import "CustomizeSnoozesViewController.h"
#import "DatePickerView.h"
#import "FileAttachmentTableViewCell.h"
#import "SharedInstanceManager.h"
#import "AppDelegate.h"
#import "MCOIMAPSessionManager.h"

@interface MailThreadViewController ()

@end

@implementation MailThreadViewController {
    MCOIMAPFetchContentOperationManager * contentFetchManager;
    long userId;
    NSMutableDictionary * heightDictionary;
    NSMutableDictionary * cellStates;
    MessageDetailView * messageDetailView;
    MoreActionView * moreActionView;
    CGFloat screenHeight;
    CGFloat screenWidth;
    NSString * threadId;
    SnoozeView *snoozeView;
    NSArray * quickResponses;
    NSString * quickResponseUserId;
    NSString * currentEmail;
    MBProgressHUD * hud;
    MoveView * moveView;
    NSManagedObjectID * actionObjectID;
    NSString * entityName;
    BOOL snoozedOnlyIfNoReply;
    DatePickerView * datePickerView;
    BOOL changeNotifier;
    MCOIMAPSessionManager * imapSessionManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    changeNotifier = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[CoreDataManager getManagedObjectContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEmailNotificationReceived:) name:kNEW_EMAIL_NOTIFICATION object:nil];
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    if (self.pushDatadictionary != nil) {
        self.isViewPresented = YES;
        [self openThreadView];
    }
    else {
        self.isViewPresented = NO;
        userId = [[self.object valueForKey:kUSER_ID] integerValue];
        threadId = [self.object valueForKey:kEMAIL_THREAD_ID];
        NSEntityDescription * des = [self.object entity];
        entityName = des.name;
        [self showProgressHudWithTitle:@""];
        UIBarButtonItem * btnBack = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_back"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(btnBackAction:)];
        self.navigationItem.leftBarButtonItem = btnBack;
    }
    
    //quickResponseUserId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    //if (![Utilities isValidString:quickResponseUserId]) {
    quickResponseUserId = [Utilities getStringFromLong:userId];
    //}
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[quickResponseUserId longLongValue]];
    NSManagedObject * user = [userArray lastObject];
    currentEmail = [user valueForKey:kUSER_EMAIL];
    if (self.folderType != kFolderTrashMail) {
        UIBarButtonItem * btnNavClock=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_clock"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(btnNaviClockAction:)];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnNavClock, nil];
    }
    
    /*[self.view removeConstraint:self.contraintLeading];
     [self.view removeConstraint:self.contraintTrailing];
     [self.btnArchive setHidden:YES];
     self.contraintTrailing = [NSLayoutConstraint constraintWithItem:self.btnReply attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.btnTrash attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
     [self.view addConstraint:self.contraintTrailing];
     [self.view layoutIfNeeded];*/
    
    heightDictionary = [[NSMutableDictionary alloc] init];
    cellStates = [[NSMutableDictionary alloc] init];
    if (contentFetchManager == nil) {
        [self initBodyFetchManager];
    }
    
    self.title = self.navigationBarTitle;
    [self.threadTableView setBackgroundView:nil];
    [self.threadTableView setBackgroundColor:[UIColor clearColor]];
    [self.btnMore addTarget:self action:@selector(btnMoreAction:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView:) name:kATTACHMENT_DOWNLOADED object:nil];
}
-(void)dismissPresentedView {
    [SharedInstanceManager sharedInstance].isEmailDetailOpened = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)openThreadView {
    [SharedInstanceManager sharedInstance].isEmailDetailOpened = YES;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIBarButtonItem * btnLeftCross = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(dismissPresentedView)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:btnLeftCross, nil];
    NSString * uid = [self.pushDatadictionary objectForKey:@"decimal_id"];
    threadId = [self.pushDatadictionary objectForKey:kTHREAD_DEC];
    if (![Utilities isValidString:uid] || ![Utilities isValidString:threadId]) {
        [self showErrorWithMessage:@"Email not found."];
        [self dismissPresentedView];
        return;
    }
    NSString * emailReceiverId = nil;
    NSManagedObject * emailOwnerObj = nil;
    NSString * receiverEmail = [self.pushDatadictionary objectForKey:@"user_email"];
    NSMutableArray * allUsers = [CoreDataManager fetchAllUsers];
    /* find user id */
    for (NSManagedObject * user in allUsers) {
        NSString * userEmail = [user valueForKey:kUSER_EMAIL];
        if ([userEmail isEqualToString:receiverEmail]) {
            emailReceiverId = [user valueForKey:kUSER_ID];
            userId = [emailReceiverId integerValue];
            currentEmail = [user valueForKey:kUSER_EMAIL];
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
            //self.modelEmail = [Utilities parseEmailModelForDBdata:self.object];
            self.pushDatadictionary = nil;
            //[self setEmailContent];
            
            userId = [[self.object valueForKey:kUSER_ID] integerValue];
            threadId = [self.object valueForKey:kEMAIL_THREAD_ID];
            NSEntityDescription * des = [self.object entity];
            entityName = des.name;
            self.selectedEmailThreadId = [threadId longLongValue];
            [self updateFetchedController];
            [self fetchCompleteThreadAttachments];
            [self.threadTableView reloadData];
        }
    }
    else {
        NSLog(@"threaview: mail not found : %@",emailReceiverId);
        /* this code will execute when new email arrive and it is not
         available in db, we need to fetch it from imap server */
        [self showProgressHudWithTitle:@"Fetching Email"];
        if (emailReceiverId == nil) {
            [self showErrorWithMessage:@"Email not found."];
            return;
        }
        if (emailOwnerObj != nil) {
            //[self fetchEmailFromServerWithSession:imapSession];
            if (imapSessionManager == nil) {
                imapSessionManager = [[MCOIMAPSessionManager alloc] init];
            }
            imapSessionManager.delegate = self;
            [imapSessionManager createImapSessionWithUserData:emailOwnerObj];
            //userId = [[emailOwnerObj valueForKey:kUSER_ID] integerValue];
            //currentEmail = [emailOwnerObj valueForKey:kUSER_EMAIL];
        }
    }
}
-(void)showErrorWithMessage:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [av show];
    [self dismissPresentedView];
}
-(void)fetchEmailFromServerWithSession:(MCOIMAPSession *)session {
    NSLog(@"call made0");
    NSString * uid = [self.pushDatadictionary objectForKey:@"decimal_id"];
    uint64_t mId = [uid longLongValue];
    NSLog(@"call made1");
    MCOIMAPSearchOperation* searchOperation = [session searchExpressionOperationWithFolder:kFOLDER_INBOX expression: [MCOIMAPSearchExpression searchGmailMessageID:mId]];
    [searchOperation start:^(NSError *error, MCOIndexSet *indexSet) {
        NSLog(@"call made2");
        if (error == nil) {
            NSLog(@"call made3");
            if (indexSet.count>0) {
                NSLog(@"call made4");
                [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:indexSet fromFolder:kFOLDER_INBOX withSessaion:session requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
                    NSLog(@"call made5");
                    if (error == nil) {
                        NSLog(@"call made6");
                        if (messages.count>0) {
                            NSLog(@"call made7");
                            MCOIMAPMessage *msg = [messages lastObject];
                            if ([CoreDataManager isThreadIdExist:[msg gmailThreadID] forUserId:userId forFolder:kFolderAllMail entity:kENTITY_EMAIL]>0) {
                                NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[msg gmailThreadID] andUserId:userId isTopEmail:NO isTrash:NO entity:kENTITY_EMAIL];
                                
                                int unreadCount = 0;
                                if ( msg.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                NSArray * typeArray = [Utilities getMessageTypes:msg userId:userId currentEmail:currentEmail];
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
                                
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:isThreadTop mailFolderName:kFOLDER_INBOX isSent:isSent isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:isConvo isInbox:isInbox userId:[Utilities getStringFromLong:userId] isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [Utilities markSnoozedAndFavorite:msg userId:userId isInboxMail:YES];
                            }
                            else { /* single email */
                                int unreadCount = 0;
                                if ( msg.flags == 0 ) {
                                    unreadCount = 1;
                                }
                                
                                [Utilities saveEmailModelForMessage:msg unreadCount:unreadCount isThreadEmail:NO mailFolderName:kFOLDER_INBOX isSent:NO isTrash:NO isArchive:NO isDarft:NO draftFetchedFromServer:NO isConversation:NO isInbox:YES userId:[Utilities getStringFromLong:userId] isFakeDraft:NO enitity:kENTITY_EMAIL];
                                [Utilities markSnoozedAndFavorite:msg userId:userId isInboxMail:YES];
                            }
                            
                            NSMutableArray * emailArray = [CoreDataManager fetchSingleEmailForUniqueId:mId andUserId:userId];
                            if (emailArray.count>0) {
                                self.object = [emailArray lastObject];
                                userId = [[self.object valueForKey:kUSER_ID] integerValue];
                                threadId = [self.object valueForKey:kEMAIL_THREAD_ID];
                                NSEntityDescription * des = [self.object entity];
                                entityName = des.name;
                                self.selectedEmailThreadId = [threadId longLongValue];
                                NSLog(@"call made 8");
                                [self updateFetchedController];
                                [self fetchCompleteThreadAttachments];
                                [self.threadTableView reloadData];
                                self.pushDatadictionary = nil;
                            }
                            [self hideProgressHud];
                        }
                        else {
                            [self showErrorWithMessage:@"Email not found"];
                        }
                    }
                    else {
                        [self showErrorWithMessage:error.localizedDescription];
                    }
                }onError:^(NSError* error) {
                }];
            }
            else {
                [self showErrorWithMessage:@"Email not found"];
            }
        }
        else {
            [self showErrorWithMessage:error.localizedDescription];
        }
    }];
}

- (void)handleDataModelChange:(NSNotification *)note {
    if (changeNotifier) {
        BOOL isChangeMade = NO;
        NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
        NSArray * insertObjectsArray = [insertedObjects allObjects];
        if(insertObjectsArray.count>0) {
            [self updateFetchedController];
            [self.threadTableView reloadData];
        }
        /*for (NSManagedObject * emailObject in insertObjectsArray) {
         for (int i = 0; i<self.fetchedResultsController.fetchedObjects.count; ++i) {
         NSIndexPath * path = [NSIndexPath indexPathForRow:i inSection:0];
         NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:path];
         //if ([[[emailObject objectID] URIRepresentation] isEqual:[[obj objectID] URIRepresentation]]) {
         [self updateFetchedController];
         //NSIndexPath * calculatedPath = [NSIndexPath indexPathForRow:0 inSection:i];
         //[Utilities insertTableViewRows:self.threadTableView forIndexArray:@[calculatedPath] withAnimation:UITableViewRowAnimationNone];
         [self.threadTableView reloadData];
         //}
         }
         }*/
        
        NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
        NSArray * updateObjectsArray = [updatedObjects allObjects];
        for (NSManagedObject * emailObject in updateObjectsArray) {
            for (int i = 0; i<self.fetchedResultsController.fetchedObjects.count; ++i) {
                NSIndexPath * path = [NSIndexPath indexPathForRow:i inSection:0];
                NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:path];
                if ([[[emailObject objectID] URIRepresentation] isEqual:[[obj objectID] URIRepresentation]]) {
                    [self updateFetchedController];
                    NSIndexPath * calculatedPath = [NSIndexPath indexPathForRow:0 inSection:i];
                    [Utilities reloadTableViewRows:self.threadTableView forIndexArray:@[calculatedPath] withAnimation:UITableViewRowAnimationNone];
                }
            }
        }
        NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
        NSArray * deleteObjectsArray = [deletedObjects allObjects];
        for (NSManagedObject * emailObject in deleteObjectsArray) {
            for (int i = 0; i<self.fetchedResultsController.fetchedObjects.count; ++i) {
                NSIndexPath * path = [NSIndexPath indexPathForRow:i inSection:0];
                NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:path];
                if ([[[emailObject objectID] URIRepresentation] isEqual:[[obj objectID] URIRepresentation]]) {
                    isChangeMade = YES;
                    [self updateFetchedController];
                    //NSIndexPath * calculatedPath = [NSIndexPath indexPathForRow:0 inSection:i];
                    //[Utilities removeTableViewRows:self.threadTableView forIndexArray:@[calculatedPath] withAnimation:UITableViewRowAnimationNone];
                    [self.threadTableView reloadData];
                }
            }
        }
        if (isChangeMade) {
            if (self.fetchedResultsController.fetchedObjects.count == 0) {
                NSLog(@"no object found");
                [self btnBackAction:nil];
            }
        }
    }
}
-(void)newEmailNotificationReceived:(NSNotification *)anote {
    //    self.pushDatadictionary = [anote userInfo];
    //    [self removeDelegates];
    //    [self setupView];
}
-(void)updateFetchedController {
    NSLog(@"crash 2: %@",entityName);
    if ([Utilities isValidString:entityName]) {
        self.fetchedResultsController = nil;
        NSError *error;
        self.fetchedResultsController = [CoreDataManager initThreadFetchedResultsController:self.fetchedResultsController threadId:self.selectedEmailThreadId andUserId:userId folderType:[Utilities getFolderTypeForString:self.folderName] needOnlyIds:NO isSnoozed:self.isSnoozed entity:entityName];
        [self.fetchedResultsController setDelegate:nil];
        if (![self.fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
    }
    NSLog(@"crash 3");
}
- (void)updateTableView:(NSNotification *)notification {
    NSString *stringID = [NSString stringWithFormat:@"%@",[[notification userInfo] valueForKey:kEMAIL_UNIQUE_ID]];
    NSLog(@"Received Notification = %@", stringID);
    
    if (self.attachmentDictionary == nil) {
        self.attachmentDictionary = [[NSMutableDictionary alloc] init];
    }
    for (int x = 0; x<self.fetchedResultsController.fetchedObjects.count; ++x) {
        NSIndexPath * path = [NSIndexPath indexPathForRow:x inSection:0];
        NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:path];
        NSString * uniqueId = [NSString stringWithFormat:@"%@",[object valueForKey:kEMAIL_UNIQUE_ID]];
        if ([stringID isEqualToString:uniqueId]) {
            id data = [self.attachmentDictionary objectForKey:uniqueId];
            if (data != nil) {
                [self.attachmentDictionary removeObjectForKey:uniqueId];
            }
            BOOL isAttachmentAvailable = [[object valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
            NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
            long longUserId = [[object valueForKey:kUSER_ID] longLongValue];
            NSString * strUserId = [Utilities getStringFromLong:longUserId];
            MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
            MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
            NSArray * attachamentNames = message.attachments;
            [self fetchAttchamentsForUniqueId:[uniqueId longLongValue] attachmentAvailable:isAttachmentAvailable object:object session:imapSession attachamentNames:attachamentNames];
            [self.threadTableView reloadData];
            break;
        }
    }
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateFetchedController];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self fetchCompleteThreadAttachments];
    //dispatch_async(dispatch_get_main_queue(), ^{
    [self.threadTableView reloadData];
    //});
    //});
    [self markRead];
    [self.threadTableView reloadData];
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    screenHeight = self.threadTableView.frame.size.height;
    screenWidth = self.threadTableView.frame.size.width;
    
    if ([[Utilities getUserDefaultWithValueForKey:kUSER_DEFAULTS_EMAIL_COMPOSED] isEqualToString:@"YES"]) {
        [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scheduledReload) userInfo:nil repeats:NO];
    }
}
- (void)openQLPreviewControllerWithIndex:(NSUInteger)index {
    QLPreviewController *previewController=[[QLPreviewController alloc]init];
    previewController.delegate=self;
    previewController.dataSource=self;
    previewController.currentPreviewItemIndex = index;
    
    [self.navigationController presentModalViewController:previewController animated:YES];
    UINavigationBar *navBar =  [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil];
    [navBar setBackgroundImage:[UIImage imageNamed:@"SideMenuBGColor"] forBarMetrics:UIBarMetricsDefault];
    //[previewController.navigationItem setRightBarButtonItem:nil];
    //[[self navigationController] presentModalViewController:previewController animated:YES];
}
#pragma - mark Private Methods

- (void) unloadVisibleCell
{
    NSArray *visibleRows = [self.threadTableView indexPathsForVisibleRows];
    
    for(int i = 0; i < visibleRows.count; ++i) {
        NSIndexPath *indexPath = [visibleRows objectAtIndex:i];
        
        if(indexPath != nil) {
            UITableViewCell *cell = [self.threadTableView cellForRowAtIndexPath:indexPath];
            if([cell isKindOfClass:[MessageGroupCell class]]) {
                MessageGroupCell *msgGCell = (MessageGroupCell *) cell;
                [msgGCell.lblHtmlView setDelegate:nil];
                [msgGCell.lblHtmlView stopLoading];
            }
        }
    }
}

- (void) scheduledReload {
    
    [Utilities setUserDefaultWithValue:@"NO" andKey:kUSER_DEFAULTS_EMAIL_COMPOSED];
    

    NSArray *keys = [cellStates allKeys];
    for(int i = 0; i < keys.count; ++i){
        NSString *strKey = [keys objectAtIndex:i];
        [cellStates setObject:@"0" forKey:strKey];
    }
    
    [self.threadTableView reloadData];
}

-(void)markRead {
    for (int i = 0; i<self.fetchedResultsController.fetchedObjects.count; i++) {
        NSManagedObject * obj = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        int count = [[obj valueForKey:kUNREAD_COUNT] intValue];
        if (count == 1) {
            MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
            [self markReadUid:[[obj valueForKey:kEMAIL_ID] longLongValue] forFolder:[obj valueForKey:kMAIL_FOLDER] withSessaion:imapSession object:obj];
        }
    }
}

-(void)fetchCompleteThreadAttachments {
    if (self.attachmentDictionary == nil) {
        self.attachmentDictionary = [[NSMutableDictionary alloc] init];
    }
    for (int x = 0; x<self.fetchedResultsController.fetchedObjects.count; ++x) {
        NSIndexPath * path = [NSIndexPath indexPathForRow:x inSection:0];
        NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:path];
        BOOL isAttachmentAvailable = [[object valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
        NSString * uniqueId = [object valueForKey:kEMAIL_UNIQUE_ID];
        long longUserId = [[object valueForKey:kUSER_ID] longLongValue];
        NSString * strUserId = [Utilities getStringFromLong:longUserId];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
        MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
        NSArray * attachamentNames = message.attachments;
        [self fetchAttchamentsForUniqueId:[uniqueId longLongValue] attachmentAvailable:isAttachmentAvailable object:object session:imapSession attachamentNames:attachamentNames];
    }
}
-(void)fetchAttchamentsForUniqueId:(uint64_t)uid attachmentAvailable:(BOOL)attachmentAvailable object:(NSManagedObject *)object session:(MCOIMAPSession *)session attachamentNames:(NSArray *)attachamentNames {
    if (self.attachmentDictionary == nil) {
        self.attachmentDictionary = [[NSMutableDictionary alloc] init];
    }
    NSMutableArray * attachments = [CoreDataManager getAttachment:userId emailUid:uid entity:kENTITY_ATTACHMENTS];
    if (attachments.count == 0) {
        if (attachmentAvailable) { /* Fetch attachments from server */
            [[MailCoreServiceManager sharedMailCoreServiceManager] downloadAttachments:object session:session email:currentEmail];
            
            /* below line just add name to list,until real data fetched */
            NSString * strId = [NSString stringWithFormat:@"%llu",uid];
            [self.attachmentDictionary setObject:attachamentNames forKey:strId];
        }
        return;
    }
    /* all attachments */
    if (attachments.count>=1) {
        NSManagedObject * object = [attachments objectAtIndex:0];
        NSMutableArray * attachmentPaths = (NSMutableArray *)[Utilities getUnArchivedArrayForObject:[object valueForKey:kATTACHMENT_PATHS]];
        if (attachmentPaths.count>=1) {
            NSString * path = [attachmentPaths objectAtIndex:0];
            NSArray * array = [Utilities getAttachmentListFromPath:path];
            if (array != nil && array.count>0) {
                NSString * strId = [NSString stringWithFormat:@"%llu",uid];
                [self.attachmentDictionary setObject:array forKey:strId];
                NSLog(@"all attachments: %@",self.attachmentDictionary);
            }
        }
    }
}
-(void)initBodyFetchManager {
    contentFetchManager = [[MCOIMAPFetchContentOperationManager alloc] init];
    contentFetchManager.delegate = self;
    NSString * uId = [NSString stringWithFormat:@"%ld",userId];
    [contentFetchManager createFetcherWithUserId:uId];
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
-(void)deleteEmail:(NSManagedObject *)object {
    NSString * folderName  = [object valueForKey:kMAIL_FOLDER];
    MCOIndexSet * indexSet = [[MCOIndexSet alloc] init];
    [indexSet addIndex:[[object valueForKey:kEMAIL_ID] longLongValue]];
    long usrId = [[object valueForKey:kUSER_ID] longLongValue];
    NSString * strUid = [Utilities getStringFromLong:usrId];
    NSString * thrdId = [object valueForKey:kEMAIL_THREAD_ID];
    long threadCount = [CoreDataManager isThreadIdExist:[thrdId longLongValue] forUserId:usrId forFolder:kFolderAllMail entity:entityName];
    [object setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
    [CoreDataManager updateData];
    
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
    if (imapSession != nil) {
        [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:kFOLDER_TRASH_MAILS completionBlock:^(id response) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (threadCount>0 ) {
                    if (threadCount == 1) { /* delete from firebase only if single email*/
                        [self syncDeleteActionToFirebaseWithObject:object];
                    }
                    
                    NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[thrdId longLongValue] andUserId:usrId isTopEmail:YES isTrash:NO entity:entityName];
                    if (array.count>0) {
                        NSManagedObject *obj = [array lastObject];
                        [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_THREAD_TOP_EMAIL];
                        [CoreDataManager updateData];
                    }
                }
                // delete email
                [CoreDataManager deleteObject:object];
                [CoreDataManager updateData];
            });
        } onError:^( NSError * error) {
            [object setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
            [CoreDataManager updateData];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Cannot delete message!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        }];
    }
}

-(void)openComposerWithMessageType:(int)messageType quickResponseObject:(NSManagedObject *)QRobject manageObject:(NSManagedObject *)object {
    EmailComposerViewController * emailComposerViewController = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    emailComposerViewController.strNavTitle = @" ";
    emailComposerViewController.draftObject = object;
    emailComposerViewController.quickResponseObject = QRobject;
    emailComposerViewController.mailType = messageType;
    emailComposerViewController.isDraft = NO;
    [self.navigationController pushViewController:emailComposerViewController animated:YES];
}

-(void)markReadUid:(long)uid forFolder:(NSString *)folderName withSessaion:(MCOIMAPSession *)session object:(NSManagedObject *)object {
    [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
    [CoreDataManager updateData];
    MCOIMAPOperation *msgOperation = [session storeFlagsOperationWithFolder:folderName
                                                                       uids:[MCOIndexSet indexSetWithIndex:uid]
                                                                       kind:MCOIMAPStoreFlagsRequestKindAdd flags:MCOMessageFlagSeen];
    
    [msgOperation start:^(NSError * error) {
        if (error == nil) {
            NSLog(@"Marked Seen.............");
            [object setValue:[NSNumber numberWithLong:0] forKey:kUNREAD_COUNT];
            [CoreDataManager updateData];
        }
        else {
            //[object setValue:[NSNumber numberWithLong:1] forKey:kUNREAD_COUNT];
            //[CoreDataManager updateData];
            NSLog(@"error = %@", error.localizedDescription);
        }
    }];
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
    changeNotifier = NO;
    NSString * strUid = [Utilities getStringFromLong:userId];
    
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[threadId longLongValue] andUserId:userId folderType:kFolderAllMail needOnlyIds:NO entity:entityName];
    
    for (NSManagedObject * obj in emailIdArray) {
        uint64_t uniqueId = [[obj valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        NSEntityDescription * des = [obj entity];
        if (imapSession != nil) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kIS_ARCHIVE];
            [CoreDataManager updateData];
            BOOL isInfoExist = [CoreDataManager isEmailInfoExist:userId emailUid:uniqueId];
            /* fetch email from server with Inbox
             Folder and save it locally */
            if (!isInfoExist) {
                [Utilities fetchEmailForUniqueId:uniqueId session:imapSession userId:strUid markArchive:YES threadId:[threadId longLongValue] entity:des.name];
            }
            else {
                NSMutableArray * emailInfo = [CoreDataManager fetchEmailInfo:uniqueId userId:userId];
                
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
    [self btnBackAction:nil];
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
-(void)markMessages {
    
    if (![Utilities isInternetActive]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet error!"
                                                        message:@"Please check your internet connection and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    changeNotifier = NO;
    //NSString * folder = [self.object valueForKey:kMAIL_FOLDER];
    NSString * strThreadId = [self.object valueForKey:kEMAIL_THREAD_ID];
    long usrId = [[self.object valueForKey:kUSER_ID] longLongValue];
    //    int unreadCount = [CoreDataManager fetchUnreadCountUserId:usrId threadId:[[self.object valueForKey:kEMAIL_THREAD_ID] longLongValue] folderType:[Utilities getFolderTypeForString:folder]];
    //    int markCount = 1;
    //    if (unreadCount>0) {
    //        markCount = 0;
    //    }
    
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[strThreadId longLongValue] andUserId:usrId folderType:[Utilities getFolderTypeForString:[self.object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:entityName];
    
    for (NSManagedObject * obj in emailIdArray) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        long usrId = [[obj valueForKey:kUSER_ID] longLongValue];
        NSString * strUid = [Utilities getStringFromLong:usrId];
        
        //        [obj setValue:[NSNumber numberWithLong:markCount] forKey:kUNREAD_COUNT];
        //        [CoreDataManager updateData];
        
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            MCOIMAPStoreFlagsRequestKind req = MCOIMAPStoreFlagsRequestKindAdd;
            
            //            if (markCount == 0) { /* MARK UNREAD HERE */
            //
            //            }
            //            else { /* MARK READ HERE */
            //                req = MCOIMAPStoreFlagsRequestKindRemove;
            //            }
            
            [[MailCoreServiceManager sharedMailCoreServiceManager] markMessage:indexSet fromFolder:folderName withSessaion:imapSession requestKind:req flagType:MCOMessageFlagFlagged completionBlock:^(void) {
                
            }onError:^(NSError * error) {
                
            }];
        }
    }
    [self btnBackAction:nil];
}
-(void)moveToFolder:(NSString *)folder {
    if (![Utilities isInternetActive]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet error!"
                                                        message:@"Please check your internet connection and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    changeNotifier = NO;
    NSString * strUid = [Utilities getStringFromLong:userId];
    NSMutableArray * emailIdArray = [CoreDataManager fetchEmailsForThreadId:[threadId longLongValue] andUserId:userId folderType:[Utilities getFolderTypeForString:[self.object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO isSnoozed:NO entity:entityName];
    for (NSManagedObject * obj in emailIdArray) {
        NSArray * array =  [Utilities getIndexSetFromObject:obj];
        NSString * folderName = [array objectAtIndex:0];
        MCOIndexSet * indexSet = [array objectAtIndex:1];
        [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
        [CoreDataManager updateData];
        NSString * entity = [obj entity].name;
        MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUid];
        if (imapSession != nil) {
            [[MailCoreServiceManager sharedMailCoreServiceManager] copyIndexSet:indexSet fromFolder:folderName withSessaion:imapSession toFolder:folder completionBlock:^(id response) {
                NSIndexSet * ind = indexSet.nsIndexSet;
                uint64_t emailUid = ind.firstIndex;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:emailUid userId:userId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [self syncDeleteActionToFirebaseWithObject:object];
                    [CoreDataManager deleteObject:object];
                }
                [CoreDataManager updateData];
            } onError:^( NSError * error) {
                NSLog(@"cannot delete error: %@", error.localizedDescription);
                NSIndexSet * ind = indexSet.nsIndexSet;
                NSMutableArray * email = [CoreDataManager fetchEmailWithId:ind.firstIndex userId:userId entity:entity];
                
                for (NSManagedObject * object in email) {
                    [object setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                    [CoreDataManager updateData];
                }
            }];
        }
    }
    [self btnBackAction:nil];
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
#pragma mark - QLPreviewControllerDatasource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.allAttachments.count;
}
- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    NSString *path = [self documentDirectoryPathForResource:self.allAttachments[index]];
    
    return [NSURL fileURLWithPath:path];
}

-(NSString*)documentDirectoryPathForResource:(NSString*)aFileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    
    NSString *fullPath = [[paths lastObject] stringByAppendingPathComponent:aFileName];
    return fullPath;
}
+ (BOOL)canPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}
- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    [Utilities removeFilesFromPaths:self.allAttachments];
}
#pragma mark - QLPreviewControllerDelegate
- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return NO;
}
//- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView **)view {
//
//}
#pragma mark - user Actions
-(IBAction)btnNaviClockAction:(id)sender {
    [self showSubView];
}
-(IBAction)btnFavoriteAction:(id)sender {
    if (self.object == nil) {
        self.object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
    }
    if ([[self.object valueForKey:kIS_FAVORITE] boolValue]) {
        [self showToastWithMessage:@"✰✰ Already Marked Favorite ✰✰"];
    }
    else {
        long uid = [[self.object valueForKey:kUSER_ID] integerValue];
        NSString * mail = [Utilities getEmailForId:[NSString stringWithFormat:@"%ld",uid]];
        NSString * stringUid = [Utilities getStringFromLong:uid];
        NSMutableDictionary * dictionary = [Utilities getDictionaryFromObject:self.object email:mail isThread:YES dictionaryType:kTypeFavorite nsdate:0];
        [Utilities syncToFirebase:dictionary syncType:[FavoriteEmailSyncManager class] userId:stringUid performAction:kActionInsert firebaseId:nil];
        [self showToastWithMessage:@"✰✰ Favorite Marked ✰✰"];
    }
}
-(IBAction)btnReplyAction:(id)sender {
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
    
    MCOIMAPMessage * message = [Utilities getUnArchivedArrayForObject:[object valueForKey:kMESSAGE_INSTANCE]];
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
        NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
        [self openComposerWithMessageType:kReply quickResponseObject:nil manageObject:object];
    }
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
-(IBAction)btnArchiveAction:(id)sender {
    if (self.folderType == kFolderArchiveMail) {
        [self moveToFolder:kFOLDER_INBOX];
    }
    else {
        [self archiveEmails];
    }
}
-(IBAction)btnForwardAction:(id)sender {
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
    [self openComposerWithMessageType:kForward quickResponseObject:nil manageObject:object];
}
#pragma - mark UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag == 101) { /* delete action sheet */
        if (buttonIndex == 0) { /* Delete button */
            if (self.folderType == kFolderTrashMail) {
                [self deleteFromTrash:nil];
            }
            else {
                [self moveToFolder:kFOLDER_TRASH_MAILS];
            }
        }
        else { /* Cancel button */
        }
    }
    else { /* reply action sheet */
        NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
        if (buttonIndex == 0) { /* Reply button */
            [self openComposerWithMessageType:kReply quickResponseObject:nil manageObject:object];
        }
        else if(buttonIndex == 1) { /* ReplyAll button */
            [self openComposerWithMessageType:kReplyAll quickResponseObject:nil manageObject:object];
        }
    }
}

-(IBAction)btnQuickResponseAction:(id)sender {
    [self.threadTableView reloadData];
    [self.view endEditing:YES];
    quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
    [snoozeView setDataSource:quickResponses];
    [snoozeView setUserId:quickResponseUserId email:currentEmail];
    [snoozeView setButtonTitles:@"Customize" buttonTitle2:@"Cancel"];
    [snoozeView setTableViewType:2];
    [snoozeView setTableViewCellHeight:44.5f];
    [snoozeView setViewXvalue:92.5f];
    [snoozeView setViewTitle:@"Quick Response"];
    [snoozeView setViewHeight:354.5f screenHeight:self.view.frame.size.height];
    [self.view addSubview:snoozeView];
    snoozeView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:snoozeView forParent:self.view topValue:0.0f];
}
-(IBAction)btnQuickBarActions:(id)sender {
    UIButton * btn = (UIButton *)sender;
    NSManagedObject * object = nil;
    if (btn.tag == 101) {
        if (quickResponses.count>=1) {
            object  = [quickResponses objectAtIndex:0];
            //NSString * strQ1 = [object valueForKey:kQUICK_REPONSE_Text];
        }
    }
    else if (btn.tag == 102) {
        if (quickResponses.count>=2) {
            object  = [quickResponses objectAtIndex:1];
            //NSString * strQ2 = [object valueForKey:kQUICK_REPONSE_Text];
        }
    }
    else {
        if (quickResponses.count>=3) {
            object  = [quickResponses objectAtIndex:2];
            //NSString * strQ3 = [object valueForKey:kQUICK_REPONSE_Text];
        }
    }
    NSManagedObject * mailobject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
    [self openComposerWithMessageType:kReply quickResponseObject:object manageObject:mailobject];
    
}
#pragma mark - SnoozeViewDelegate

- (void) snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply {
    if (viewType == 2) {
        ComposeQuickResponseViewController * composeQuickResponseViewController = [[ComposeQuickResponseViewController alloc] initWithNibName:@"ComposeQuickResponseViewController" bundle:nil];
        [self.navigationController pushViewController:composeQuickResponseViewController animated:YES];
    }
    else if (viewType == 1) {
        snoozedOnlyIfNoReply = ifNoReply;
        CustomizeSnoozesViewController * customizeSnoozesViewController = [[CustomizeSnoozesViewController alloc] initWithNibName:@"CustomizeSnoozesViewController" bundle:nil];
        [self.navigationController pushViewController:customizeSnoozesViewController animated:YES];
    }
}
//- (void) snoozeView:(SnoozeView *)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
//    if (quickResponses) {
//        quickResponses = nil;
//        quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
//        if (Index<=quickResponses.count-1) {
//            NSManagedObject * object = [quickResponses objectAtIndex:Index];
//            NSManagedObject * mailobject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
//            [self openComposerWithMessageType:kReply quickResponseObject:object manageObject:mailobject];
//        }
//    }
//}
- (void) snoozeView:(SnoozeView*)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
    if ([view getTableViewType] == 1) {
        changeNotifier = NO;
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
        [Utilities calculateDateWithHours:hour minutes:minutes preferenceId:preferenceId currentEmail:currentEmail userId:[Utilities getStringFromLong:userId] emailData:self.object onlyIfNoReply:snoozedOnlyIfNoReply viewType:[view getTableViewType]];
        [self btnBackAction:nil];
    }
    else {
        if (quickResponses) {
            quickResponses = nil;
            quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
            if (Index<=quickResponses.count-1) {
                NSManagedObject * object = [quickResponses objectAtIndex:Index];
                NSManagedObject * mailobject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]];
                [self openComposerWithMessageType:kReply quickResponseObject:object manageObject:mailobject];
            }
        }
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
    changeNotifier = NO;
    [Utilities setEmailToSnoozeTill:date withObject:self.object currentEmail:currentEmail onlyIfNoReply:snoozedOnlyIfNoReply userId:[Utilities getStringFromLong:userId]];
    [self btnBackAction:nil];
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    /* id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
     NSInteger rowCount = [sectionInfo numberOfObjects];
     if (rowCount>0) {
     return [sectionInfo numberOfObjects] + 1;
     }*/
    if (section>self.fetchedResultsController.fetchedObjects.count-1) {
        return 1;
    }
    NSIndexPath * path = [NSIndexPath indexPathForRow:section inSection:0];
    NSManagedObject * object = [self.fetchedResultsController objectAtIndexPath:path];
    uint64_t uniqueId = [[object valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
    NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
    if (array == nil) {
        return 1;
    }
    return array.count + 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section>self.fetchedResultsController.fetchedObjects.count-1) {
        static NSString *tableIdentifier = @"QuickReply";
        QuickReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"QuickReplyCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.container.layer.borderColor = [UIColor colorWithRed:228.0f/255.0f green:228.0f/255.0f blue:228.0f/255.0f alpha:1.0].CGColor;
        cell.container.layer.borderWidth = 0.5f;
        cell.container.layer.cornerRadius = 5.0f;
        cell.container.layer.masksToBounds = YES;
        [cell.btnMore addTarget:self action:@selector(btnQuickResponseAction:) forControlEvents:UIControlEventTouchUpInside];
        NSString * strQ1 = @"";
        NSString * strQ2 = @"";
        NSString * strQ3 = @"";
        quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
        if (quickResponses.count>=1) {
            NSManagedObject * object1  = [quickResponses objectAtIndex:0];
            strQ1 = [object1 valueForKey:kQUICK_REPONSE_Text];
            [cell.btnQR1 addTarget:self action:@selector(btnQuickBarActions:) forControlEvents:UIControlEventTouchUpInside];
            if (quickResponses.count>=2) {
                NSManagedObject * object2  = [quickResponses objectAtIndex:1];
                strQ2 = [object2 valueForKey:kQUICK_REPONSE_Text];
                [cell.btnQR2 addTarget:self action:@selector(btnQuickBarActions:) forControlEvents:UIControlEventTouchUpInside];
                if (quickResponses.count>=3) {
                    NSManagedObject * object3  = [quickResponses objectAtIndex:2];
                    strQ3 = [object3 valueForKey:kQUICK_REPONSE_Text];
                    [cell.btnQR3 addTarget:self action:@selector(btnQuickBarActions:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        
        [cell.btnQR1 setTitle:strQ1 forState:UIControlStateNormal];
        [cell.btnQR2 setTitle:strQ2 forState:UIControlStateNormal];
        [cell.btnQR3 setTitle:strQ3 forState:UIControlStateNormal];
        cell.btnQR1.tag = 101;
        cell.btnQR2.tag = 102;
        cell.btnQR3.tag = 103;
        return cell;
    }
    if (indexPath.row == 0) {
        static NSString *tableIdentifier = @"GroupCell";
       
        MessageGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MessageGroupCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        
        uint64_t uniqueId = [[emailData valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
        if (array.count>0) {
            cell.bottomBar.constant = 0.0f;
        }
        else {
            cell.bottomBar.constant = 10.0f;
        }
        MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[emailData valueForKey:kMESSAGE_INSTANCE]];
        MCOAddress * mcoAddress = message.header.from;
        NSString * name = mcoAddress.displayName;
        if (![Utilities isValidString:name]) { // if sender name nil, set sender email as name
            name = [emailData valueForKey:kEMAIL_TITLE];
        }
        cell.lblTitle.text = name;
        cell.lblDate.text = [Utilities getEmailStringDateForDetailView:[emailData valueForKey:kEMAIL_DATE]];
        NSString * emailPreview = [emailData valueForKey:kEMAIL_HTML_PREVIEW];
        NSString * messageId = [emailData valueForKey:kEMAIL_ID];
        cell.tag = messageId.integerValue;
        NSString * folderName = [emailData valueForKey:kMAIL_FOLDER];
        NSString * strTag = [NSString stringWithFormat:@"%ld",(long)indexPath.section];
        NSString * plainString = [emailData valueForKey:kEMAIL_PREVIEW];
        if (![Utilities isValidString:plainString]) {
            cell.lblPreview.text = @" ";
            if (contentFetchManager == nil) {
                [self initBodyFetchManager];
            }
            [contentFetchManager startFetchOpWithFolder:folderName andMessageId:[messageId intValue] forNSManagedObject:emailData nsindexPath:path needHtml:NO];
        }
        else {
            cell.lblPreview.text = plainString;
        }
        NSString * cellState = [cellStates objectForKey:strTag];
        if ([Utilities isValidString:emailPreview]) {
            cell.lblHtmlView.scalesPageToFit = YES;
            cell.lblHtmlView.contentMode = UIViewContentModeScaleAspectFit;
            //[cell.lblHtmlView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
            [cell.lblHtmlView loadHTMLString:emailPreview baseURL:nil];
            cell.lblHtmlView.dataDetectorTypes = UIDataDetectorTypeAll;
            cell.lblHtmlView.delegate = self;
            cell.lblHtmlView.tag = indexPath.section;
            cell.lblHtmlView.scrollView.bounces = NO;
            cell.lblHtmlView.scrollView.scrollEnabled = NO;
            cell.activityContainer.tag = indexPath.section + 2000;
            cell.tag = indexPath.section + 1000;
            //[cell.activityIndicator stopAnimating];
            //[cell.activityContainer setHidden:YES];
        }
        else {// get message preview if not available in db
            //cell.lblPreview.text = @" ";
            if (contentFetchManager == nil) {
                [self initBodyFetchManager];
            }
            [contentFetchManager startFetchOpWithFolder:folderName andMessageId:[messageId intValue] forNSManagedObject:emailData nsindexPath:path needHtml:YES];
        }
        cell.btnDetail.tag = indexPath.section;
        cell.btnMore.tag = indexPath.section;
        [cell.btnDetail addTarget:self action:@selector(btnDetailAction:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnMore addTarget:self action:@selector(btnMoreAction:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        if (cellState != nil) {
            if ([cellState isEqualToString:@"1"]) { /* open full cell */
                [cell.lblPreview setHidden:YES];
                [cell.lblHtmlView setHidden:NO];
                [cell.btnDetail setHidden:NO];
                [cell.lblDate setHidden:NO];
                [cell.btnMore setHidden:NO];
            }
            else { /* need tap to open  */
                [cell.lblHtmlView setHidden:YES];
                [cell.lblPreview setHidden:NO];
                [cell.btnDetail setHidden:YES];
                [cell.lblDate setHidden:YES];
                [cell.btnMore setHidden:YES];
            }
        }
        else { /* open full cell */
            [cell.lblHtmlView setHidden:NO];
            [cell.lblPreview setHidden:YES];
            [cell.btnDetail setHidden:NO];
            [cell.lblDate setHidden:NO];
            [cell.btnMore setHidden:NO];
        }
        [cell.btnMore setHidden:YES];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleTap:)];
        [cell addGestureRecognizer:tap];
        cell.userInteractionEnabled = YES;
        cell.tag = indexPath.section;
        [[cell contentView] setBackgroundColor:[UIColor clearColor]];
        [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setNeedsUpdateConstraints];
        [cell layoutIfNeeded];
        return  cell;
    }
    
    NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
    NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
    uint64_t uniqueId = [[emailData valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
    NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
    static NSString *tableIdentifier = @"FileAttachmentCell";
    
    FileAttachmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FileAttachmentTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.viewSep.hidden = YES;
    if (indexPath.row == array.count) {
        //cell.viewSep.hidden = YES;
        cell.viewSep1.hidden = NO;
    }
    else {
        //cell.viewSep.hidden = NO;
        cell.viewSep1.hidden = YES;
    }
    id object = [array objectAtIndex:indexPath.row-1];
    if ([object isKindOfClass:[MCOAttachment class]]) {
        [cell.activityIndicator stopAnimating];
        [cell.arrowView setHidden:NO];
    }
    else {
        [cell.arrowView setHidden:YES];
        [cell.activityIndicator startAnimating];
    }
    MCOAttachment * attachment = (MCOAttachment *)object;
    cell.imgFile.image = [UIImage imageNamed:[Utilities getImageNameForMimeType:attachment.mimeType]];
    cell.lblFileName.text = attachment.filename;
    [cell.btnRemoveAttachment setHidden:YES];
    [[cell contentView] setBackgroundColor:[UIColor clearColor]];
    [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat value = 90.0f;
    NSString * strTag = [NSString stringWithFormat:@"%ld",(long)indexPath.section];
    NSString * height = [heightDictionary objectForKey:strTag];
    
    if (indexPath.section == self.fetchedResultsController.fetchedObjects.count-1) { /* open last row by default */
        if (indexPath.row == 0) {
            if (height != nil) {
                NSInteger ht = [height integerValue];
                [cellStates setObject:@"1" forKey:strTag];
                return ht;
            }
            return value;
        }
        
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        uint64_t uniqueId = [[emailData valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
        if (indexPath.row == array.count) {
            return 54.0f;
        }
        return 44.0f;
    }
    else if (indexPath.section > self.fetchedResultsController.fetchedObjects.count-1) { /* Quick reply cell height */
        return 60.0f;
    }
    else {
        if (indexPath.row == 0) {
            NSString * cellState = [cellStates objectForKey:strTag];
            if (cellState != nil) {
                if ([cellState isEqualToString:@"1"]) { /* open full cell */
                    if (height != nil) {
                        NSInteger ht = [height integerValue];
                        return ht;
                    }
                    return value;
                }
                else { /* need tap to open  */
                    return value;
                }
            }
            else {
                [cellStates setObject:@"0" forKey:strTag];
            }
        }
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        uint64_t uniqueId = [[emailData valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
        if (indexPath.row == array.count) {
            return 54.0f;
        }
        return 44.0f;
    }
    return value;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    NSInteger rowCount = [sectionInfo numberOfObjects];
    if (rowCount>0) {
        return rowCount + 1;
    }
    return 0;
}

#pragma - mark UITableView delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section<self.fetchedResultsController.fetchedObjects.count) {
        NSIndexPath * path = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
        NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:path];
        uint64_t uniqueId = [[emailData valueForKey:kEMAIL_UNIQUE_ID] longLongValue];
        NSMutableArray * array = [self.attachmentDictionary objectForKey:[NSString stringWithFormat:@"%llu",uniqueId]];
        id test =  [array objectAtIndex:indexPath.row-1];
        if ([test isKindOfClass:[MCOAttachment class]]) { // attachment dowloaded
            NSLog(@"MCOAttachment class");
            self.allAttachments = [Utilities saveAttachmentsToTempPath:array];
            [self openQLPreviewControllerWithIndex:indexPath.row-1];
        }
    }
    
    /*NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
     EmailDetailViewController * emailDetailViewController = [[EmailDetailViewController alloc] initWithNibName:@"EmailDetailViewController" bundle:nil];
     emailDetailViewController.isViewPresented = NO;
     emailDetailViewController.modelEmail = [Utilities parseEmailModelForDBdata:managedObject];
     emailDetailViewController.object = managedObject;
     [self.navigationController pushViewController:emailDetailViewController animated:YES];*/
}

-(void)updateResponseList {
    [self.threadTableView reloadData];
}
-(void)btnMoreAction:(UIButton *)sender withEvent:(UIEvent *)event {
    UIButton * btn = (UIButton *)sender;
    if([moreActionView isDescendantOfView:self.view]) {
        [moreActionView hideView];
    }
    else {
        UITouch *touch = [[event allTouches] anyObject];
        CGFloat yInButton = [touch locationInView:btn].y;
        CGFloat yInView = [touch locationInView:self.view].y;
        CGFloat detailButtonY = yInView - yInButton;
        
        if (btn.tag<=self.fetchedResultsController.fetchedObjects.count-1 || btn.tag == 1000) {
            moreActionView = [[[NSBundle mainBundle] loadNibNamed:@"MoreActionView" owner:self options:nil] objectAtIndex:0];
            moreActionView.folderType = self.folderType;
            [moreActionView setupView];
            moreActionView.delegate = self;
            if (btn.tag == 1000) {
                [moreActionView viewType:kMORE_VIEW_TYPE_THRD];
            }
            else {
                [moreActionView viewType:kMORE_VIEW_TYPE_MSG];
            }
            if (btn.tag<=self.fetchedResultsController.fetchedObjects.count-1) {
                NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:btn.tag]];
                actionObjectID = emailData.objectID;
            }
            [moreActionView setViewPosition:detailButtonY screenHeight:screenHeight];
            [self.view addSubview:moreActionView];
            moreActionView.translatesAutoresizingMaskIntoConstraints = NO;
            [Utilities setLayoutConstarintsForView:moreActionView forParent:self.view topValue:0.0f];
        }
    }
}
-(void)btnDetailAction:(UIButton *)sender withEvent:(UIEvent *)event {
    UIButton * btn = (UIButton *)sender;
    if([messageDetailView isDescendantOfView:self.view]) {
        [messageDetailView hideView];
    }
    else {
        UITouch *touch = [[event allTouches] anyObject];
        CGFloat yInButton = [touch locationInView:btn].y;
        CGFloat yInView = [touch locationInView:self.view].y;
        CGFloat detailButtonY = yInView - yInButton;
        if (btn.tag<=self.fetchedResultsController.fetchedObjects.count-1) {
            messageDetailView = [[[NSBundle mainBundle] loadNibNamed:@"MessageDetailView" owner:self options:nil] objectAtIndex:0];
            [messageDetailView setDelegate:self];
            NSManagedObject *emailData = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:btn.tag inSection:0]];
            
            messageDetailView.dataArray = [Utilities fillArrayForMessageDetail:emailData];
            messageDetailView.date = [emailData valueForKey:kEMAIL_DATE];
            messageDetailView.profileImageUrl = [emailData valueForKey:kSENDER_IMAGE_URL];
            [messageDetailView setupView];
            [messageDetailView setViewPosition:detailButtonY screenHeight:screenHeight];
            [self.view addSubview:messageDetailView];
            messageDetailView.translatesAutoresizingMaskIntoConstraints = NO;
            [Utilities setLayoutConstarintsForView:messageDetailView forParent:self.view topValue:0.0f];
        }
    }
}

#pragma - mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    //NSLog(@"delegate call webview tag = %ld",(long)theWebView.tag);
    
    //    if (theWebView.isLoading)
    //        return;
    
    //[self readyState:[theWebView stringByEvaluatingJavaScriptFromString:@"document.readyState"] webview:theWebView];
    [self setZoomLevelForWebview:theWebView];
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    else if (navigationType == UIWebViewNavigationTypeOther) {
        return YES;
    }
    return YES;
}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    NSInteger tag = recognizer.view.tag;
    if (tag == self.fetchedResultsController.fetchedObjects.count-1) {
        return;
    }
    NSString * strTag = [NSString stringWithFormat:@"%ld",(long)tag];
    NSString * state = [cellStates objectForKey:strTag];
    if ([state isEqualToString:@"1"]) {
        [cellStates setObject:@"0" forKey:strTag];
    }
    else {
        [cellStates setObject:@"1" forKey:strTag];
    }
    [Utilities reloadTableViewRows:self.threadTableView forIndexArray:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:tag]] withAnimation:UITableViewRowAnimationFade];
}
- (IBAction)buttonPressed:(id)sender forEvent:(UIEvent*)event {
    UIView *button = (UIView *)sender;
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint location = [touch locationInView:button];
    NSLog(@"Location in button: %f, %f", location.x, location.y);
}
-(void)setZoomLevelForWebview:(UIWebView *)webView {
    //CGSize contentSize = webView.scrollView.contentSize;
    //CGSize viewSize = webView.bounds.size;
    //float rw = viewSize.width / contentSize.width;
    
    //webView.scrollView.minimumZoomScale = rw;
    //webView.scrollView.maximumZoomScale = rw;
    //webView.scrollView.zoomScale = rw;
    
    const int additionalHeight = 86; /* THIS HEIGHT IS FOR TOP VIEW IN CELL */
    
    CGSize contentSize2 = webView.scrollView.contentSize;
    NSString * strTag = [NSString stringWithFormat:@"%ld",(long)webView.tag];
    NSString * strHieght = [heightDictionary objectForKey:strTag];
    NSString * height = [NSString stringWithFormat:@"%ld",(long)contentSize2.height + additionalHeight];
    if (strHieght == nil) {
        //height = [NSString stringWithFormat:@"%ld",(long)contentSize2.height + additionalHeight];
        [heightDictionary setObject:height forKey:strTag];
        if (webView.tag<=self.fetchedResultsController.fetchedObjects.count-1) {
            [Utilities reloadTableViewRows:self.threadTableView forIndexArray:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:webView.tag]] withAnimation:UITableViewRowAnimationNone];
        }
    }
    else {
        
        long diff = [height integerValue] - [strHieght integerValue];
        
        if (diff > 10) {
            //height = [NSString stringWithFormat:@"%ld",(long)contentSize2.height + additionalHeight];
            [heightDictionary setObject:height forKey:strTag];
            if (webView.tag<=self.fetchedResultsController.fetchedObjects.count-1) {
                [Utilities reloadTableViewRows:self.threadTableView forIndexArray:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:webView.tag]] withAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}
- (void)readyState:(NSString *)str webview:(UIWebView *)webview
{ //NSLog(@"str:%@",str);
    
    if ([str isEqualToString:@"complete"]||[str isEqualToString:@"interactive"]) {
        //NSLog(@"IT HAS BEEN DONE");
        //[self setZoomLevelForWebview:webview];
        [webview setHidden:NO];
        //[pageLoadingActivityIndicator stopAnimating];
    }
}
#pragma - mark User Actions
-(IBAction)btnBackAction:(id)sender {
    
    [self unloadVisibleCell];
    
    if(contentFetchManager) {
        contentFetchManager.delegate = nil;
        contentFetchManager = nil;
    }
    
    if (sender != nil) {
        if (self.isViewPresented) {
            [self dismissPresentedView];
        }
        else {
            [[self navigationController] popViewControllerAnimated:YES];
        }
        return;
    }
    [UIView animateWithDuration:0.6
                     animations:^{
                         self.threadTableView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                     }
                     completion:^(BOOL finished) {
                     }];
    self.contraintTableTop.constant = screenHeight;
    [self.view.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.7f animations:^{
        [self.view.superview layoutIfNeeded];
    }completion:^(BOOL finished) {
        if (self.isViewPresented) {
            [self dismissPresentedView];
        }
        else {
            [[self navigationController] popViewControllerAnimated:NO];
        }
    }];
    
    return;
    
    self.contraintTableTrailing.constant = screenWidth/2;
    self.contraintTableLeading.constant = screenWidth/2;
    self.contraintTableTop.constant = screenHeight;
    [self.view.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.75f animations:^{
        [self.view.superview layoutIfNeeded];
    }];
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.6;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromBottom; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
    return;
    [UIView animateWithDuration:0.75
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:NO];
                     }];
    [self.navigationController popViewControllerAnimated:NO];
    
    return;
    //Init Animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.50];
    
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.navigationController.view cache:YES];
    
    //Create ViewController
    [[self navigationController] popViewControllerAnimated:NO];
    //Start Animation
    [UIView commitAnimations];
}
-(void)moveSnoozeToInbox {
    NSMutableArray * emailIdArray = [CoreDataManager getEmailsForThreadId:[threadId longLongValue] andUserId:userId folderType:[Utilities getFolderTypeForString:[self.object valueForKey:kMAIL_FOLDER]] needOnlyIds:NO entity:entityName];
    
    for (NSManagedObject * obj in emailIdArray) {
        [self syncDeleteActionToFirebaseWithObject:obj];
    }
}
-(void)deleteFromTrash:(NSManagedObject *)object {
    
    if (![Utilities isInternetActive]) {
        return;
    }
    changeNotifier = NO;
    MCOIndexSet * finalIndexSet = [[MCOIndexSet alloc] init];
    NSMutableArray * emailIdArray = nil;
    NSManagedObject * obje = nil;
    if (object == nil) {
        emailIdArray = [CoreDataManager fetchEmailsForThreadId:[threadId longLongValue] andUserId:userId folderType:[Utilities getFolderTypeForString:kFOLDER_TRASH_MAILS] needOnlyIds:NO isSnoozed:NO entity:entityName];
        if (emailIdArray.count<=0) {
            return;
        }
        obje = [emailIdArray objectAtIndex:0];
        
        for (NSManagedObject * obj in emailIdArray) {
            long idsz = [[obj valueForKey:kEMAIL_ID] longLongValue];
            [finalIndexSet addIndex:idsz];
        }
    }
    else {
        obje = object;
        long idsz = [[obje valueForKey:kEMAIL_ID] longLongValue];
        [finalIndexSet addIndex:idsz];
        emailIdArray = [[NSMutableArray alloc] initWithObjects:obje, nil];
    }
    if (finalIndexSet.count == 0) {
        return;
    }
    long longUserId = [[obje valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:longUserId];
    NSArray * array =  [Utilities getIndexSetFromObject:obje];
    NSString * folderName = [array objectAtIndex:0];
    MCOMessageFlag newflags = MCOMessageFlagDraft;
    
    newflags |= MCOMessageFlagDeleted;
    newflags |= !MCOMessageFlagFlagged;
    
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
    if (imapSession != nil) {
        for (NSManagedObject * obj in emailIdArray) {
            [obj setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
        }
        [CoreDataManager updateData];
        MCOIMAPOperation *changeFlags = [imapSession  storeFlagsOperationWithFolder:folderName  uids:finalIndexSet kind:MCOIMAPStoreFlagsRequestKindSet flags:newflags];
        [changeFlags start:^(NSError *error) {
            if (!error) {
                if (object != nil) {
                    NSMutableArray * thread = [CoreDataManager fetchEmailsForThreadId:[threadId longLongValue] andUserId:userId folderType:[Utilities getFolderTypeForString:kFOLDER_TRASH_MAILS] needOnlyIds:NO isSnoozed:NO entity:entityName];
                    if (thread.count>0) {
                        if (thread.count == 1) { /* delete from firebase only if single email*/
                            [self syncDeleteActionToFirebaseWithObject:object];
                        }
                        
                        NSMutableArray * array = [CoreDataManager fetchTopEmailForThreadId:[threadId longLongValue] andUserId:longUserId isTopEmail:YES isTrash:NO entity:entityName];
                        if (array.count>0) {
                            NSManagedObject *obj = [array lastObject];
                            [obj setValue:[NSNumber numberWithBool:NO] forKey:kIS_THREAD_TOP_EMAIL];
                            [CoreDataManager updateData];
                        }
                    }
                }
                for (NSManagedObject * obj in emailIdArray) {
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
                for (NSManagedObject * obj in emailIdArray) {
                    [obj setValue:[NSNumber numberWithBool:NO] forKey:kHIDE_EMAIL];
                }
                [CoreDataManager updateData];
            }
        }];
        [self btnBackAction:nil];
    }
}
#pragma mark - MoveViewDelegate
- (void)actionIndexString:(NSString *)string {
    if ([string isEqualToString:@"Inbox"]) {
        NSLog(@"INBOX");
        if (self.folderType == kFolderSnoozeMail) {
            [self moveSnoozeToInbox];
        }
        else if (self.folderType == kFolderArchiveMail || self.folderType == kFolderTrashMail) {
            [self moveToFolder:kFOLDER_INBOX];
        }
    }
    else if ([string isEqualToString:@"Spam"]) {
        NSLog(@"SPAM");
        [self moveToFolder:kFOLDER_SPAM];
    }
    else if ([string isEqualToString:@"Trash"]) {
        NSLog(@"TRASH");
        [self moveToFolder:kFOLDER_TRASH_MAILS];
    }
    else if ([string isEqualToString:@"Starred"]) {
        NSLog(@"STARRED");
        [self markMessages];
    }
    else if ([string isEqualToString:@"Important"]) {
        NSLog(@"IMPORTANT");
        [self moveToFolder:@"[Gmail]/Important"];
    }
}
#pragma mark - MoreActionViewDelegate
- (void)buttonTapped:(int)btnIndex onView:(int)viewType {
    if (viewType == kMORE_VIEW_TYPE_THRD) {
        /* COMPLETE THREAD MORE_VIEW
         Move.tag = 101;
         Delete.tag = 102;
         Print.tag = 103;
         Spam.tag.tag = 104;
         View Detail.tag = 105; */
        
        if (btnIndex == 101) {
            NSLog(@"Move");
            moveView = [[[NSBundle mainBundle] loadNibNamed:@"MoveView" owner:self options:nil] objectAtIndex:0];
            moveView.delegate = self;
            moveView.folderType = self.folderType;
            [moveView setupView];
            [self.view addSubview:moveView];
            moveView.translatesAutoresizingMaskIntoConstraints = NO;
            [Utilities setLayoutConstarintsForView:moveView forParent:self.view topValue:0.0f];
        }
        else if (btnIndex == 102) {
            NSLog(@"Delete");
            if (self.folderType == kFolderTrashMail) {
                [self deleteFromTrash:nil];
            }
            else {
                [self moveToFolder:kFOLDER_TRASH_MAILS];
            }
        }
        else if (btnIndex == 103) {
            NSLog(@"Print");
        }
        else if (btnIndex == 104) {
            NSLog(@"Spam");
            [self moveToFolder:kFOLDER_SPAM];
        }
        else {
            NSLog(@"Detail");
        }
    }
    else {
        /* MESSAGE MORE_VIEW
         Reply.tag = 201;
         Forward.tag = 202;
         Print.tag = 203;
         Delete.tag = 204; */
        NSManagedObjectContext * context = [CoreDataManager getManagedObjectContext];
        NSManagedObject * obj = [context objectWithID:actionObjectID];
        if (obj == nil) {
            return;
        }
        if (btnIndex == 201) {
            NSLog(@"Reply");
            [self openComposerWithMessageType:kReply quickResponseObject:nil manageObject:obj];
        }
        else if (btnIndex == 202) {
            NSLog(@"Forward");
            [self openComposerWithMessageType:kForward quickResponseObject:nil manageObject:obj];
        }
        else if (btnIndex == 203) {
            NSLog(@"Print");
        }
        else {
            NSLog(@"Delete");
            if (self.folderType == kFolderTrashMail) {
                [self deleteFromTrash:obj];
            }
            else {
                [self deleteEmail:obj];
            }
        }
    }
}
#pragma mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *obj = [self.fetchedResultsController objectAtIndexPath:indexPath];
    /*[obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_BODY];
     
     if ([messagePreview length]>=50) {
     messagePreview = [messagePreview substringToIndex:50];
     }
     
     [obj setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];*/
    [obj setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    [CoreDataManager updateData];
    [self hideProgressHud];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    [self hideProgressHud];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    if (self.object != nil) {
        NSString * emailPreview = [self.object valueForKey:kEMAIL_HTML_PREVIEW];
        if (![Utilities isValidString:emailPreview]) {
            NSString * messageId = [self.object valueForKey:kEMAIL_ID];
            NSString * folderName = [self.object valueForKey:kMAIL_FOLDER];
            [contentFetchManager startFetchOpWithFolder:folderName andMessageId:[messageId intValue] forNSManagedObject:self.object nsindexPath:nil needHtml:YES];
        }
        else {
            [self hideProgressHud];
        }
        [self.threadTableView reloadData];
    }
}

#pragma - mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.threadTableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.row];
    newIndexPath = [NSIndexPath indexPathForRow:0 inSection:newIndexPath.row];
    NSLog(@"new indexPath: section :%ld, row: %ld",(long)newIndexPath.section, (long)newIndexPath.row);
    NSLog(@"indexPath: section :%ld, row: %ld",(long)indexPath.section, (long)indexPath.row);
    UITableView *tableView = self.threadTableView;
    
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
            [self.threadTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.threadTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.threadTableView endUpdates];
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedSuccessfullyWithObject:(MCOIMAPSession *)imapSession {
    if (self.isViewPresented) {
        [self fetchEmailFromServerWithSession:imapSession];
        return;
    }
}
-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager didReceiveError:(NSError *)error {
    [self hideProgressHud];
}
#pragma mark - MessageDetailViewDelegate
- (void)messageDetailViewDidRemoveFromSuperView {
    messageDetailView = nil;
}
-(void)dealloc {
    if (snoozeView) {
        snoozeView.delegate = nil;
        snoozeView = nil;
    }
    if (moreActionView) {
        moreActionView.delegate = nil;
        moreActionView = nil;
    }
    if (moveView) {
        moveView.delegate = nil;
        moveView = nil;
    }
    if (contentFetchManager) {
        contentFetchManager.delegate = nil;
        contentFetchManager = nil;
    }
    if (messageDetailView) {
        messageDetailView.delegate = nil;
        messageDetailView = nil;
    }
    if (imapSessionManager) {
        imapSessionManager.delegate = nil;
        imapSessionManager = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kATTACHMENT_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNEW_EMAIL_NOTIFICATION object:nil];
    NSLog(@"dealloc : MailThreadViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
