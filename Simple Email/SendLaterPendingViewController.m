//
//  SendLaterPendingViewController.m
//  SimpleEmail
//
//  Created by JCB on 8/6/17.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "SendLaterPendingViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "WebServiceManager.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "MBProgressHUD.h"
#import "SmartInboxTableViewCell.h"
#import "CellConfigureManager.h"
#import "EmailComposerViewController.h"

@interface SendLaterPendingViewController () <JZSwipeCellDelegate>

@end

@implementation SendLaterPendingViewController {
    MBProgressHUD *hud;
    NSMutableArray *pendingEmails;
    NSIndexPath * didSelectIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SWRevealViewController *revealController = [self revealViewController];
    
    self.title = @"Send Later Pending";
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:revealController
                                                             action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = btnMenu;
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    
    [self fetchAllSendLaterPending];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchAllSendLaterPending {
//    NSString *userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
//    
//    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
//    NSManagedObject * object = [userArray lastObject];
//    
//    NSString *currentEmail = [object valueForKey:kUSER_EMAIL];
//    
//    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
//    [dictionary setValue:currentEmail forKey:@"email"];
//    MBProgressHUDMode mode = MBProgressHUDModeIndeterminate;
//    NSString * sign = @"";
//    [self showProgressHudWithTitle:sign mode:mode];
//    [[WebServiceManager sharedServiceManager] getScheduledEmail:dictionary completionBlock:^(id response) {
//        [self hideProgressHud];
//        NSMutableDictionary *data = (NSMutableDictionary*)[Utilities dataToDictionary:response];
//        pendingEmails = [data objectForKey:@"result"];
//        [self.tableView reloadData];
//    } onError:^(NSString *resultMessage, int errorCode) {
//        [self hideProgressHud];
//        [self showAlertWithTitle:@"Error!" andMessage:@"Cannot fetch emails. Please try again." withDelegate:nil];
//    } onProgress:^(NSProgress *progress) {
//        NSLog(@"progress: %f",progress.fractionCompleted*100);
//        hud.progressObject = progress;
//        hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
//    }];
    
    pendingEmails = [[NSMutableArray alloc] init];
    NSString * userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    NSMutableArray * userArray = [[NSMutableArray alloc] init];
    
    if (self.fetchMultipleAccount) {
        userArray = [CoreDataManager fetchAllUsers];
    }
    else {
        userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    }
    
    for (NSManagedObject *object in userArray) {
        NSString *email = [object valueForKey:kUSER_EMAIL];
        [self fetchPendingEmailFor:email];
    }
}

- (void)fetchPendingEmailFor:(NSString *)email {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:email forKey:@"email"];
    MBProgressHUDMode mode = MBProgressHUDModeIndeterminate;
    NSString * sign = @"";
    [self showProgressHudWithTitle:sign mode:mode];
    [[WebServiceManager sharedServiceManager] getScheduledEmail:dictionary completionBlock:^(id response) {
        [self hideProgressHud];
        NSMutableDictionary *data = (NSMutableDictionary*)[Utilities dataToDictionary:response];
        NSArray* emails = [data objectForKey:@"result"];
        for (int i = 0; i < emails.count; i++) {
            NSDictionary *dic = [emails objectAtIndex:i];
            NSMutableDictionary *emailDic = [dic mutableCopy];
            NSError *error;
            NSData *jsonData = [[emailDic objectForKey:@"to"] dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableArray *array = [NSJSONSerialization  JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            
            [emailDic removeObjectForKey:@"to"];
            [emailDic setValue:array forKey:@"to"];
            if ([[emailDic objectForKey:@"sendflag"] integerValue] == 0) {
                [pendingEmails addObject:emailDic];
            }
        }
        
        
        [self.tableView reloadData];
    } onError:^(NSString *resultMessage, int errorCode) {
        [self hideProgressHud];
        [self showAlertWithTitle:@"Error!" andMessage:@"Cannot fetch emails. Please try again." withDelegate:nil];
    } onProgress:^(NSProgress *progress) {
        NSLog(@"progress: %f",progress.fractionCompleted*100);
        hud.progressObject = progress;
        hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
    }];
}

-(void)showProgressHudWithTitle:(NSString *)title mode:(MBProgressHUDMode)mode {
    if (hud) {
        return;
    }
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = mode;
    hud.label.text = title;
}

-(void)hideProgressHud {
    if (hud) {
        [hud hideAnimated:YES];
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

#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [pendingEmails count];;
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
    NSMutableDictionary *emailData = [pendingEmails objectAtIndex:indexPath.row];
    
    [cell.imgProfile setImage:[UIImage imageNamed:@"profile_image_placeholder"]];

    [self setupSwipeCellOptionsFor:cell];
    
    return [CellConfigureManager configureInboxCell:cell withData:emailData view:self.view atIndexPath:indexPath isSent:YES];
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
    
    EmailComposerViewController * mailComposer = [[EmailComposerViewController alloc] initWithNibName:@"EmailComposerViewController" bundle:nil];
    mailComposer.isDraft = NO;
    mailComposer.isSendLater = YES;
    mailComposer.sendLaterObject = [pendingEmails objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:mailComposer animated:YES];
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
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
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


-(void)btnSwipeDeleteActionAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![Utilities isInternetActive]) {
        [self showAlertWithTitle:@"Internet error!" andMessage:[NSString stringWithFormat:@"Please check your internet connection and try again."] withDelegate:nil];
        return;
    }

    NSMutableDictionary *emailData = [pendingEmails objectAtIndex:indexPath.row];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[emailData valueForKey:@"id"] forKey:@"id"];
    
    MBProgressHUDMode mode = MBProgressHUDModeIndeterminate;
    NSString * sign = @"";
    [self showProgressHudWithTitle:sign mode:mode];
    
    [[WebServiceManager sharedServiceManager] deleteScheduledEmail:dictionary completionBlock:^(id response) {
        [self hideProgressHud];
        [pendingEmails removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
    } onError:^(NSString *resultMessage, int errorCode) {
        [self hideProgressHud];
        [self showAlertWithTitle:@"Error!" andMessage:@"Cannot Delete email. Please try again." withDelegate:nil];
    } onProgress:^(NSProgress *progress) {
        NSLog(@"progress: %f",progress.fractionCompleted*100);
        hud.progressObject = progress;
        hud.label.text = [NSString stringWithFormat:@"%.0f%%",progress.fractionCompleted*100];
    }];
}


@end
