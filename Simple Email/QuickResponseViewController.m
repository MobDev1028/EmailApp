//
//  QuickResponseViewController.m
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "QuickResponseViewController.h"
#import "SWRevealViewController.h"
#import "QuickResponseTableViewCell.h"
#import "ComposeQuickResponseViewController.h"
#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "QuickResponseSyncManager.h"
#import "AttachmentViewerViewController.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"

@interface QuickResponseViewController ()

@end

@implementation QuickResponseViewController {
    //NSMutableArray * responseTtile;
    BOOL allowTxtFieldEdit;
    NSString * userId;
    NSString *  currentEmail;
    MBProgressHUD *hud;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    
    currentEmail = [object valueForKey:kUSER_EMAIL];
    [self refreshTableView];
}
#pragma - mark Private Methods
-(void)setUpView {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:kNSNOTIFICATIONCENTER_QUICKREPONSE object:nil];
    
    allowTxtFieldEdit = NO;
    
    [self.responseTableView setBackgroundView:nil];
    [self.responseTableView setBackgroundColor:[UIColor clearColor]];
    self.responseTableView.allowsSelectionDuringEditing = YES;
    
    
    [self.navigationController.navigationBar setHidden:NO];
    self.title = @"Quick Response";
    [self addRightSideButtonWithUIBarButtonSystemItem:UIBarButtonSystemItemEdit];
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[self revealViewController]
                                                             action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = btnMenu;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}
-(void)deleteFirebaseObject:(NSManagedObject *)object {
    NSString * firebaseId = [object valueForKey:kFIREBASE_ID];
    if ([[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue]) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setObject:firebaseId forKey:kFIREBASE_ID];
        [dictionary setObject:userId forKey:kUSER_ID];
        NSString * path = [NSString stringWithFormat:@"%@/images/%@",[Utilities encodeToBase64:currentEmail],firebaseId];
        [dictionary setObject:path forKey:@"path"];
        [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:userId performAction:kActionDeleteAttachment firebaseId:nil];
    }
    [Utilities syncToFirebase:nil syncType:[QuickResponseSyncManager class] userId:userId performAction:kActionDelete firebaseId:firebaseId];
}
-(void)refreshTableView {
    self.dataArray = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail]];
    [self.responseTableView reloadData];
}
-(void)addRightSideButtonWithUIBarButtonSystemItem:(UIBarButtonSystemItem )item {
    UIBarButtonItem * btnEdit=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:item
                                                                            target:self
                                                                            action:@selector(btnEditAction:)];
    [btnEdit setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [UIFont fontWithName:@"SFUIText-Semibold" size:17]
                                     , NSFontAttributeName,
                                     [UIColor whiteColor], NSForegroundColorAttributeName,
                                     nil]
                           forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItem = btnEdit;
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
#pragma - mark User Action
-(IBAction)btnEditAction:(id)sender {
    self.responseTableView.editing = !self.responseTableView.editing;
    allowTxtFieldEdit = !allowTxtFieldEdit;
    [self.responseTableView reloadData];
    
    if (allowTxtFieldEdit) {
        [self addRightSideButtonWithUIBarButtonSystemItem:UIBarButtonSystemItemDone];
    }
    else {
        [self addRightSideButtonWithUIBarButtonSystemItem:UIBarButtonSystemItemEdit];
    }
}
-(IBAction)btnQuickResponsesAction:(id)sender {
    [self showProgressHudWithTitle:@""];
    UIButton * btn = (UIButton *)sender;
    [btn setEnabled:NO];
    for (NSManagedObject * obj in self.dataArray) {
        [self deleteFirebaseObject:obj];
    }
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [Utilities preloadQuickResponsesForEmail:[Utilities encodeToBase64:currentEmail] andUserId:userId];
        [btn setEnabled:YES];
        [self hideProgressHud];
    });
}
-(void)removeDelegates {
    
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
    
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return allowTxtFieldEdit;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    //return allowTxtFieldEdit;
    return NO;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"QuickResponseCell";
    
    QuickResponseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"QuickResponseTableViewCell" owner:self options:nil];
        cell      = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.editingAccessoryType = UITableViewCellEditingStyleNone;
    }
    
    NSManagedObject * object  = [self.dataArray objectAtIndex:indexPath.row];
    //NSLog(@"url = %@", [object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH]);
    cell.txtResponses.enabled = NO;//allowTxtFieldEdit;
    cell.imgAttachment.hidden = ![[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue];
    cell.txtResponses.text = [object valueForKey:kQUICK_REPONSE_Title];
    cell.txtResponses.delegate = self;
    cell.txtResponses.tag = indexPath.row;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.5f;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row>=self.dataArray.count) {
        return;
    }
    NSManagedObject * object = [self.dataArray objectAtIndex:indexPath.row];
    
    if (allowTxtFieldEdit) {
        ComposeQuickResponseViewController * composeQuickResponseViewController = [[ComposeQuickResponseViewController alloc] initWithNibName:@"ComposeQuickResponseViewController" bundle:nil];
        composeQuickResponseViewController.object = object;
        [self.navigationController pushViewController:composeQuickResponseViewController animated:YES];
        return;
    }
    NSString * imageUrl = [object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH];
    BOOL isAttachmentAvailable = [[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue];
    if (isAttachmentAvailable && [Utilities isValidString:imageUrl]) {
        
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        SWRevealViewController * rvc = [appDelegate getRootView];
        AttachmentViewerViewController * attachmentVC = [[AttachmentViewerViewController alloc] initWithNibName:@"AttachmentViewerViewController" bundle:nil];
        [attachmentVC showImageWithUrl:imageUrl];
        UINavigationController * nv = [[UINavigationController alloc] initWithRootViewController:attachmentVC];
        [rvc presentViewController:nv animated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject * object = [self.dataArray objectAtIndex:indexPath.row];
    [self deleteFirebaseObject:object];
    
    /*[self.dataArray removeObjectAtIndex:indexPath.row];
     [CoreDataManager deleteObject:object];
     [CoreDataManager updateData];
     
     [tableView beginUpdates];
     NSIndexPath *moreRow = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
     [self.responseTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:moreRow,nil]   withRowAnimation:UITableViewRowAnimationBottom];
     [tableView endUpdates];*/
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self updateTextLabelsWithText: newString atIndex:(int)textField.tag];
    
    return YES;
}

-(void)updateTextLabelsWithText:(NSString *)string atIndex:(int)index {
    // [responseTtile removeObjectAtIndex:index];
    //[responseTtile replaceObjectAtIndex:index withObject:string];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNSNOTIFICATIONCENTER_QUICKREPONSE
                                                  object:nil];
    NSLog(@"dealloc - QuickResponseViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
