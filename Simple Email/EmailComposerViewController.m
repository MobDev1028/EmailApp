//
//  EmailComposerViewController.m
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "EmailComposerViewController.h"

#import "CLToken.h"
#import "Utilities.h"
#import "Constants.h"
#import "SnoozeView.h"
#import "MBProgressHUD.h"
#import "SendMessageManager.h"
#import "CustomKeyBoardToolBar.h"
#import "SWRevealViewController.h"
#import "SideMenuViewController.h"
#import "MailCoreServiceManager.h"
#import "TextEditorViewController.h"
#import "QuickResponseViewController.h"
#import "CustomizeSendLaterViewController.h"
#import "ComposeQuickResponseViewController.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "FileAttachmentTableViewCell.h"
#import "AttachmentViewerViewController.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AutocompleteCell.h"
#import "SharedInstanceManager.h"
#import "UtilityImapSessionManager.h"
#import "DatePickerView.h"
#import "WebServiceManager.h"

@interface EmailComposerViewController ()

@end

@implementation EmailComposerViewController {
    NSString *body;
    long currentTag;
    NSString * name;
    NSString * userId;
    MBProgressHUD *hud;
    SnoozeView *snoozeView;
    NSString * emailString;
    NSString * currentEmail;
    NSArray * quickResponses;
    BOOL isViewDismissed;
    SendMessageManager * sendMessage;
    TextEditorViewController * textEditor;
    MCOIMAPSessionManager * imapSessionManager;
    //CustomKeyBoardToolBar *customKeyBoardToolBar;
    MCOIMAPFetchContentOperationManager * contentFetchManager;
    double totalAttachmentSize;
    double ccViewLastHeight;
    double toViewLastHeight;
    BOOL isCcViewHidden;
    BOOL isViewDidAppearCalled;
    BOOL isSentRequestMade;
    int quickResponseBottom;
    BOOL isAdditionalHeightAdded;
    CGFloat viewHeight;
    BOOL isAutoCompleteForAccountsList;
    NSMutableArray * dataArray;
    long cloneId;
    DatePickerView * datePickerView;
    NSURL * coreDataObjectId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    cloneId = -1;
    isViewDismissed = NO;
    isViewDidAppearCalled = NO;
    isSentRequestMade = NO;
    isAutoCompleteForAccountsList = NO;
    [self.attachmentView setHidden:YES];
    [self.webView setHidden:YES];
    totalAttachmentSize = 0.0;
    quickResponseBottom = 50;
    self.scrollView.delegate = self;
    [self createSession];
    [self setUpView];
    [self setUpTokenView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView:) name:kATTACHMENT_DOWNLOADED object:nil];
    /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
     if (!self.tokenInputView.editing) {
     [self.tokenInputView beginEditing];
     }
     });
     
     [[NSNotificationCenter defaultCenter]addObserver:self
     selector:@selector(saveDraft)
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];*/
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(scrollToBottom)
                                                name:kEDITOR_ACTIVE
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openSendLaterMenu:)
                                                 name:kNOTIFICATION_SEND_LATER object:nil];
}
- (void)openSendLaterMenu:(NSNotification *)note {
    [self customKeyBoardSendLaterDelegate];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isViewDidAppearCalled == NO) {
        ccViewLastHeight = 0.0f;
        toViewLastHeight = 54.0f;
        CGFloat toViewHeight = self.toView.frame.size.height;
        
        if (toViewHeight>54.0f) {
            toViewLastHeight = toViewHeight;
            [self setScrollViewConstant:containerViewHeight.constant + (toViewHeight-54)];
        }
        [self.containerView removeConstraint:editorHeight];
        editorHeight = [NSLayoutConstraint constraintWithItem:textEditor.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.textEditorContainerView.frame.size.height];
        [self.containerView addConstraint:editorHeight];
        [self.containerView layoutIfNeeded];
        isCcViewHidden = YES;
        isViewDidAppearCalled = YES;
    }
    viewHeight = self.view.frame.size.height;
}
#pragma mark - QLPreviewControllerDatasource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.attachmentsTempUrl.count;
}
- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    NSString *path = [self documentDirectoryPathForResource:self.attachmentsTempUrl[index]];
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
    [Utilities removeFilesFromPaths:self.attachmentsTempUrl];
}
#pragma mark - QLPreviewControllerDelegate
- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return NO;
}
//- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView **)view {
//
//}
#pragma - mark Private Methods
- (IBAction)fromFieldTap:(id)sender {
    [self showUsersList];
}
- (void)showUsersList {
    [self.autoCompleteTableView setHidden:YES];
    [self.autoCompleteContainerView setHidden:YES];
    dataArray = [CoreDataManager fetchAllUsers];
    if (dataArray.count<=1) {
        return;
    }
    isAutoCompleteForAccountsList = YES;
    [self.containerView removeConstraint:tableViewTopLayoutConstraint];
    tableViewTopLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.autoCompleteTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.fieldFrom attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self.containerView addConstraint:tableViewTopLayoutConstraint];
    [self.containerView layoutIfNeeded];
    [self.autoCompleteTableView setHidden:NO];
    [self.autoCompleteContainerView setHidden:NO];
    
    autoCompleteContainerViewTopConstraint.constant = 0;
    
    [self.autoCompleteTableView reloadData];
}
- (void)openQLPreviewControllerWithIndex:(NSUInteger)index {
    QLPreviewController *previewController=[[QLPreviewController alloc]init];
    previewController.delegate=self;
    previewController.dataSource=self;
    previewController.currentPreviewItemIndex = index;
    
    [[self navigationController] presentModalViewController:previewController animated:YES];
    UINavigationBar *navBar =  [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil];
    [navBar setBackgroundImage:[UIImage imageNamed:@"SideMenuBGColor"] forBarMetrics:UIBarMetricsDefault];
}
- (void)updateTableView:(NSNotification *)notification {
    NSString *stringID = [NSString stringWithFormat:@"%@",[[notification userInfo] valueForKey:kEMAIL_UNIQUE_ID]];
    if (self.attachments == nil) {
        self.attachments = [[NSMutableArray alloc] init];
    }
    NSString * uniqueId = [NSString stringWithFormat:@"%@",[self.draftObject valueForKey:kEMAIL_UNIQUE_ID]];
    if ([stringID isEqualToString:uniqueId]) {
        [self fetchAttachments];
    }
}

- (void)fetchAttachments {
    if (self.attachments == nil) {
        self.attachments = [[NSMutableArray alloc] init];
    }
    BOOL isAttachmentAvailable = [[self.draftObject valueForKey:kIS_ATTACHMENT_AVAILABLE] boolValue];
    NSString * uniqueId = [self.draftObject valueForKey:kEMAIL_UNIQUE_ID];
    long longUserId = [[self.draftObject valueForKey:kUSER_ID] longLongValue];
    NSString * strUserId = [Utilities getStringFromLong:longUserId];
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:strUserId];
    MCOIMAPMessage * message = (MCOIMAPMessage*)[Utilities getUnArchivedArrayForObject:[self.draftObject valueForKey:kMESSAGE_INSTANCE]];
    NSArray * attachamentNames = message.attachments;
    [self fetchAttchamentsForUniqueId:[uniqueId longLongValue] attachmentAvailable:isAttachmentAvailable object:self.draftObject session:imapSession attachamentNames:attachamentNames];
    
}
- (void)fetchAttchamentsForUniqueId:(uint64_t)uid attachmentAvailable:(BOOL)attachmentAvailable object:(NSManagedObject *)object session:(MCOIMAPSession *)session attachamentNames:(NSArray *)attachamentNames {
    if (self.attachments == nil) {
        self.attachments = [[NSMutableArray alloc] init];
    }
    NSMutableArray * attachments = [CoreDataManager getAttachment:[userId longLongValue] emailUid:uid entity:kENTITY_ATTACHMENTS];
    if (attachments.count == 0) {
        if (attachmentAvailable) { /* Fetch attachments from server */
            NSLog(@"attachment call made");
            [[MailCoreServiceManager sharedMailCoreServiceManager] downloadAttachments:object session:session email:currentEmail];
            /* below line just add name to list,until real data fetched
             for (int i = 0; i < attachamentNames.count ; ++i) {
             [self.attachments addObject:[attachments objectAtIndex:i]];
             }*/
        }
        return;
    }
    /* real attachments data */
    if (attachments.count>=1) {
        NSManagedObject * object = [attachments objectAtIndex:0];
        NSMutableArray * attachmentPaths = (NSMutableArray *)[Utilities getUnArchivedArrayForObject:[object valueForKey:kATTACHMENT_PATHS]];
        if (attachmentPaths.count>=1) {
            NSString * path = [attachmentPaths objectAtIndex:0];
            NSArray * array = [Utilities getAttachmentListFromPath:path];
            if (array != nil && array.count>0) {
                for (int i = 0; i < array.count ; ++i) {
                    MCOAttachment * attachment = [array objectAtIndex:i];
                    double size = (double)attachment.data.length/1024.0f/1024.0f;
                    NSLog(@"size = %f",size);
                    totalAttachmentSize+=size;
                    [self.attachments addObject:[array objectAtIndex:i]];
                }
                NSLog(@"all attachments: %@",self.attachments);
                [self.btnAttcahments setHidden:NO];
            }
        }
    }
}
- (void)setUpView {
    
    self.autoCompleteTableView.layer.cornerRadius = 5.0f;
    
    [self.btnAttcahments setHidden:YES];
    [self setBorder];
    self.lblTo.text = @"To:";
    if (textEditor == nil) {
        textEditor = [[TextEditorViewController alloc] initWithNibName:@"TextEditorViewController" bundle:nil];
        [self displayContentController:textEditor];
    }
    
    if (self.draftObject != nil) {
        coreDataObjectId = [[self.draftObject objectID] URIRepresentation];
        [self.btnShowQuote setHidden:YES];
        self.webView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.webView.layer.borderWidth = 0.5f;
        
        self.message = [Utilities getUnArchivedArrayForObject:[self.draftObject valueForKey:kMESSAGE_INSTANCE]];
        NSString * content = [self.draftObject valueForKey:kEMAIL_HTML_PREVIEW];
        NSString * subject = nil;
        NSString *date = [NSDateFormatter localizedStringFromDate:[[self.message header] date]
                                                        dateStyle:NSDateFormatterMediumStyle
                                                        timeStyle:NSDateFormatterMediumStyle];
        if (![Utilities isValidString:content]) {
            [self addPlaceHolderWithFetchContent:YES];
        }
        else {
            NSString * htmlContent = nil;
            if (self.mailType == kDraft || self.mailType == kNewEmail) {
                subject = [self.draftObject valueForKey:kEMAIL_SUBJECT];
                body = content;
                if (textEditor != nil) {
                    [textEditor importHtml:body];
                }
                [self.btnShowQuote setHidden:YES];
                [self fetchAttachments];
            }
            
            else if(self.mailType == kReply){
                self.lblTo.text = @"reply-to:";
                subject = [[[self.message header] replyHeaderWithExcludedRecipients:@[]] subject];
                [self.btnShowQuote setHidden:YES];
                htmlContent = [self.draftObject valueForKey:kEMAIL_HTML_PREVIEW];
                NSString *replyLine = [NSString stringWithFormat:@"<div><br /><br />On %@, %@ wrote:<br /></div>", date, [[[self.message header] from] nonEncodedRFC822String]];
                NSString *oldContent = [NSString stringWithFormat:@"<div style='margin-left: 5px; border-left:2px solid blue;'><div style='margin-left: 5px';>%@</div></div>",  htmlContent];
                body = [replyLine stringByAppendingString:oldContent];
                if ([Utilities isValidString:htmlContent]) {
                    [self loadWebViewWithHtmlContent:htmlContent];
                }
                if (self.quickResponseObject != nil) {
                    [self processQuickResponse:self.quickResponseObject];
                }
            }
            else if(self.mailType == kReplyAll){
                self.lblTo.text = @"reply-to:";
                subject = [[[self.message header] replyAllHeaderWithExcludedRecipients:@[]] subject];
                [self.btnShowQuote setHidden:YES];
                htmlContent = [self.draftObject valueForKey:kEMAIL_HTML_PREVIEW];
                NSString *replyLine = [NSString stringWithFormat:@"<div><br />On %@, %@ wrote:<br /><br /></div>", date, [[[self.message header] from]nonEncodedRFC822String]];
                NSString *oldContent = [NSString stringWithFormat:@"<div style='margin-left: 5px; border-left:2px solid blue;'><div style='margin-left: 5px';>%@</div></div>",  htmlContent];
                body = [replyLine stringByAppendingString:oldContent];
                if ([Utilities isValidString:htmlContent]) {
                    [self loadWebViewWithHtmlContent:htmlContent];
                }
            }
            else if(self.mailType == kForward){
                [self fetchAttachments];
                NSString * fwdSubject = [[self.message header] subject];
                NSString * line1 = [NSString stringWithFormat:@"<div><br />---------- Forwarded message ----------</div>"];
                NSString * line2 = [NSString stringWithFormat:@"<div>From: %@</div>",[[[self.message header] from]nonEncodedRFC822String]];
                
                NSString * line3 = [NSString stringWithFormat:@"<div>Date: %@</div>",date];
                NSString * line4 = [NSString stringWithFormat:@"<div>Subject: %@<br /><br /></div>",[Utilities isValidString:fwdSubject]? fwdSubject : @""];
                NSString *replyLine = [NSString stringWithFormat:@"%@%@%@%@",line1,line2,line3,line4];
                
                subject = [[[self.message header] forwardHeader] subject];
                [self.btnShowQuote setHidden:YES];
                htmlContent = [self.draftObject valueForKey:kEMAIL_HTML_PREVIEW];
                //body = replyLine;//[NSString stringWithFormat:@"<div>%@%@</div>",replyLine,htmlContent];
                
                NSString *oldContent = [NSString stringWithFormat:@"<div style='margin-left: 5px; border-left:2px solid blue;'><div style='margin-left: 5px';>%@</div></div>",  htmlContent];
                body = [replyLine stringByAppendingString:oldContent];
                
                if ([Utilities isValidString:htmlContent]) {
                    [self loadWebViewWithHtmlContent:htmlContent];
                }
            }
            if (textEditor != nil) {
                [textEditor importHtml:body];
            }
            //self.txtWritingArea.text = body;
            
            self.fieldSubject.text = subject;
        }
    }
    else if (_sendLaterObject != nil) {
        [self.btnShowQuote setHidden:YES];
        self.webView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.webView.layer.borderWidth = 0.5f;
        
        NSString * content = [self.sendLaterObject valueForKey:@"message"];
        NSString * subject = [self.sendLaterObject valueForKey:@"subject"];
        
        if (![Utilities isValidString:content]) {
            [self addPlaceHolderWithFetchContent:YES];
        }
        else {
            NSString * htmlContent = nil;
            if (self.mailType == kDraft || self.mailType == kNewEmail) {
                subject = [self.sendLaterObject valueForKey:@"subject"];
                body = content;
                if (textEditor != nil) {
                    [textEditor importHtml:body];
                }
                [self.btnShowQuote setHidden:YES];
                [self fetchAttachments];
            }
            
            if (textEditor != nil) {
                [textEditor importHtml:body];
            }
            
            self.fieldSubject.text = subject;
            self.toAddresses = [self.sendLaterObject valueForKey:@"to"];
        }
    }
    else { /* new email */
        [self addPlaceHolderWithFetchContent:NO];
        [self.btnShowQuote setHidden:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHidden:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    /*self.scrollView.contentSize = CGSizeMake(0, 200);
     
     customKeyBoardToolBar  =   [[[NSBundle mainBundle] loadNibNamed:@"CustomKeyBoardToolBar" owner:self options:nil] objectAtIndex:0];
     customKeyBoardToolBar.delegate = self;
     self.txtWritingArea.inputAccessoryView = customKeyBoardToolBar;
     self.fieldTo.inputAccessoryView = customKeyBoardToolBar;
     self.fieldFrom.inputAccessoryView = customKeyBoardToolBar;
     self.fieldSubject.inputAccessoryView = customKeyBoardToolBar;*/
    
    //self.txtWritingArea.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.navigationController.navigationBar setHidden:NO];
    
    //    if (self.strNavTitle == nil || [self.strNavTitle isEqualToString:@""]) {
    //        self.title = @"";
    //        fromTabHeight.constant = 0.0f;
    //    }
    //    else {
    //        fromTabHeight.constant = 44.0f;
    //        self.title = self.strNavTitle;
    //    }
    [self.view layoutIfNeeded];
    UIBarButtonItem * btnNavClock = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_send_nav"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(btnSendAction:)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnNavClock, nil ];
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_attachment_white"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(btnAttachmentAction:)];
    UIBarButtonItem * btncross=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(btnCrossAction:)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:btncross,btnMenu, nil ];
}

- (void) displayContentController: (TextEditorViewController*) content {
    [self addChildViewController:content];
    //content.view.bounds = self.txtWritingArea.bounds;
    //content.view.frame = self.txtWritingArea.frame;
    [self.containerView addSubview:content.view];
    content.view.translatesAutoresizingMaskIntoConstraints = NO;
    //[Utilities setLayoutConstarintsForEditorView:content.view parentView:self.containerView fromBottomView:self.textEditorContainerView bottomSpace:0.0f topView:self.textEditorContainerView topSpace:0.0f leadingSpace:0.0f trailingSpace:0.0f];
    
    
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:content.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.subjectView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    editorHeight = [NSLayoutConstraint constraintWithItem:content.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.textEditorContainerView.frame.size.height];
    [self.containerView addConstraint:editorHeight];
    
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:content.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.containerView  attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]];
    
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:content.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.containerView  attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f]];
    
    [self.containerView layoutIfNeeded];
    [content didMoveToParentViewController:self];
}

- (void) hideContentController: (TextEditorViewController*) content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}
-(void)scrollToBottom {
    /*set scroll to bottom when click on editor
     so that toolbar can visible */
    ///if (!self.btnQuickResponse.hidden) {
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:bottomOffset animated:YES];
    //}
}
-(void)setBorder {
    subjectTop.constant = -108.0f;
    UIColor * bColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:242.0f/255.0f alpha:1.0f];
    
    /*self.fieldSubject.layer.borderWidth = 0.8f;
    self.fieldSubject.layer.borderColor = bColor.CGColor;
    
    self.toContainerView.layer.borderWidth = 1.0f;
    self.toContainerView.layer.borderColor = bColor.CGColor;
    
    self.ccTokenInputView.layer.borderWidth = 1.0f;
    self.ccTokenInputView.layer.borderColor = bColor.CGColor;
    
    self.bccTokenInputView.layer.borderWidth = 0.8f;
    self.bccTokenInputView.layer.borderColor = bColor.CGColor;
     */
}

-(void)popViewController {
    
    [self hideProgressHud];
    
    if (textEditor != nil) {
        [self hideContentController:textEditor];
    }
    textEditor = nil;
    [self.navigationController popViewControllerAnimated:YES];
    isViewDismissed = YES;
}

-(void)addPlaceHolderWithFetchContent:(BOOL)fetchContent {
    //self.txtWritingArea.text = @"Compose email...";
    //self.txtWritingArea.textColor = [UIColor lightGrayColor]; //optional
    if (fetchContent) {
        if (contentFetchManager == nil) {
            [self showProgressHudWithTitle:@"Fetching Email Body" mode:MBProgressHUDModeIndeterminate];
            [self initBodyFetchManager];
        }
    }
}
-(void)createSession {
    if (self.sendLaterObject != nil) {
        userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.strongDelegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        
        currentEmail = [object valueForKey:kUSER_EMAIL];
        name = [object valueForKey:kUSER_NAME];
        [imapSessionManager createImapSessionWithUserData:object];
    }
    else if (self.draftObject == nil) {
        userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.strongDelegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        
        currentEmail = [object valueForKey:kUSER_EMAIL];
        name = [object valueForKey:kUSER_NAME];
        [imapSessionManager createImapSessionWithUserData:object];
    }
    else {
        long uid = [[self.draftObject valueForKey:kUSER_ID] longLongValue];
        userId = [NSString stringWithFormat:@"%ld",uid];
        NSLog(@"drafted user id = %@", userId);
        if (imapSessionManager == nil) {
            imapSessionManager = [[MCOIMAPSessionManager alloc] init];
        }
        imapSessionManager.strongDelegate = self;
        NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
        NSManagedObject * object = [userArray lastObject];
        
        currentEmail = [object valueForKey:kUSER_EMAIL];
        name = [object valueForKey:kUSER_NAME];
        [imapSessionManager createImapSessionWithUserData:object];
    }
}
-(void)keyboardWillBeShown:(NSNotification *)notification {
    NSString * btnTitle = @"Quoted Text";
    if (quotedViewBottom.constant > 0.0f) {
        quotedViewBottom.constant = 0.0f;
        
        [self.btnShowQuote setTitle:btnTitle forState:UIControlStateNormal];
        
        [self.view setNeedsUpdateConstraints];
        [self.btnCrossWebview setHidden:YES];
        [self.webView setHidden:YES];
        [UIView animateWithDuration:0.25f animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    [self btnHideAttachment:nil];
    
    /* if app is running on iPhone 5 or 4 than add addtional 100 in scrollview */
    CGFloat screenHeight = [self getViewHeight];
    if (!isAdditionalHeightAdded && screenHeight<667) {
        [self setScrollViewConstant:containerViewHeight.constant+100];
        isAdditionalHeightAdded = YES;
        
        CGFloat height= self.textEditorContainerView.frame.size.height;
        NSLog(@"height = %f", height);
        [self.containerView removeConstraint:editorHeight];
        editorHeight = [NSLayoutConstraint constraintWithItem:textEditor.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:height];
        [self.containerView addConstraint:editorHeight];
        [self.containerView layoutIfNeeded];
    }
}
- (void)keyboardWasShown:(NSNotification *)notification {
    self.autoCompleteTableView.hidden = YES;
    [self.autoCompleteContainerView setHidden:YES];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int height = MIN(keyboardSize.height,keyboardSize.width);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        quickBtnBottom.constant = height + quickResponseBottom;
        [self.view setNeedsUpdateConstraints];
        [UIView animateWithDuration:0.35f animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}
- (void)keyboardHidden:(NSNotification *)notification {
    [self hideQuickResponseButton];
    //your other code here..........
}
-(void)hideQuickResponseButton {
    if (isAdditionalHeightAdded) {
        isAdditionalHeightAdded = NO;
        [self setScrollViewConstant:containerViewHeight.constant-100];
    }
    quickBtnBottom.constant = 10;
    [textEditor displayToolbar];
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.35f animations:^{
        [self.view layoutIfNeeded];
    }];
    quickResponseBottom = 50;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //[textEditor displayToolbar];
        [self.btnQuickResponse setHidden:NO];
    });
}
-(float)getViewHeight {
    float SW;
    float SH;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (( [[[UIDevice currentDevice] systemVersion] floatValue]<8)  && UIInterfaceOrientationIsLandscape(orientation))
    {
        SW = [[UIScreen mainScreen] bounds].size.height;
        SH = [[UIScreen mainScreen] bounds].size.width;
    }
    else
    {
        SW = [[UIScreen mainScreen] bounds].size.width;
        SH = [[UIScreen mainScreen] bounds].size.height;
    }
    return SH;
}
-(void)saveFakeDraftWithCase:(int)value {
    
    if ((self.mailType == kForward || self.mailType == kReplyAll || self.mailType == kReply || self.mailType == kNewEmail) && self.isDraft == NO) { /* email, reply, forward sent */
        NSLog(@"email, reply, forward sent");
    }
    else { /* draft edited */
        if (self.draftObject != nil) {
            if (value == kDraft) {
                NSString * subject = self.fieldSubject.text;
                NSString *txtbody = [[[textEditor exportText] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
                if ([txtbody length]>=50) {
                    txtbody = [txtbody substringToIndex:50];
                }
                [self.draftObject setValue:[NSNumber numberWithBool:YES] forKey:kIS_FAKE_DRAFT];
                [self.draftObject setValue:txtbody forKey:kEMAIL_PREVIEW];
                [self.draftObject setValue:subject forKey:kEMAIL_SUBJECT];
            }
            else { /* draft sent */
                [self.draftObject setValue:[NSNumber numberWithBool:YES] forKey:kHIDE_EMAIL];
            }
            [CoreDataManager updateData];
        }
        else { /* draft saved */
            NSLog(@"draft saved");
            NSString * subject = self.fieldSubject.text;
            NSString * txtbody = [[[textEditor exportText] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
            if ([txtbody length]>=50) {
                txtbody = [txtbody substringToIndex:50];
            }
            cloneId = [Utilities getFakeDraftId];
            [CoreDataManager saveFakeDraft:nil forUserId:[userId longLongValue] subject:subject preview:txtbody fakeId:cloneId];
        }
    }
}
-(void)saveDraft {
    [self.view endEditing:YES];
    if (self.isSendLater) {
        [self removeDelegates];
        [self popViewController];
    }
    else if ([self needsToSaveDraft]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you want to save the draft?"
                                                                 delegate:self
                                                        cancelButtonTitle:@"No"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Yes", nil];
        actionSheet.tag = 1028;
        [actionSheet showInView:self.view];
    }
    else {
        [self removeDelegates];
        [self popViewController];
    }
}
-(void)setUpTokenView {
    [self.attachmentTableView setBackgroundView:nil];
    [self.attachmentTableView setBackgroundColor:[UIColor clearColor]];
    [self.attachmentTableView setTag:1875];
    [self.autoCompleteTableView setTag:1876];
    // First, get the view embedding the grandchildview to front.
    [self.view bringSubviewToFront:[self.btnQuickResponse superview]];
    // Now, inside that container view, get the "grandchildview" to front.
    [[self.btnQuickResponse superview] bringSubviewToFront:self.btnQuickResponse];
    
    [[self.btnShowQuote superview] bringSubviewToFront:self.btnShowQuote];
    [[self.btnAttcahments superview] bringSubviewToFront:self.btnAttcahments];
    [[self.webView superview] bringSubviewToFront:self.webView];
    [[self.attachmentView superview] bringSubviewToFront:self.attachmentView];
    [[self.lblFile superview] bringSubviewToFront:self.lblFile];
    [[self.imgAttachment superview] bringSubviewToFront:self.imgAttachment];
    [[self.autoCompleteContainerView superview] bringSubviewToFront:self.autoCompleteContainerView];
    [[self.autoCompleteTableView superview] bringSubviewToFront:self.autoCompleteTableView];
    [[self.btnCrossWebview superview] bringSubviewToFront:self.btnCrossWebview];
    [self.btnCrossWebview setHidden:YES];
    if (self.toAddresses == nil) {
        self.toAddresses = [[NSMutableArray alloc] init];
    }
    if (self.ccAddresses == nil) {
        self.ccAddresses = [[NSMutableArray alloc] init];
    }
    if (self.senderData == nil) {
        self.senderData = [[NSMutableArray alloc] init];
    }
    if (self.bccAddresses == nil) {
        self.bccAddresses = [[NSMutableArray alloc] init];
    }
    if (self.toAddressesMap == nil) {
        self.toAddressesMap = [[NSMutableArray alloc] init];
    }
    if (self.ccAddressesMap == nil) {
        self.ccAddressesMap = [[NSMutableArray alloc] init];
    }
    if (self.bccAddressesMap == nil) {
        self.bccAddressesMap = [[NSMutableArray alloc] init];
    }
    
    if ([Utilities isValidString:userId]) {
        
        self.fieldFrom.text = currentEmail;
        if (![Utilities isValidString:name]) {
            name = [[currentEmail componentsSeparatedByString:@"@"] objectAtIndex:0];
        }
        [self.senderData addObject:name];
        [self.senderData addObject:currentEmail];
    }
    
    if (![self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.tokenInputTopSpace.constant = 0.0;
    }
    
    [UITextField appearanceWhenContainedIn:[CLTokenInputView class], nil].font = [UIFont fontWithName:@"SFUIText-Regular" size:15];
    
    [UILabel appearanceWhenContainedIn:[CLTokenInputView class], nil].font = [UIFont fontWithName:@"SFUIText-Regular" size:15];
    
    if ([self.toAddresses count] > 1) {
        NSString *toAddress = [self.toAddresses firstObject];
        for (int i = 1; i < [self.toAddresses count]; i ++) {
            NSString *str = [self.toAddresses objectAtIndex:i];
            toAddress = [NSString stringWithFormat:@"%@,%@", toAddress, str];
        }
        
        self.tokenInputView.fieldName = toAddress;
    }
    else if ([self.toAddresses count] == 1) {
        NSString *toAddress = [self.toAddresses firstObject];
        self.tokenInputView.fieldName = toAddress;
    }
    else {
        self.tokenInputView.fieldName = @"";
    }
    [self.tokenInputView setFieldColor:[UIColor blackColor]];
    self.tokenInputView.placeholderText = @"  ";
    self.tokenInputView.accessoryView = nil;
    self.tokenInputView.drawBottomBorder = NO;
    self.tokenInputView.tintColor = [UIColor blackColor];
    self.tokenInputView.delegate = self;
    self.tokenInputView.tag = 198;
    
    
    self.ccTokenInputView.fieldName = @"";
    [self.ccTokenInputView setFieldColor:[UIColor blackColor]];
    self.ccTokenInputView.placeholderText = @"  ";
    self.ccTokenInputView.accessoryView = nil;
    self.ccTokenInputView.drawBottomBorder = NO;
    self.ccTokenInputView.tintColor = [UIColor blackColor];
    self.ccTokenInputView.delegate = self;
    self.ccTokenInputView.tag = 199;
    
    self.bccTokenInputView.fieldName = @"";
    [self.bccTokenInputView setFieldColor:[UIColor blackColor]];
    self.bccTokenInputView.placeholderText = @"  ";
    self.bccTokenInputView.accessoryView = nil;
    self.bccTokenInputView.drawBottomBorder = NO;
    self.bccTokenInputView.tintColor = [UIColor blackColor];
    self.bccTokenInputView.delegate = self;
    self.bccTokenInputView.tag = 200;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        if (self.sendLaterObject != nil) {
//            NSString *to = [self.sendLaterObject valueForKey:@"to"];
//            [self saveEmailInToken:to forTag:198];
//            [self extractCcAddressesForTag:199];
//            [self extractBccAddressesForTag:200];
//        }
        if (self.draftObject != nil && self.mailType == kNewEmail) {
            /*editing draft */
            [self extractToAddressesWithFilter:NO];
            [self extractCcAddressesForTag:199];
            [self extractBccAddressesForTag:200];
        }
        else if (self.draftObject != nil && self.mailType == kReplyAll) {
            MCOAddress * mcoAddress = self.message.header.from;
            if (![mcoAddress.mailbox isEqualToString:[self.senderData lastObject]]) {
                MCOAddress * mcoAddress = self.message.header.from;
                NSString * from = [NSString stringWithFormat:@"%@ ", mcoAddress.mailbox];
                //NSString * from = [NSString stringWithFormat:@"%@ ", self.message.header.sender.mailbox];
                [self saveEmailInToken:from forTag:198];
            }
            [self extractToAddressesWithFilter:YES];
            [self extractCcAddressesForTag:198];
        }
        else if (self.draftObject != nil && self.mailType == kReply) {
            MCOAddress * mcoAddress = self.message.header.from;
            //NSString * from = [NSString stringWithFormat:@"%@ ", self.message.header.sender.mailbox];
            NSString * from = [NSString stringWithFormat:@"%@ ", mcoAddress.mailbox];
            if (self.message.header.replyTo.count == 1) {
                MCOAddress * fromAddress = [self.message.header.replyTo objectAtIndex:0];
                
                if(![mcoAddress.mailbox isEqualToString:fromAddress.mailbox]) {
                    from = [NSString stringWithFormat:@"%@ ", fromAddress.mailbox];
                }
            }
            /* check if
             the sender of the message is equal to
             current login account than just get all "to" addresses
             from message and make them "to" for new reply.
             it is cases with gmail app
             
             else
             just get from address message and make it "to" for the
             new message */
            
            if ([mcoAddress.mailbox isEqualToString:[self.senderData lastObject]]) {
                [self extractToAddressesWithFilter:NO];
            }
            else {
                [self saveEmailInToken:from forTag:198];
            }
        }
    });
}
-(void)setScrollViewConstant:(double)constant {
    containerViewHeight.constant = constant;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.0f animations:^{
        [self.view layoutIfNeeded];
    }];
}
-(void)animateCcViewWithButton:(UIButton *)btn {
    CGFloat toViewHeight = self.toView.frame.size.height;
    CGFloat ccViewHeight = self.ccView.frame.size.height;
    CGFloat scrollViewHeight = 0.0f;
    
    NSLog(@"ToView Height = %f", toViewHeight);
    NSLog(@"ccView Height = %f", ccViewHeight);
    NSLog(@"scrollView Height = %f", scrollViewHeight);
    //[btn setSelected:!btn.selected];
    [self.view endEditing:YES];
    if (subjectTop.constant == 0.0) {
        //isCcViewHidden = YES;
        //[self setScrollViewConstant:containerViewHeight.constant-scrollViewHeight];
        //subjectTop.constant = -ccViewHeight;
    }
    else {
        [btn setHidden:YES];
        isCcViewHidden = NO;
        
        if (toViewHeight>toViewLastHeight) {
            scrollViewHeight = toViewHeight-toViewLastHeight;
            [self setScrollViewConstant:containerViewHeight.constant+scrollViewHeight];
        }
        else if (toViewHeight<toViewLastHeight) {
            scrollViewHeight = toViewLastHeight-toViewHeight;
            scrollViewHeight = -scrollViewHeight;
            [self setScrollViewConstant:containerViewHeight.constant+scrollViewHeight];
        }
        else if (toViewHeight == toViewLastHeight) {
            //[self setScrollViewConstant:containerViewHeight.constant+scrollViewHeight];
        }
        
        if (ccViewHeight>ccViewLastHeight) {
            scrollViewHeight = ccViewHeight-ccViewLastHeight;
        }
        else if (ccViewHeight<ccViewLastHeight) {
            scrollViewHeight = ccViewLastHeight-ccViewHeight;
            scrollViewHeight = -scrollViewHeight;
        }
        ccViewLastHeight = ccViewHeight;
        
        
        
        if (scrollViewHeight!=0.0f) {
            [self setScrollViewConstant:containerViewHeight.constant + scrollViewHeight];
        }
        NSLog(@"ToView Height = %f", toViewHeight);
        NSLog(@"ccView Height = %f", ccViewHeight);
        NSLog(@"scrollView Height = %f", scrollViewHeight);
        subjectTop.constant = 0.0f;
        toViewLastHeight = toViewHeight;
        ccViewLastHeight = ccViewHeight;
    }
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}
-(void)extractToAddressesWithFilter:(BOOL)filter {
    id object = [Utilities getUnArchivedArrayForObject:[self.draftObject valueForKey:kTO_ADDRESSES]];
    NSMutableArray * array = nil;
    if ([object isKindOfClass:[NSMutableArray class]]) {
        array = (NSMutableArray *)object;
    }
    if (array != nil) {
        for (int i = 0; i<array.count; ++i) {
            NSMutableDictionary * dic = [array objectAtIndex:i];
            NSString * to = [NSString stringWithFormat:@"%@ ", [dic objectForKey:kMAIL_BOX]];
            if (filter) {
                if (![[dic objectForKey:kMAIL_BOX] isEqualToString:[self.senderData lastObject]]) {
                    //[self.ccAddresses addObject:to];
                    [self saveEmailInToken:to forTag:198];
                }
            }
            else {
                [self saveEmailInToken:to forTag:198];
            }
        }
    }
}
-(void)extractCcAddressesForTag:(long)tag {
    id object = [Utilities getUnArchivedArrayForObject:[self.draftObject valueForKey:kCC_ADDRESSES]];
    NSMutableArray * array = nil;
    if ([object isKindOfClass:[NSMutableArray class]]) {
        array = (NSMutableArray *)object;
    }
    if (array != nil) {
        for (int i = 0; i<array.count; ++i) {
            NSMutableDictionary * dic = [array objectAtIndex:i];
            NSString * cc = [NSString stringWithFormat:@"%@ ", [dic objectForKey:kMAIL_BOX]];
            if (tag == 298) {
                if (![[dic objectForKey:kMAIL_BOX] isEqualToString:[self.senderData lastObject]]) {
                    //[self.ccAddresses addObject:cc];
                    [self saveEmailInToken:cc forTag:tag];
                    
                }
            }
            else {
                if ([Utilities isValidString:cc]) {
                    [self saveEmailInToken:cc forTag:tag];
                    if (tag == 199) {
                        if (subjectTop.constant == -108.0f) {
                            subjectTop.constant = 0.0f;
                        }
                    }
                }
            }
        }
    }
}
-(void)extractBccAddressesForTag:(long)tag {
    id object = [Utilities getUnArchivedArrayForObject:[self.draftObject valueForKey:kBCC_ADDRESSES]];
    NSMutableArray * array = nil;
    if ([object isKindOfClass:[NSMutableArray class]]) {
        array = (NSMutableArray *)object;
    }
    if (array != nil) {
        for (int i = 0; i<array.count; ++i) {
            NSMutableDictionary * dic = [array objectAtIndex:i];
            NSString * bcc = [NSString stringWithFormat:@"%@ ", [dic objectForKey:kMAIL_BOX]];
            
            //[self.ccAddresses addObject:cc];
            if ([Utilities isValidString:bcc]) {
                [self saveEmailInToken:bcc forTag:tag];
                if (subjectTop.constant == -108.0f) {
                    subjectTop.constant = 0.0f;
                }
            }
        }
    }
}
-(void)saveEmailInToken:(NSString *)text forTag:(long)tokenTag {
    NSString *lastChar = nil;
    if ([Utilities isValidString:text]) {
        lastChar = [text substringFromIndex:[text length] - 1];
        
        if ([lastChar isEqualToString:@","] || [lastChar isEqualToString:@" "]){
            
            NSString *stringWithoutcoma = [text
                                           stringByReplacingOccurrencesOfString:lastChar withString:@""];
            if ([Utilities isValidString:stringWithoutcoma]) {
                CLToken *token = [[CLToken alloc] initWithDisplayText:stringWithoutcoma context:nil];
                if (tokenTag == 198) {
                    [self.tokenInputView addToken:token];
                }
                else if (tokenTag == 199) {
                    [self.ccTokenInputView addToken:token];
                }
                else if (tokenTag == 200) {
                    [self.bccTokenInputView addToken:token];
                }
                emailString = nil;
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
}
-(void)showProgressHudWithTitle:(NSString *)title mode:(MBProgressHUDMode)mode {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = mode;
    hud.label.text = title;
}
-(void)hideProgressHud {
    if (hud) {
        [hud hideAnimated:YES];
    }
}
-(BOOL)needsToSaveDraft {
    BOOL needtoSaveDraft = NO;
    NSString * messageBody = [textEditor exportHtml];//self.txtWritingArea.text;
    //    UIColor * textColor = self.txtWritingArea.textColor;
    //    if ([textColor isEqual:[UIColor lightGrayColor]]) {
    //        messageBody = @"";
    //    }
    if ([Utilities isValidString:messageBody]) {
        needtoSaveDraft = YES;
    }
    if ([Utilities isValidString:emailString]) {
        [self saveEmailInToken:[NSString stringWithFormat:@"%@,",emailString] forTag:currentTag];
    }
    if (self.toAddresses.count > 0) {
        needtoSaveDraft = YES;
    }
    
    if ([Utilities isValidString:self.fieldSubject.text]) {
        needtoSaveDraft = YES;
    }
    
    return needtoSaveDraft;
}
-(void)setEmailContent {
    if (self.draftObject != nil) {
        NSString * emailBody = [self.draftObject valueForKey:kEMAIL_BODY];
        if ([Utilities isValidString:emailBody]) {
        }
        else {
            if (contentFetchManager == nil) {
                [self showProgressHudWithTitle:@"Fetching Email Body" mode:MBProgressHUDModeIndeterminate];
                [self initBodyFetchManager];
            }
        }
    }
}
-(void)initBodyFetchManager {
    contentFetchManager = [[MCOIMAPFetchContentOperationManager alloc] init];
    contentFetchManager.delegate = self;
    [contentFetchManager createFetcherWithUserId:userId];
}
-(BOOL)parseEmailsWithCase:(int)caseType {
    NSMutableArray * tempTo = [[NSMutableArray alloc] init];
    BOOL toEmail = YES;
    BOOL bccEmail = NO;
    BOOL ccEmail = NO;
    for (NSString * email in self.toAddresses) {
        if ([email isEqualToString:kBCC]) {
            toEmail = NO;
            bccEmail = YES;
            ccEmail = NO;
        }
        else if ([email isEqualToString:kCC]) {
            toEmail = NO;
            bccEmail = NO;
            ccEmail = YES;
        }
        else {
            if (![Utilities NSStringIsValidEmail:email] && caseType != kDraft) {
                [self showAlertWithTitle:@"Invalid Address" andMessage:[NSString stringWithFormat:@"Please enter valid email address."] withDelegate:nil];
                isSentRequestMade = NO;
                return false;
            }
            else {
                if (toEmail) {
                    [tempTo addObject:email];
                }
                else if(bccEmail) {
                    [self.bccAddresses addObject:email];
                }
                else if (ccEmail) {
                    [self.ccAddresses addObject:email];
                }
            }
        }
    }
    [self.toAddresses removeAllObjects];
    [self.toAddresses addObjectsFromArray:tempTo];
    NSLog(@"CC: %@",self.ccAddresses);
    NSLog(@"BCC: %@",self.bccAddresses);
    NSLog(@"TO: %@",self.toAddresses);
    return YES;
}

-(BOOL)validateMessage:(int)caseType {
    [self.view endEditing:YES];
    
    sendMessage = [[SendMessageManager alloc] init];
    NSString * hudMessage = @"Sending mail...";
    sendMessage.folderType = kFolderSentMail;
    
    if (self.mailType == kNewEmail) {
    }
    else if (self.mailType == kReply) {
        sendMessage.header = [self.message.header replyHeaderWithExcludedRecipients:@[]];
    }
    else if (self.mailType == kReplyAll) {
        sendMessage.header = [self.message.header replyAllHeaderWithExcludedRecipients:@[]];
    }
    else if (self.mailType == kForward) {
        sendMessage.header = [self.message.header replyAllHeaderWithExcludedRecipients:@[]];
    }
    else if (self.mailType == kDraft) {
        sendMessage.folderType = kFolderDraftMail;
        hudMessage = @"Saving Draft";
    }
    NSLog(@"Orignal header: %@",self.message.header.description);
    //NSLog(@"FAKE :%@",sendMessage.header.description);
    self.sendingData = [[NSMutableArray alloc] init];
    if (![Utilities NSStringIsValidEmail:self.fieldFrom.text]) {
        [self showAlertWithTitle:@"Alert" andMessage:[NSString stringWithFormat:@"Need Sender Address."] withDelegate:nil];
        isSentRequestMade = NO;
        return false;
    }
    [self.sendingData addObject:self.fieldSubject.text];
    NSString * messageBody = [textEditor exportHtml];//self.txtWritingArea.text;
    //    UIColor * textColor = self.txtWritingArea.textColor;
    //    if ([textColor isEqual:[UIColor lightGrayColor]]) {
    //        messageBody = @"";
    //    }
    
    [self.sendingData addObject:messageBody];
    if (self.draftObject && !self.isDraft) {
        //NSString * html = [self.draftObject valueForKey:kEMAIL_HTML_PREVIEW];
        //[self.sendingData addObject:[NSString stringWithFormat:@"<div>%@%@</div>",body,html]];
    }
    if ([Utilities isValidString:emailString]) {
        [self saveEmailInToken:[NSString stringWithFormat:@"%@,",emailString] forTag:currentTag];
    }
    if (self.toAddresses.count == 0 && caseType != kDraft) {
        [self showAlertWithTitle:@"Invalid Address" andMessage:[NSString stringWithFormat:@"Please enter valid email address."] withDelegate:nil];
        isSentRequestMade = NO;
        return false;
    }
    BOOL value = [self parseEmailsWithCase:caseType];
    if (!value) {
        return value;
    }
    /*
     if (![Utilities NSStringIsValidEmail:email] && caseType != kDraft) {
     [self showAlertWithTitle:@"Invalid Address" andMessage:[NSString stringWithFormat:@"Please enter valid email address."] withDelegate:nil];
     isSentRequestMade = NO;
     return;
     }
     
     if (self.bccAddresses.count>0) {
     for (NSString * email in self.bccAddresses) {
     if (![Utilities NSStringIsValidEmail:email] && caseType != kDraft) {
     [self showAlertWithTitle:@"Invalid Address" andMessage:[NSString stringWithFormat:@"Please enter valid email address."] withDelegate:nil];
     isSentRequestMade = NO;
     return;
     }
     }
     }
     
     if (self.ccAddresses.count>0) {
     for (NSString * email in self.ccAddresses) {
     if (![Utilities NSStringIsValidEmail:email] && caseType != kDraft) {
     [self showAlertWithTitle:@"Invalid Address" andMessage:[NSString stringWithFormat:@"Please enter valid email address."] withDelegate:nil];
     isSentRequestMade = NO;
     return;
     }
     }
     }*/
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        isSentRequestMade = NO;
        return false;
    }
    return true;
}
-(void)sendMessageWithCase:(int)caseType {
    BOOL value =  [self validateMessage:caseType];
    if (!value) {
        return;
    }
    if (totalAttachmentSize>25) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Attachment Error!!" message:@"The file size exceeds the 25 MB attachment limit." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
        return;
    }
    sendMessage.delegate = self;
    sendMessage.sendingData = self.sendingData;
    sendMessage.fromData = self.senderData;
    sendMessage.toAddresses = self.toAddresses;
    sendMessage.ccAddresses = self.ccAddresses;
    sendMessage.bccAddresses = self.bccAddresses;
    sendMessage.attachments = self.attachments;
    NSString * email = nil;
    if (self.senderData.count>=2) {
        email = [self.senderData objectAtIndex:1];
    }
    if ([Utilities isValidString:email]) {
        [sendMessage startSendingWithEmail:email];
        [self saveFakeDraftWithCase:caseType];
    }
    
    [self showProgressHudWithTitle:@"Sending Email" mode:MBProgressHUDModeIndeterminate];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(popViewController) userInfo:nil repeats:NO];
    
    [Utilities setUserDefaultWithValue:@"YES" andKey:kUSER_DEFAULTS_EMAIL_COMPOSED];
}


- (void)handleDataModelChange:(NSNotification *)note {
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSArray * array = [deletedObjects allObjects];
    for (NSManagedObject * emailObject in array) {
        if ([[[emailObject objectID] URIRepresentation] isEqual:coreDataObjectId]) {
            if (isViewDismissed == NO) {
                //UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!!" message:@"This message has been removed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //[av show];
                
                if (textEditor != nil) {
                    [self hideContentController:textEditor];
                }
                textEditor = nil;
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
    }
}
-(void)deleteOldDraftWithSucessMessage:(NSString*)message deletLocalCopy:(BOOL)deleteLocal newUid:(long)uid  {
    NSArray * array =  [Utilities getIndexSetFromObject:self.draftObject];
    NSString * folderName = [array objectAtIndex:0];
    MCOIndexSet * indexSet = [array objectAtIndex:1];
    MCOMessageFlag newflags = MCOMessageFlagDraft;
    
    newflags |= MCOMessageFlagDeleted;
    
    newflags |= !MCOMessageFlagFlagged;
    [self manageLocalDBWithNewUid:YES];
    MCOIMAPSession * imapSession = [Utilities getSessionForUID:userId];
    if (imapSession != nil) {
        MCOIMAPOperation *changeFlags = [imapSession  storeFlagsOperationWithFolder:folderName  uids:indexSet kind:MCOIMAPStoreFlagsRequestKindSet flags:newflags];
        [changeFlags start:^(NSError *error) {
            if (!error) {
                NSLog(@"\nFlag has been changed changed\n");
                MCOIMAPOperation *expungeOp = [imapSession expungeOperation:folderName];
                [expungeOp start:^(NSError *error) {
                    
                    if (error) {
                        NSLog(@"\nExpunge Failed\n");
                        [self showSuccessMessage:error.localizedDescription];
                        [self removeDelegates];
                    }
                    else {
                        NSLog(@"\nFolder Expunged\n");
                        [self removeDelegates];
                    }
                }];
            }
            else {
                NSLog(@"\nError with flag changing\n");
                [self showSuccessMessage:error.localizedDescription];
                [self removeDelegates];
            }
            
        }];
    }
}
-(void)loadWebViewWithHtmlContent:(NSString *)content {
    //    if (content == nil) {
    //        [self.webView loadHTMLString:@"" baseURL:nil];
    //        return;
    //    }
    self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
    self.webView.scalesPageToFit = YES;
    self.webView.contentMode = UIViewContentModeScaleAspectFit;
    content = [NSString stringWithFormat:@"<div>%@%@</div>",body,content];
    
    NSMutableString * html = [NSMutableString string];
    [html appendFormat:@"<html><head><script>%@</script><style>%@</style></head>"
     @"<body>%@</body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'>"
     @"</iframe></html>", mainJavascript, mainStyle, content];
    [self.webView setDelegate:self];
    [self.webView loadHTMLString:html baseURL:nil];
}
-(void)manageLocalDBWithNewUid:(BOOL)deleteLocal {
    /* Need to delete local copy if draft email has been sent*/
    if (deleteLocal) {
        [CoreDataManager deleteObject:self.draftObject];
        [CoreDataManager updateData];
    }
    /* Here we will update existing local copy with new uid,
     it means draft has been updated on server */
    else {
        /*[self.draftObject setValue:[NSNumber numberWithLong:uid] forKey:kEMAIL_ID];
         NSString * str = [textEditor exportHtml];//self.txtWritingArea.text;
         [self.draftObject setValue:str forKey:kEMAIL_BODY];
         if ([str length]>=50) {
         str = [str substringToIndex:50];
         }
         [self.draftObject setValue:str forKey:kEMAIL_PREVIEW];
         [self.draftObject setValue:[NSDate date] forKey:kEMAIL_DATE];
         [self.draftObject setValue:self.fieldSubject.text forKey:kEMAIL_SUBJECT];
         if (self.toAddresses.count>0) {
         //[self.draftObject setValue:[Utilities getArchivedArray:self.toAddresses] forKey:kTO_ADDRESSES];
         }
         [CoreDataManager updateData];*/
    }
    
}
-(void)showSuccessMessage:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHud];
        [self showAlertWithTitle:@"Alert" andMessage:msg withDelegate:nil];
    });
}
-(void)showPickerView {
    [self.view endEditing:YES];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.navigationBar.translucent = NO;
    picker.navigationBar.barTintColor = [UIColor colorWithRed:43.0f/255.0f green:52.0f/255.0f blue:66.0f/255.0f alpha:1.0f];
    picker.navigationBar.tintColor = [UIColor whiteColor];
    picker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    [self presentViewController:picker animated:YES completion:NULL];
}
-(void)setAttachmentViewVisibilityWithBool:(BOOL)value dealy:(double)dealy {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dealy * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.attachmentView setHidden:value];
    });
}
#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender{
    //executes when you scroll the scrollView
    //[self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // execute when you drag the scrollView
    //[self.view endEditing:YES];
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (self.attachments == nil) {
        self.attachments = [[NSMutableArray alloc] init];
    }
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    NSData * imageData = UIImageJPEGRepresentation(chosenImage, 1.0);
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"bytes = %lu",(unsigned long)imageData.length)   ;
    NSLog(@"File size is : %.5f MB",(float)imageData.length/1024.0f/1024.0f);
    
    double size = (double)imageData.length/1024.0f/1024.0f;
    NSLog(@"size = %f",size );
    totalAttachmentSize+=size;
    NSLog(@"TOTAL SIZE = %f",totalAttachmentSize);
    if (totalAttachmentSize>25) {
        totalAttachmentSize-=size;
        imageData = nil;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Attachment Error!!" message:@"The file size exceeds the 25 MB attachment limit." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
        return;
    }
    [self.attachments addObject:imageData];
    [self.btnAttcahments setHidden:NO];
    [self.attachmentTableView reloadData];
    
    /*NSURL *refURL = [info valueForKey:UIImagePickerControllerReferenceURL];
     
     // define the block to call when we get the asset based on the url (below)
     ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
     {
     ALAssetRepresentation *imageRep = [imageAsset defaultRepresentation];
     NSLog(@"[imageRep filename] : %@", [imageRep filename]);
     };
     
     // get the asset library and fetch the asset based on the ref url (pass in block above)
     ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
     [assetslibrary assetForURL:refURL resultBlock:resultblock failureBlock:nil];*/
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
#pragma - mark CustomKeyBoardToolBarDelegate
- (void) customKeyBoardBoldDelegate {
    
}
- (void) customKeyBoardItalicDelegate {
    
}
- (void) customKeyBoardSendLaterDelegate {
    [self.view endEditing:YES];
    if (snoozeView != nil) {
        snoozeView.delegate = nil;
        snoozeView = nil;
    }
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
    BOOL isDeafult = NO;
    if (value == 1) {
        isDeafult = YES;
    }
    
    NSMutableArray * array = [CoreDataManager fetchSendlaterPreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
    [snoozeView setDataSource:array];
    [snoozeView setButtonTitles:@"Save" buttonTitle2:@"Cancel"];
    [snoozeView setTableViewType:3];
    [snoozeView setTableViewCellHeight:44.5f];
    [snoozeView setViewXvalue:38.0f];
    [snoozeView setViewTitle:@"Send Later"];
    [snoozeView setViewHeight:463.5f screenHeight:self.view.frame.size.height];
    
    [self.view addSubview:snoozeView];
    snoozeView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:snoozeView forParent:self.view topValue:0.0f];
}
- (void) customKeyBoardBulletsDelegate {
    
}
- (void) customKeyBoardNotesDelegate {
    
}

#pragma - mark User Actions
-(IBAction)btnSendAction:(id)sender {
    if (_isSendLater) {
        
        [self updateScheduledEmail];
        return;
    }
    if (!isSentRequestMade) {
        isSentRequestMade = YES;
        [self sendMessageWithCase:kNewEmail];
    }
}
-(IBAction)btnCrossAction:(id)sender {
    [self saveDraft];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}
-(IBAction)btnAttachmentAction:(id)sender {
    [self showPickerView];
}
-(IBAction)btnQuickResponseAction:(id)sender {
    [self.view endEditing:YES];
    if (snoozeView != nil) {
        snoozeView.delegate = nil;
        snoozeView = nil;
    }
    snoozeView = [[[NSBundle mainBundle] loadNibNamed:@"SnoozeView" owner:self options:nil] objectAtIndex:0];
    snoozeView.delegate = self;
    
    quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
    [snoozeView setDataSource:quickResponses];
    [snoozeView setUserId:userId email:currentEmail];
    [snoozeView setButtonTitles:@"Customize" buttonTitle2:@"Cancel"];
    [snoozeView setTableViewType:2];
    [snoozeView setTableViewCellHeight:44.5f];
    [snoozeView setViewXvalue:92.5f];
    [snoozeView setViewTitle:@"Quick Response"];
    [snoozeView setViewHeight:354.5f screenHeight:self.view.frame.size.height];
    
    [self.view addSubview:snoozeView];
    snoozeView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:snoozeView forParent:self.view topValue:0.0f];
    //    QuickResponseViewController *quickResponseViewController = [[QuickResponseViewController alloc] init];
    //    SWRevealViewController *revealController = [self revealViewController];
    //     UINavigationController * sideMenuNav = (UINavigationController*) revealController.rearViewController;
    //    SideMenuViewController * sideMenu = [[sideMenuNav viewControllers] objectAtIndex:0];
    //    [sideMenu setPresentedRow:0 andSection:1];
    //    [revealController pushFrontViewController:[[UINavigationController alloc] initWithRootViewController:quickResponseViewController] animated:YES];
}
-(IBAction)btnOpenCcAction:(id)sender {
    [self animateCcViewWithButton:(UIButton*)sender];
}
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
-(IBAction)btnShowAttachment:(id)sender {
    [self.view endEditing:YES];
    [self.attachmentTableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (attachmentViewBottom.constant == 0.0f) {
            attachmentViewBottom.constant = -195.0f;
            [self setAttachmentViewVisibilityWithBool:YES dealy:0.30];
        }
        else {
            attachmentViewBottom.constant = 0.0f;
            [self setAttachmentViewVisibilityWithBool:NO dealy:0.0];
        }
        
        [self.view setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25f animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}
-(IBAction)btnHideAttachment:(id)sender {
    if (attachmentViewBottom.constant == 0.0f) {
        attachmentViewBottom.constant = -195.0f;
        [self.view setNeedsUpdateConstraints];
        [self setAttachmentViewVisibilityWithBool:YES dealy:0.30];
        [UIView animateWithDuration:0.25f animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    else {
        // attachmentViewBottom.constant = 0.0f;
    }
}
-(IBAction)removeAttachment:(id)sender {
    UIButton * btn = (UIButton*)sender;
    if (self.attachments.count>=btn.tag) {
        id obj = [self.attachments objectAtIndex:btn.tag];
        NSData * data = nil;
        if ([obj isKindOfClass:[NSData class]]) {
            data = (NSData *)obj;
        }
        else {
            MCOAttachment * attachment = [self.attachments objectAtIndex:btn.tag];
            data = attachment.data;
        }
        double size = (double)data.length/1024.0f/1024.0f;
        totalAttachmentSize-=size;
        [self.attachments removeObjectAtIndex:btn.tag];
        [self.attachmentTableView reloadData];
        if (totalAttachmentSize<=0) {
            totalAttachmentSize = 0.0;
        }
    }
    if (self.attachments.count == 0) {
        [self.btnAttcahments setHidden:YES];
        [self btnHideAttachment:nil];
    }
}
-(IBAction)btnShowQuotedMessageAction:(id)sender {
    [self.view endEditing:YES];
    UIButton * btn = (UIButton*)sender;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //NSString * btnTitle = @"Quoted Text";
        CGFloat calculatedHeight = viewHeight/1.5;
        //        if (calculatedHeight>editorHeight.constant) {
        //            calculatedHeight -= 100;
        //        }
        NSLog(@"view height: %f",viewHeight);
        if (quotedViewBottom.constant == 0.0f) {
            quotedViewBottom.constant = calculatedHeight;
            webViewHeight.constant = calculatedHeight;
            //btnTitle = @"Hide";
            [self.btnCrossWebview setHidden:NO];
            [self.webView setHidden:NO];
            if (self.attachments.count>0) {
                [self.btnAttcahments setHidden:YES];
            }
        }
        else {
            if (self.attachments.count>0) {
                [self.btnAttcahments setHidden:NO];
            }
            [self.btnCrossWebview setHidden:YES];
            [self.webView setHidden:YES];
            quotedViewBottom.constant = 0.0f;
        }
        [self.view setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25f animations:^{
            [self.view layoutIfNeeded];
        }];
    });
    if (btn.tag == 1990) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            btn.tag = 1991;
            [self setZoomLevelForWebview:self.webView];
        });
    }
}

- (IBAction) btnCloseSelectAccountView:(id)sender
{
    [self.autoCompleteTableView setHidden:YES];
    [self.autoCompleteContainerView setHidden:YES];
}

#pragma - mark UITableView data source

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select Account";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 1875) {
        if (self.attachments != nil) {
            return self.attachments.count;
        }
        [self.btnAttcahments setHidden:YES];
    }
    else {
        if (isAutoCompleteForAccountsList) {
            return dataArray.count;
        }
        return self.names.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1875) {
        static NSString *tableIdentifier = @"FileAttachmentCell";
        FileAttachmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FileAttachmentTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell.activityIndicator setHidden:YES];
        [cell.viewSep1 setHidden:YES];
        [cell.bgview setHidden:YES];
        id object = [self.attachments objectAtIndex:indexPath.row];
        if ([object isKindOfClass:[NSData class]]) {
            cell.imgFile.image = [UIImage imageNamed:@"photo_icon"];
            cell.lblFileName.text = [NSString stringWithFormat:@"Attachment_%ld",indexPath.row+1];
        }
        else {
            MCOAttachment * attachment = [self.attachments objectAtIndex:indexPath.row];
            cell.imgFile.image = [UIImage imageNamed:[Utilities getImageNameForMimeType:attachment.mimeType]];
            cell.lblFileName.text = attachment.filename;
        }
        if (indexPath.row == self.attachments.count-1) {
            cell.viewSep.hidden = YES;
        }
        else {
            cell.viewSep.hidden = NO;
        }
        [cell.arrowView setHidden:YES];
        [cell.btnRemoveAttachment setHidden:NO];
        [cell.btnRemoveAttachment addTarget:self action:@selector(removeAttachment:) forControlEvents:UIControlEventTouchUpInside];
        cell.btnRemoveAttachment.tag = indexPath.row;
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else {
        static NSString *tableIdentifier = @"AutoCell";
        AutocompleteCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AutocompleteCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (isAutoCompleteForAccountsList) {
            NSManagedObject * data = dataArray[indexPath.row];
            NSString * email = [data valueForKey:kUSER_EMAIL];
            cell.lblEmail.text = email;
            cell.lblName.text = @"";
            //if ([self.selectedNames containsObject:name]) {
            //     cell.accessoryType = UITableViewCellAccessoryCheckmark;
            //}else {
            //     cell.accessoryType = UITableViewCellAccessoryNone;
            //}
        }
        else {
            NSManagedObject * nameObject = self.names[indexPath.row];
            NSString *email = [nameObject valueForKey:kEMAIL_TITLE];
            NSString *nam = [nameObject valueForKey:kSENDER_NAME];
            cell.lblName.text = nam;
            cell.lblEmail.text = email;
        }
        return cell;
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1875) {
        return 44.0f;
    }
    return 44.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
#pragma - mark UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1876) {
        if (isAutoCompleteForAccountsList) {
            self.fieldFrom.text = @"";
            NSManagedObject * obj = [dataArray objectAtIndex:indexPath.row];
            NSString * email = [obj valueForKey:kUSER_EMAIL];
            NSString *userName = [obj valueForKey:kUSER_NAME];
            self.fieldFrom.text = email;
            [self.senderData removeAllObjects];
            [self.senderData addObject:userName];
            [self.senderData addObject:email];
            [self.autoCompleteContainerView setHidden:YES];
            [self.autoCompleteTableView setHidden:YES];
            
        }
        else {
            NSManagedObject * object = [self.names objectAtIndex:indexPath.row];
            NSString * email = [object valueForKey:kEMAIL_TITLE];
            NSString * names = [object valueForKey:kSENDER_NAME];
            NSLog(@"NAME: %@",names);
            NSLog(@"EMAIL: %@",email);
            
            CLToken *token = [[CLToken alloc] initWithDisplayText:email context:nil];
            if (self.tokenInputView.isEditing) {
                [self.tokenInputView addToken:token];
            }
            else if(self.ccTokenInputView.isEditing){
                [self.ccTokenInputView addToken:token];
            }
            else if(self.bccTokenInputView.isEditing){
                [self.bccTokenInputView addToken:token];
            }
        }
        return;
    }
    
    if (self.attachments.count >= indexPath.row) {
        self.attachmentsTempUrl = [Utilities saveAttachmentsToTempPath:self.attachments];
        [self openQLPreviewControllerWithIndex:indexPath.row];
    }

}

#pragma mark - SnoozeViewDelegate
- (void) snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply {
    if (viewType == 3) {
        BOOL isDeafult = YES;
        NSLog(@"index: %d",view.selectedIndex);
        NSMutableArray * array = [CoreDataManager fetchSendlaterPreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
        NSManagedObject * object = [array objectAtIndex:view.selectedIndex-2];
        int preferenceId = [[object valueForKey:kPREFERENCE_ID] intValue];
        int hour = [[object valueForKey:kSEND_HOUR_COUNT] intValue];
        int minutes = [[object valueForKey:kSEND_MINUTE_COUNT] intValue];
        NSDate * date = [Utilities calculateDateWithHours:hour minutes:minutes preferenceId:preferenceId currentEmail:currentEmail userId:userId emailData:nil onlyIfNoReply:ifNoReply viewType:[view getTableViewType]];
        if (date == nil) {
            return;
        }
        NSLog(@"before format: %@",date);
        [self saveScheduledEmailForDate:date];
    }
    else {
        ComposeQuickResponseViewController * composeQuickResponseViewController = [[ComposeQuickResponseViewController alloc] initWithNibName:@"ComposeQuickResponseViewController" bundle:nil];
        [self.navigationController pushViewController:composeQuickResponseViewController animated:YES];
    }
}

- (void) snoozeView:(SnoozeView *)view didTapEditButton:(int)viewType {
    if (viewType == 3) {
            CustomizeSendLaterViewController *customizeSendLaterViewController = [[CustomizeSendLaterViewController alloc] initWithNibName:@"CustomizeSendLaterViewController" bundle:nil];
            [self.navigationController pushViewController:customizeSendLaterViewController animated:YES];
    }
}

- (void) snoozeView:(SnoozeView *)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply {
    if (view.getTableViewType == 3) {
        if (Index == 0) {
            [self openPickerViewForIndex:Index];
        }
        return;
    }
    if (quickResponses) {
        quickResponses = nil;
        quickResponses = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
        NSManagedObject * object = [quickResponses objectAtIndex:Index];
        [self processQuickResponse:object];
        
    }
}
-(void)processQuickResponse:(NSManagedObject *)object {
    if (object == nil) {
        return;
    }
    NSString * responseString = [object valueForKey:kQUICK_REPONSE_HTML];
    [textEditor importHtml:[NSString stringWithFormat:@"%@ %@",[textEditor exportHtml], responseString ]];
    if ([[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue]) {
        if (self.attachments == nil) {
            self.attachments = [[NSMutableArray alloc] init];
        }
        [self showProgressHudWithTitle:@"" mode:MBProgressHUDModeIndeterminate];
        NSString * url = [object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH];
        if (self.img == nil) {
            self.img = [[UIImageView alloc] init];
        }
        
        [self.img sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageHighPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //... completion code here ...
            [self hideProgressHud];
            if (error == nil) {
                NSData * imageData = UIImageJPEGRepresentation(image, 1.0);
                NSLog(@"bytes = %lu",(unsigned long)imageData.length)   ;
                NSLog(@"File size is : %.5f MB",(float)imageData.length/1024.0f/1024.0f);
                double size = (double)imageData.length/1024.0f/1024.0f;
                NSLog(@"FILE SIZE = %f",size);
                totalAttachmentSize+=size;
                NSLog(@"TOTAL SIZE = %f",totalAttachmentSize);
                if (totalAttachmentSize>25) {
                    totalAttachmentSize-=size;
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Attachment Error!!" message:@"The file size exceeds the 25 MB attachment limit." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                    return;
                }
                NSString * path =  [[SDImageCache sharedImageCache] defaultCachePathForKey:url];
                NSLog(@"path = %@", path);
                [self.attachments addObject:imageData];
                [self.btnAttcahments setHidden:NO];
                [self.attachmentTableView reloadData];
            }
            else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
        
        
        //            [self.img setImageWithURL:[NSURL URLWithString:url]
        //                     placeholderImage:[UIImage imageNamed:@""]
        //                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //                                //... completion code here ...
        //                                NSString * path =  [[SDImageCache sharedImageCache] defaultCachePathForKey:url];
        //                                NSLog(@"path = %@", path);
        //                                [self.attachments addObject:path];
        //                                [self hideProgressHud];
        //                            }];
        
        
    }
    //    UIColor * textColor = self.txtWritingArea.textColor;
    //    if ([textColor isEqual:[UIColor lightGrayColor]]) {
    //        self.txtWritingArea.textColor = [UIColor blackColor];
    //        self.txtWritingArea.text = @"";
    //    }
    
    //
    //    self.txtWritingArea.text = [NSString stringWithFormat:@"%@%@",self.txtWritingArea.text, responseString ];
}
-(void)openPickerViewForIndex:(int)index {
    datePickerView.delegate = nil;
    datePickerView = nil;
    
    datePickerView = [[[NSBundle mainBundle] loadNibNamed:@"DatePickerView" owner:self options:nil] objectAtIndex:0];
    datePickerView.showHoursPicker = NO;
    [datePickerView setupViewWithTitle:@"Pick Date/Time"];
    datePickerView.delegate = self;
    
    [datePickerView setDatePickerMode:UIDatePickerModeDateAndTime];
    [self.view addSubview:datePickerView];
    datePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:datePickerView forParent:self.view topValue:0.0f];
}

#pragma - mark DatePickerView
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit) fromDate:date];
    [components setSecond:0];
    [self saveScheduledEmailForDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
}
-(void)removeDelegates {
    if (datePickerView != nil) {
        datePickerView.delegate = nil;
        datePickerView = nil;
    }
    if (sendMessage) {
        sendMessage.delegate = nil;
        sendMessage = nil;
    }
    if (snoozeView) {
        snoozeView.delegate = nil;
        snoozeView = nil;
    }
    if (imapSessionManager) {
        imapSessionManager.strongDelegate = nil;
        imapSessionManager = nil;
    }
    if (contentFetchManager) {
        contentFetchManager.delegate = nil;
        contentFetchManager = nil;
    }
}
-(void)saveScheduledEmailForDate:(NSDate *)date {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *sendTime = [df stringFromDate:date];
    NSLog(@"%@", sendTime);
    BOOL value = [self validateMessage:kNewEmail];
    if (!value) {
        return;
    }
    [self showProgressHudWithTitle:@"" mode:MBProgressHUDModeAnnularDeterminate];
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:kSECRET forKey:@"secret"];
    [dictionary setObject:self.fieldFrom.text forKey:@"sender"];
    [dictionary setObject:self.toAddresses forKey:@"to"];
    [dictionary setObject:self.ccAddresses forKey:@"cc"];
    [dictionary setObject:self.bccAddresses forKey:@"bcc"];
    [dictionary setObject:sendTime forKey:@"send_time"];
    [dictionary setObject:[self.sendingData objectAtIndex:0] forKey:@"subject"];
    [dictionary setObject:[self.sendingData objectAtIndex:1] forKey:@"message"];
    [dictionary setObject:[NSString stringWithFormat:@"%llu",self.message.gmailThreadID] forKey:@"thread_id"];
    if (self.mailType == kNewEmail) {
        [dictionary setObject:@"" forKey:@"references"];
    }
    else if (self.mailType == kReply || self.mailType == kReplyAll || self.mailType == kForward) {
        [dictionary setObject:self.message.header.references forKey:@"references"];
        [dictionary setObject:self.message.header.messageID forKey:@"in_reply_to"];
    }
    [dictionary setObject:[Utilities getDeviceIdentifier] forKey:@"device_token"];
    NSLog(@"dictionary = %@", dictionary);
    MBProgressHUDMode mode = MBProgressHUDModeIndeterminate;
    NSString * sign = @"";
    BOOL attachmentAvailable = NO;
    if (self.attachments.count>0) {
        mode = MBProgressHUDModeAnnularDeterminate;
        sign = @"0%";
        attachmentAvailable = YES;
        [dictionary setObject:self.attachments forKey:@"images"];
    }
    [self showProgressHudWithTitle:sign mode:mode];
    [[WebServiceManager sharedServiceManager] saveScheduledEmail:dictionary withAttchament:attachmentAvailable completionBlock:^(id response) {
        [self hideProgressHud];
        [self popViewController];
        [self removeDelegates];
    }onError:^(NSString * resultMessage, int errorCode) {
        [self hideProgressHud];
        [self showAlertWithTitle:@"Error!" andMessage:@"Cannot save email. Please try again." withDelegate:nil];
    }onProgress:^(NSProgress * progress) {
        NSLog(@"progress: %f",progress.fractionCompleted*100);
        hud.progressObject = progress;
        hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
    }];
}

- (void)updateScheduledEmail {
    BOOL value = [self validateMessage:kNewEmail];
    if (!value) {
        return;
    }
    [self showProgressHudWithTitle:@"" mode:MBProgressHUDModeAnnularDeterminate];
    NSMutableDictionary * dictionary = _sendLaterObject;
    [dictionary setObject:kSECRET forKey:@"secret"];
    [dictionary setObject:self.fieldFrom.text forKey:@"sender"];
    [dictionary setObject:self.toAddresses forKey:@"to"];
    [dictionary setObject:self.ccAddresses forKey:@"cc"];
    [dictionary setObject:self.bccAddresses forKey:@"bcc"];
    [dictionary setObject:[self.sendingData objectAtIndex:0] forKey:@"subject"];
    [dictionary setObject:[self.sendingData objectAtIndex:1] forKey:@"message"];
    [dictionary setObject:[NSString stringWithFormat:@"%llu",self.message.gmailThreadID] forKey:@"thread_id"];
    if (self.mailType == kNewEmail) {
        [dictionary setObject:@"" forKey:@"references"];
    }
    else if (self.mailType == kReply || self.mailType == kReplyAll || self.mailType == kForward) {
        [dictionary setObject:self.message.header.references forKey:@"references"];
        [dictionary setObject:self.message.header.messageID forKey:@"in_reply_to"];
    }
    NSLog(@"dictionary = %@", dictionary);
    MBProgressHUDMode mode = MBProgressHUDModeIndeterminate;
    NSString * sign = @"";
    BOOL attachmentAvailable = NO;
    if (self.attachments.count>0) {
        mode = MBProgressHUDModeAnnularDeterminate;
        sign = @"0%";
        attachmentAvailable = YES;
        [dictionary setObject:self.attachments forKey:@"images"];
    }
    [self showProgressHudWithTitle:sign mode:mode];
    
    if (_isSendLater) {
        [[WebServiceManager sharedServiceManager] editScheduledEmail:dictionary withAttchament:attachmentAvailable completionBlock:^(id response) {
            [self hideProgressHud];
            [self popViewController];
            [self removeDelegates];
        }onError:^(NSString * resultMessage, int errorCode) {
            [self hideProgressHud];
            [self showAlertWithTitle:@"Error!" andMessage:@"Cannot save email. Please try again." withDelegate:nil];
        }onProgress:^(NSProgress * progress) {
            NSLog(@"progress: %f",progress.fractionCompleted*100);
            hud.progressObject = progress;
            hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
        }];
        return;
    }
    
    [[WebServiceManager sharedServiceManager] editScheduledEmail:dictionary withAttchament:attachmentAvailable completionBlock:^(id response) {
        [self hideProgressHud];
        [self popViewController];
        [self removeDelegates];
    }onError:^(NSString * resultMessage, int errorCode) {
        [self hideProgressHud];
        [self showAlertWithTitle:@"Error!" andMessage:@"Cannot save email. Please try again." withDelegate:nil];
    }onProgress:^(NSProgress * progress) {
        NSLog(@"progress: %f",progress.fractionCompleted*100);
        hud.progressObject = progress;
        hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
    }];
}
#pragma mark - CLTokenInputViewDelegate

- (void)tokenInputView:(CLTokenInputView *)view didChangeText:(NSString *)text {
    emailString = text;
    [self saveEmailInToken:text forTag:view.tag];
    isAutoCompleteForAccountsList = NO;
    if (![Utilities isValidString:text]) {
        self.autoCompleteTableView.hidden = YES;
        [self.autoCompleteContainerView setHidden:YES];
    } else {
        self.names = [CoreDataManager fetchAutocompleteContactsforString:text userId:userId];
        if (self.names.count > 0) {
            self.autoCompleteTableView.hidden = NO;
            [self.autoCompleteContainerView setHidden:NO];
        }
        else {
            self.autoCompleteTableView.hidden = YES;
            [self.autoCompleteContainerView setHidden:YES];
        }
    }
    
    autoCompleteContainerViewTopConstraint.constant = self.toView.frame.origin.y;
    
    [self.autoCompleteTableView reloadData];
}

- (void)tokenInputView:(CLTokenInputView *)view didAddToken:(CLToken *)token {
    NSString *email = token.displayText;
    if (view.tag == 198) {
        [self.toAddresses addObject:email];
    }
    else if (view.tag == 199) {
        [self.ccAddresses addObject:email];
    }
    else if (view.tag == 200) {
        [self.bccAddresses addObject:email];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGFloat toViewHeight = self.toView.frame.size.height;
        CGFloat ccViewHeight = self.ccView.frame.size.height;
        CGFloat scrollViewHeight = 0.0f;
        //scrollViewHeight = ccViewHeight + toViewHeight;
        if (toViewHeight>54.0f) {
            if (toViewHeight>toViewLastHeight) {
                scrollViewHeight = toViewHeight-toViewLastHeight;
            }
            else if (toViewHeight<toViewLastHeight) {
                scrollViewHeight = toViewLastHeight-toViewHeight;
            }
            toViewLastHeight = toViewHeight;
        }
        if (scrollViewHeight>0.0f) {
            [self setScrollViewConstant:containerViewHeight.constant + scrollViewHeight];
            scrollViewHeight = 0.0f;
        }
        
        if (!isCcViewHidden) {// only consider cc & bcc height here
            if (ccViewHeight>ccViewLastHeight) {
                scrollViewHeight = ccViewHeight-ccViewLastHeight;
            }
            else if (ccViewHeight<ccViewLastHeight) {
                scrollViewHeight = ccViewLastHeight-ccViewHeight;
            }
            ccViewLastHeight = ccViewHeight;
        }
        
        if (scrollViewHeight!=0.0f) {
            [self setScrollViewConstant:containerViewHeight.constant + scrollViewHeight];
        }
        NSLog(@"ToView Height = %f", toViewHeight);
        NSLog(@"ccView Height = %f", ccViewHeight);
        NSLog(@"scrollView Height = %f", scrollViewHeight);
    });
}

- (void)tokenInputView:(CLTokenInputView *)view didRemoveToken:(CLToken *)token {
    NSString *email = token.displayText;
    if (view.tag == 198) {
        [self.toAddresses removeObject:email];
    }
    else if (view.tag == 199) {
        [self.ccAddresses removeObject:email];
    }
    else if (view.tag == 200) {
        [self.bccAddresses removeObject:email];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGFloat toViewHeight = self.toView.frame.size.height;
        CGFloat ccViewHeight = self.ccView.frame.size.height;
        CGFloat scrollViewHeight = 0.0f;
        //scrollViewHeight = ccViewHeight + toViewHeight;
        //if (toViewHeight>=54.0f) {
        if (toViewHeight>toViewLastHeight) {
            scrollViewHeight = toViewHeight-toViewLastHeight;
        }
        else if (toViewHeight<toViewLastHeight) {
            scrollViewHeight = toViewLastHeight-toViewHeight;
            scrollViewHeight = -scrollViewHeight;
        }
        toViewLastHeight = toViewHeight;
        //}
        if (scrollViewHeight>0.0f) {
            [self setScrollViewConstant:containerViewHeight.constant + scrollViewHeight];
            scrollViewHeight = 0.0f;
        }
        
        if (!isCcViewHidden) {// only consider cc & bcc height here
            if (ccViewHeight>ccViewLastHeight) {
                scrollViewHeight = ccViewHeight-ccViewLastHeight;
            }
            else if (ccViewHeight<ccViewLastHeight) {
                scrollViewHeight = ccViewLastHeight-ccViewHeight;
                scrollViewHeight = -scrollViewHeight;
            }
            ccViewLastHeight = ccViewHeight;
        }
        
        if (scrollViewHeight!=0.0f) {
            [self setScrollViewConstant:containerViewHeight.constant + scrollViewHeight];
        }
        NSLog(@"ToView Height = %f", toViewHeight);
        NSLog(@"ccView Height = %f", ccViewHeight);
        NSLog(@"scrollView Height = %f", scrollViewHeight);
    });
}

- (CLToken *)tokenInputView:(CLTokenInputView *)view tokenForText:(NSString *)text {
    //    if (self.filteredNames.count > 0) {
    //        NSString *matchingName = self.filteredNames[0];
    //        CLToken *match = [[CLToken alloc] initWithDisplayText:matchingName context:nil];
    //        return match;
    //    }
    // TODO: Perhaps if the text is a valid phone number, or email address, create a token
    // to "accept" it.
    return nil;
}

- (void)tokenInputViewDidEndEditing:(CLTokenInputView *)view {
    NSString * txt = view.textField.placeholder;
    NSLog(@"holder = %@;;", txt);
    if (textEditor !=nil && [txt isEqualToString:@"  "]) {
        // [textEditor displayToolbar];
    }
    if ([Utilities isValidString:emailString]) {
        [self saveEmailInToken:[NSString stringWithFormat:@"%@,",emailString] forTag:view.tag];
    }
    view.accessoryView = nil;
}

- (void)tokenInputViewDidBeginEditing:(CLTokenInputView *)view {
    if (textEditor !=nil ) {
        //[self hideQuickResponseButton];
        quickResponseBottom = 0;
        [self.btnQuickResponse setHidden:YES];
        [textEditor dismissToolbar];
    }
    currentTag = view.tag;
    NSLog(@"token input view did begin editing: %@", view);
    //view.accessoryView = [self contactAddButton];
    /*[self.containerView removeConstraint:tableViewTopLayoutConstraint];
    tableViewTopLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.autoCompleteTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self.containerView addConstraint:tableViewTopLayoutConstraint];
    [self.containerView layoutIfNeeded];
     */
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"Compose email..."]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Compose email...";
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message withDelegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - SendMessageManagerDelegate
-(void)sendMessageManager:(SendMessageManager *)manager emailSentSuccessfullyTo:(NSString*)to {
    if ((self.mailType == kForward || self.mailType == kReplyAll || self.mailType == kReply || self.mailType == kNewEmail) && self.isDraft == NO) {
        //[self popViewController];
        [self removeDelegates];
    }
    else {
        if (self.draftObject != nil) {
            [self deleteOldDraftWithSucessMessage:@"Email Sent" deletLocalCopy:YES newUid:-1];
        }
        else {
            //[self popViewController];
            [self removeDelegates];
        }
    }
}
-(void)sendMessageManager:(SendMessageManager *)manager didRecieveError:(NSError*)error {
    [self hideProgressHud];
    [self showAlertWithTitle:@"Error" andMessage:error.localizedDescription withDelegate:nil];
}
-(void)sendMessageManager:(SendMessageManager *)manager draftSavedSuccessfullyWithId:(long)uid {
    
    if (self.draftObject != nil && self.isDraft) {// existing draft edited locally
        [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:[MCOIndexSet indexSetWithIndex:uid] fromFolder:kFOLDER_DRAFT_MAILS withSessaion:self.imapSession requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
            if (error == nil) {
                for (int i = 0; i <messages.count ; ++i) {
                    MCOIMAPMessage* message = [messages objectAtIndex:i];
                    long count = 0;
                    if ( message.flags == 0 ) {
                        count = 1;
                    }
                    long usrId = [[self.draftObject valueForKey:kUSER_ID] longLongValue];
                    NSString * strUid = [Utilities getStringFromLong:usrId];
                    [Utilities saveEmailModelForMessage:message unreadCount:count isThreadEmail:NO mailFolderName:kFOLDER_DRAFT_MAILS isSent:NO isTrash:NO isArchive:NO isDarft:YES draftFetchedFromServer:YES isConversation:NO isInbox:NO userId:strUid isFakeDraft:NO enitity:kENTITY_EMAIL];
                    
                    [self deleteOldDraftWithSucessMessage:@"Draft Saved." deletLocalCopy:YES newUid:uid];
                }
            }
            else {
            }
        }onError:^(NSError* error) {
        }];
        
        //[self deleteOldDraftWithSucessMessage:@"Draft Saved." deletLocalCopy:YES newUid:uid];
    }
    else {
        
        /* fetch new draft for saving locally */
        //[self popViewController];
        
        [[MailCoreServiceManager sharedMailCoreServiceManager] fetchMessageForIndexSet:[MCOIndexSet indexSetWithIndex:uid] fromFolder:kFOLDER_DRAFT_MAILS withSessaion:self.imapSession requestKind:[Utilities getImapRequestKind] completionBlock:^(NSError* error, NSArray *messages ,MCOIndexSet *vanishedMessages) {
            
            if (error == nil) {
                for (int i = 0; i <messages.count ; ++i) {
                    MCOIMAPMessage* message = [messages objectAtIndex:i];
                    long count = 0;
                    if (message.flags == 0) {
                        count = 1;
                    }
                    
                    NSMutableArray * cloneDrafts = [CoreDataManager fetchFakeDraftForId:cloneId];
                    for (int x = 0; x<cloneDrafts.count; ++x) {
                        NSManagedObject * cloneObject = [cloneDrafts objectAtIndex:x];
                        [CoreDataManager deleteObject:cloneObject];
                    }
                    [CoreDataManager updateData];
                    
                    [Utilities saveEmailModelForMessage:message unreadCount:count isThreadEmail:NO mailFolderName:kFOLDER_DRAFT_MAILS isSent:NO isTrash:NO isArchive:NO isDarft:YES draftFetchedFromServer:YES isConversation:NO isInbox:NO userId:userId isFakeDraft:NO enitity:kENTITY_EMAIL];
                    
                    [self removeDelegates];
                }
            }
            else {
                [self removeDelegates];
                [self showSuccessMessage:@"Something went wrong!!! Cannot Save Draft."];
            }
        }onError:^(NSError* error) {
            [self removeDelegates];
        }];
    }
}
#pragma - mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self popViewController];
}
#pragma - mark UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        self.mailType = kDraft;
        [self sendMessageWithCase:kDraft];
    }
    else {
        [self removeDelegates];
        [self popViewController];
    }
}
#pragma - mark MCOIMAPSessionManagerDelegate

-(void)MCOIMAPSessionManager:(MCOIMAPSessionManager *)manager sessionCreatedWithObject:(MCOIMAPSession *)imapSession {
    self.imapSession = imapSession;
}
#pragma - mark MCOIMAPFetchContentOperationManagerDelegate
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didReceiveHtmlBody:(NSString *)htmlBody andMessagePreview:(NSString *)messagePreview atIndexPath:(NSIndexPath *)indexPath {
    if ([Utilities isValidString:messagePreview]) {
        //[self.txtWritingArea setTextColor:[UIColor blackColor]];
        //self.txtWritingArea.text = messagePreview;
        [textEditor importHtml:htmlBody];
    }
    [self.draftObject setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_BODY];
    
    if ([messagePreview length]>=50) {
        messagePreview = [messagePreview substringToIndex:50];
    }
    [self.draftObject setValue:[Utilities isValidString:messagePreview]? messagePreview : @" " forKey:kEMAIL_PREVIEW];
    [self.draftObject setValue:htmlBody forKey:kEMAIL_HTML_PREVIEW];
    [self loadWebViewWithHtmlContent:htmlBody];
    [self.draftObject setValue:0 forKey:kUNREAD_COUNT];
    [CoreDataManager updateData];
    [self hideProgressHud];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didRecieveError:(NSError *)error {
    [self hideProgressHud];
    //UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Something went wrong!!! Cannot fetch message body" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    //[alert show];
}
-(void)MCOIMAPFetchContentOperation:(MCOIMAPFetchContentOperationManager *)operation didUpdateAccessTokenSuccessfullyWithSession:(MCOIMAPSession *)seesion {
    NSString * folder = [self.draftObject valueForKey:kMAIL_FOLDER];
    int uid = [[self.draftObject valueForKey:kEMAIL_ID] intValue];
    [contentFetchManager startFetchOpWithFolder:folder andMessageId:uid forNSManagedObject:self.draftObject nsindexPath:nil needHtml:YES];
}

#pragma - mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
}
#pragma - mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textEditor !=nil) {
        quickResponseBottom = 0;
        [self.btnQuickResponse setHidden:YES];
        [textEditor dismissToolbar];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textEditor !=nil) {
        [textEditor dismissToolbar];
    }
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    if (textEditor !=nil) {
        [textEditor displayToolbar];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textEditor !=nil) {
        [textEditor displayToolbar];
    }
}

-(void)dealloc {
    NSLog(@"dealloc : EmailComposerViewController");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    //[[NSNotificationCendraft sent or ter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kEDITOR_ACTIVE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNOTIFICATION_SEND_LATER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kATTACHMENT_DOWNLOADED object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
