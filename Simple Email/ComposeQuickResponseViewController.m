//
//  ComposeQuickResponseViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ComposeQuickResponseViewController.h"
#import "Constants.h"
#import "Utilities.h"
#import "CustomKeyBoardToolBar.h"
#import "QuickResponseSyncManager.h"
#import "TextEditorViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "AttachmentViewerViewController.h"
#import "MBProgressHUD.h"

@interface ComposeQuickResponseViewController ()

@end

@implementation ComposeQuickResponseViewController {
    NSString * userId;
    NSString * currentEmail;
    TextEditorViewController * textEditor;
    TextEditorViewController * titleEditor;
    NSData * imageData;
    MBProgressHUD *hud;
    BOOL isNew;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
}
#pragma - mark Private Methods
-(void)setUpView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveQuickResponseNotification:) name:kNSNOTIFICATIONCENTER_QUICKREPONSE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveimageUploadedNotification:) name:kIMAGE_UPLOADED object:nil];
    if (titleEditor == nil) {
        titleEditor = [[TextEditorViewController alloc] initWithNibName:@"TextEditorViewController" bundle:nil];
        [titleEditor importHtml:@"Title...."];
        [self displayContentController:titleEditor];
    }
    if (textEditor == nil) {
        textEditor = [[TextEditorViewController alloc] initWithNibName:@"TextEditorViewController" bundle:nil];
        [self displayContentController:textEditor];
    }
    if (self.object != nil) {
        NSString * str = [self.object valueForKey:kQUICK_REPONSE_HTML];
        NSString * title = [self.object valueForKey:kQUICK_REPONSE_Title];
        if ([Utilities isValidString:str]) {
            [textEditor importHtml:str];
        }
        if ([Utilities isValidString:title]) {
            [titleEditor importHtml:title];
        }
    }
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    
    currentEmail = [object valueForKey:kUSER_EMAIL];
    
    /*[self.txtView becomeFirstResponder];
     CustomKeyBoardToolBar *customKeyBoardToolBar  =   [[[NSBundle mainBundle] loadNibNamed:@"CustomKeyBoardToolBar" owner:self options:nil] objectAtIndex:0];
     customKeyBoardToolBar.delegate = self;
     self.txtView.inputAccessoryView = customKeyBoardToolBar;
     self.txtView.autocorrectionType = UITextAutocorrectionTypeNo;
     customKeyBoardToolBar.btnSendLater.hidden = YES;*/
    
    [self.navigationController.navigationBar setHidden:NO];
    self.title = @"Compose Quick Response";
    UIBarButtonItem * btnNavClock=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_save"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(btnSaveAction:)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnNavClock, nil ];
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_attachment_white"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(btnAttachmentAction:)];
    UIBarButtonItem * btncross=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(btnCrossActions:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:btncross,btnMenu, nil ];
}
- (void) displayContentController: (TextEditorViewController*) content {
    
    [self addChildViewController:content];
    //content.view.bounds = self.txtWritingArea.bounds;
    //content.view.frame = self.txtWritingArea.frame;
    [self.view addSubview:content.view];
    content.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (content == textEditor) {
        [Utilities setLayoutConstarintsForEditorView:content.view parentView:self.view fromBottomView:self.textEditorContainerView bottomSpace:0.0f topView:self.textEditorContainerView topSpace:100.0f leadingSpace:0.0f trailingSpace:0.0f];
    }
    else if (content == titleEditor) {
        content.view.frame = CGRectMake(0, 0, content.view.frame.size.width, 100);
        [Utilities setLayoutConstarintsForEditorView:content.view parentView:self.view fromBottomView:self.textEditorContainerView bottomSpace:0.0f topView:self.textEditorContainerView topSpace:0.0f leadingSpace:0.0f trailingSpace:0.0f];
    }
    
    NSLog(@"Height : / %f", content.view.frame.size.height);
    
    [content didMoveToParentViewController:self];
}

- (void) hideContentController: (TextEditorViewController*) content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}
-(void)showPickerView {
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
-(NSMutableDictionary *)composeDictionaryWithTitle:(NSString *)title text:(NSString *)text html:(NSString *)html object:(NSManagedObject *)object {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    int type = -1;
    NSString * firebaseId = nil;
    NSString * attachmentPath = @"";
    NSString * attachmentAvailable = @"0";
    if (object == nil) {
        type = kActionInsert;
    }
    else {
        type = kActionEdit;
        
        firebaseId = [self.object valueForKey:kFIREBASE_ID];
        attachmentPath = [self.object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH];
        NSString * val = @"0";
        if ([[self.object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue]) {
            val = @"1";
        }
        attachmentAvailable = val;
        if (imageData != nil) {
            [self uploadAttachedImageWithId:firebaseId];
        }
    }
    [dictionary setObject:title forKey:kQUICK_REPONSE_Title];
    [dictionary setObject:text forKey:kQUICK_REPONSE_Text];
    [dictionary setObject:html forKey:kQUICK_REPONSE_HTML];
    [dictionary setObject:attachmentPath forKey:kQUICK_REPONSE_ATTACHMENT_PATH];
    [dictionary setObject:attachmentAvailable forKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE];
    [dictionary setObject:[Utilities encodeToBase64:currentEmail] forKey:kUSER_EMAIL];
    [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:userId performAction:type firebaseId:firebaseId];
    return dictionary;
}
-(void)uploadAttachedImageWithId:(NSString *)firebaseId {
    [self showProgressHudWithTitle:@""];
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:imageData forKey:@"data"];
    [dictionary setObject:firebaseId forKey:kFIREBASE_ID];
    [dictionary setObject:userId forKey:kUSER_ID];
    NSString * path = [NSString stringWithFormat:@"%@/images/%@",[Utilities encodeToBase64:currentEmail],firebaseId];
    [dictionary setObject:path forKey:@"path"];
    [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:userId performAction:kActionInsertAttachment firebaseId:nil];
}
#pragma - mark Custom KeyBoard Delegate
- (void) customKeyBoardBoldDelegate {
    [self.view endEditing:YES];
}
- (void) customKeyBoardItalicDelegate {
    [self.view endEditing:YES];
}
- (void) customKeyBoardSendLaterDelegate {
    [self.view endEditing:YES];
}
- (void) customKeyBoardBulletsDelegate {
    [self.view endEditing:YES];
}
- (void) customKeyBoardNotesDelegate {
    [self.view endEditing:YES];
}

#pragma - mark User Actions
-(IBAction)btnCrossActions:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
-(IBAction)btnAttachmentAction:(id)sender {
    BOOL attachmentAvailable = [[self.object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue];
    if (attachmentAvailable) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Show Attachment", @"Delete Attachment", @"Modify Attachment", nil];
        actionSheet.tag = 1022;
        actionSheet.delegate = self;
        [actionSheet showInView:self.view];
        
        return;
    }
    [self showPickerView];
}
-(IBAction)btnSaveAction:(id)sender {
    [self.view endEditing:YES];
    NSString * htmlText = [textEditor exportHtml]; //self.txtView.text;
    NSString * text = [textEditor exportText];
    NSString * title = [titleEditor exportHtml];
    if ([Utilities isValidString:htmlText] && [Utilities isValidString:title]) {
        if (self.object) { /* edited quick response */
            isNew = NO;
            [self composeDictionaryWithTitle:title text:text html:htmlText object:self.object];
        }
        else { /* new quick response */
            isNew = YES;
            [self composeDictionaryWithTitle:title text:text html:htmlText object:nil];
        }
    }
    else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error!!" message:@"Cannot save empty quick response" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    }
    if (imageData == nil) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma - mark UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    
    if (buttonIndex == 0) { /* Show Attachment */
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        SWRevealViewController * rvc = [appDelegate getRootView];
        AttachmentViewerViewController * attachmentVC = [[AttachmentViewerViewController alloc] initWithNibName:@"AttachmentViewerViewController" bundle:nil];
        NSString * url = [self.object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH];
        [attachmentVC showImageWithUrl:url];
        UINavigationController * nv = [[UINavigationController alloc] initWithRootViewController:attachmentVC];
        [rvc presentViewController:nv animated:YES completion:nil];
    }
    else if(buttonIndex == 1) { /* Delete Attachment */
        NSString * firebaseId = [self.object valueForKey:kFIREBASE_ID];
        if ([[self.object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue]) {
            NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
            [dictionary setObject:firebaseId forKey:kFIREBASE_ID];
            [dictionary setObject:userId forKey:kUSER_ID];
            NSString * path = [NSString stringWithFormat:@"%@/images/%@",[Utilities encodeToBase64:currentEmail],firebaseId];
            [dictionary setObject:path forKey:@"path"];
            [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:userId performAction:kActionDeleteAttachment firebaseId:nil];
        }
    }
    else if (buttonIndex == 2) { /* modify attachment */
        [self showPickerView];
    }
    
}
-(void) receiveQuickResponseNotification:(NSNotification*)notification {
    if ([notification.name isEqualToString:kNSNOTIFICATIONCENTER_QUICKREPONSE]) {
        NSDictionary* userInfo = notification.userInfo;
        NSLog (@"Successfully received test notification! %@", userInfo);
        if (imageData != nil && self.object == nil) {
            [self uploadAttachedImageWithId:[userInfo objectForKey:kFIREBASE_ID]];
        }
    }
}
-(void) receiveimageUploadedNotification:(NSNotification*)notification {
    if ([notification.name isEqualToString:kIMAGE_UPLOADED]) {
        NSDictionary* userInfo = notification.userInfo;
        [self hideProgressHud];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    imageData = UIImageJPEGRepresentation(chosenImage, 1.0);
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"bytes = %lu",(unsigned long)imageData.length)   ;
    NSLog(@"File size is : %.5f MB",(float)imageData.length/1024.0f/1024.0f);
    
    double size = (double)imageData.length/1024.0f/1024.0f;
    NSLog(@"size = %f",size );
    
    if (size>25) {
        imageData = nil;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Attachment Error!!" message:@"The file size exceeds the 25 MB attachment limit." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    }
    
    //    if (imageData != nil && self.object != nil) {
    //        [self uploadAttachedImageWithId:[self.object valueForKey:kFIREBASE_ID]];
    //    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
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
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNSNOTIFICATIONCENTER_QUICKREPONSE
                                                  object:nil];
    NSLog(@"dealloc - ComposeQuickResponseViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
