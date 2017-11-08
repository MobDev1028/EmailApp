//
//  ManageAccountViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "ManageAccountViewController.h"
#import "Utilities.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "OAuthManager.h"
#import "MBProgressHUD.h"
#import "WebServiceManager.h"
#import "SWRevealViewController.h"
#import "SideMenuViewController.h"
#import "RegularInboxViewController.h"
#import "ManangeAccountTableViewCell.h"
#import "AddAccountFormViewController.h"
#import "AcountAlertPageViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "SharedInstanceManager.h"
#import "AccountsDetailViewController.h"

@interface ManageAccountViewController ()<OAuthManagerDelegate>

@end

@implementation ManageAccountViewController {
    MBProgressHUD *hud;
    NSString * selectedUserId;
    NSString * selectedUserMail;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isViewPresented) {
        SWRevealViewController *revealController = [self revealViewController];
        UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:revealController
                                                                 action:@selector(revealToggle:)];
        self.navigationItem.leftBarButtonItem = btnMenu;
    }
    else {
        UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_back"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(btnBackAction:)];
        self.navigationItem.leftBarButtonItem = btnMenu;
    }
    if (!self.isViewPresented) {
        self.title = @"Mail Accounts";
        [self.btnAddAccount setHidden:NO];
    }
    else {
        self.title = @"Remove Account";
        [self.btnAddAccount setHidden:YES];
    }
    [self.manageAccountTabkeView setBackgroundView:nil];
    [self.manageAccountTabkeView setBackgroundColor:[UIColor clearColor]];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self updateTableView];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTableView];
}
-(void)showProgressViewWithTitle:(NSString *)title {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
}
-(void)showLogoutAlert {
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Logout!!"
                                                      message:@"Are you sure you want to logout?"
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Yes", @"No", nil];
    [myAlert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteUser];
    }
}
-(void)deleteUser {
    NSString* uniqueIdentifier = [Utilities getDeviceIdentifier]; // IOS 6+
    if ([Utilities isValidString:uniqueIdentifier]) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setObject:selectedUserMail forKey:@"user_email"];
        [dictionary setObject:uniqueIdentifier forKey:@"device_udid"];
        [dictionary setObject:kSECRET forKey:@"secret"];
        [self showProgressViewWithTitle:@"Removing Account"];
        [[WebServiceManager sharedServiceManager] deleteUser:dictionary completionBlock:^(id response) {
            id data = [Utilities dataToDictionary:response];
            NSString * unreadCount = [data valueForKey:@"deviceUnreadCount"];
            AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate setBadgeCount:[unreadCount integerValue]];
            
            // id data = [Utilities dataToDictionary:response];
            //NSDictionary* userInfo = @{kUSER_ID: selectedUserId};
            
            //NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
            //[nc postNotificationName:kNSNOTIFICATIONCENTER_LOGOUT object:self userInfo:userInfo];
            NSError * error = [CoreDataManager wipeUser:selectedUserId];
            if(error == nil) {
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                /* Remove email listners for deleted user */
                [appDelegate removeEmailListnersForId:selectedUserId];
                
                /* remove imap shared instances for deleted user */
                [appDelegate removeImapSessionsForId:selectedUserId];
                
                NSMutableDictionary * firebaseDictionary = [[SharedInstanceManager sharedInstance] firebaseSharedInstance];
                NSMutableArray * inst = [firebaseDictionary objectForKey:selectedUserId];
                if (inst != nil) {
                    [firebaseDictionary removeObjectForKey:selectedUserId];
                }
                
                [Utilities setUserDefaultWithValue:nil andKey:kSELECTED_ACCOUNT];
                NSMutableArray * users = [CoreDataManager fetchAllUsers];
                if (users.count == 0) {
                    [appDelegate setRootViewForSignUp];
                }
                else if(users.count > 0) {
                    NSManagedObject * object = [users objectAtIndex:0];
                    NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
                    [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
                }
            }
            else {
                UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                  message:@"Cannot delete delete account data."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil, nil];
                [myAlert show];
            }
            if (hud) {
                [hud hideAnimated:YES];
            }
            [self swapViewWithDelay:0.5f indexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
        }onError:^(NSString * message, int errorCode) {
            if (hud) {
                [hud hideAnimated:YES];
            }
            UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Cannot remove account. please try again."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
            [myAlert show];
        }onProgress:^(NSProgress * progress) {
            
        }];
    }
}
-(void)swapViewWithDelay:(double)delay indexPath:(NSIndexPath *)indexPath {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        RegularInboxViewController *regularInboxViewController = [[RegularInboxViewController alloc] init];
        regularInboxViewController.renderView = YES;
        SWRevealViewController *revealController = [self revealViewController];
        UINavigationController * sideMenuNav = (UINavigationController*) revealController.rearViewController;
        NSArray* tempVCA = [(UINavigationController*) revealController.frontViewController viewControllers];
        
        for(UIViewController *tempVC in tempVCA)
        {
            if([tempVC isKindOfClass:[ManageAccountViewController class]] || [tempVC isKindOfClass:[AcountAlertPageViewController class]]) {
                [tempVC removeFromParentViewController];
            }
        }
        SideMenuViewController * sideMenu = [[sideMenuNav viewControllers] objectAtIndex:0];
        [sideMenu setPresentedRow:1 andSection:0];
        [revealController pushFrontViewController:[[UINavigationController alloc] initWithRootViewController:regularInboxViewController] animated:YES];
        
        if (self.isViewPresented) {
            if (hud) {
                [hud hideAnimated:YES];
            }
            return;
        }
        NSManagedObject * object = [self.dataArray objectAtIndex:indexPath.row];
        NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
    });
    
}
#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"ManageAccountCell";
    
    ManangeAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ManangeAccountTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSManagedObject * object = [self.dataArray objectAtIndex:indexPath.row];
    NSString * email = [object valueForKey:kUSER_EMAIL];
    cell.lblMail.text = email;
    NSString * name = [object valueForKey:kUSER_NAME];
    if (![Utilities isValidString:name]) {
        name = [[email componentsSeparatedByString: @"@"] objectAtIndex:0];
    }
    cell.lblName.text = name;
    
    NSString * url = [object valueForKey:kUSER_IMAGE_URL];
    
    [cell.imgProfilePic sd_setImageWithURL:[NSURL URLWithString:url]
                          placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
    if (self.dataArray.count-1 == indexPath.row) {
        cell.sepView.hidden = YES;
    }
    else {
        cell.sepView.hidden = NO;
    }
    return  cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 60.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isComingFromMail) {
        NSManagedObject * object1 = [self.dataArray objectAtIndex:indexPath.row];
        AccountsDetailViewController * accountsDetailViewController = [[AccountsDetailViewController alloc] initWithNibName:@"AccountsDetailViewController" bundle:nil];
        accountsDetailViewController.object = object1;
        [self.navigationController pushViewController:accountsDetailViewController animated:YES];
        return;
    }
    double delayInSeconds = 0.0;
    if (self.isViewPresented) {
        delayInSeconds = 1.0;
        NSManagedObject * object = [self.dataArray objectAtIndex:indexPath.row];
        selectedUserId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        selectedUserMail = [object valueForKey:kUSER_EMAIL];
        [self showLogoutAlert];
        return;
    }
    [self swapViewWithDelay:0.0f indexPath:indexPath];
}
#pragma - mark User Action
-(IBAction)btnBackAction:(id)sender {
    if (self.isViewPresented) {
        //[self swapViewWithDelay:0.0f indexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}
-(IBAction)btnAddAccount:(id)sender {
    [OAuthManager sharedOAuthManager].isFirstLogin = NO;
    [OAuthManager sharedOAuthManager].delegate = self;
    [[OAuthManager sharedOAuthManager] startOAuth];
    [self showProgressViewWithTitle:@"Fetching Profile"];
}
/*#pragma - mark InboxManager Delegate
 -(void)accountAddedsuccessfullyForEmail:(NSString *)email ForIndex:(NSString *)index {
 [self getUserProfileForEmail:email withIndex:index];
 }
 - (void) didReceiveError:(NSError *)error {
 if (hud) {
 [hud hideAnimated:YES];
 }
 UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Something went wrong!!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
 
 [alert show];
 }
 - (void) noEmailsToFetch {
 
 }*/

#pragma - mark OAuthManagerDelegate
-(void)oAuthManager:(OAuthManager *)manager accountAddedsuccessfullyForEmail:(NSString *)email forIndex:(NSString *)index {
    [self getUserProfileForEmail:email withIndex:index];
}
-(void)oAuthManager:(OAuthManager *)manager didReceiveError:(NSError *)error {
    if (hud) {
        [hud hideAnimated:YES];
    }
    /*UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Something went wrong!!!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
     [alert show];*/
}
#pragma mark - user actions
-(void)getUserProfileForEmail:(NSString *)email withIndex:(NSString *)index {
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if (response != nil) {
            [self saveUserDefaultWithArray:[Utilities parseProfile:response] index:index];
        }
        if (hud) {
            [hud hideAnimated:YES];
        }
    } onError:^( NSString *resultMessage, int errorCode )
     {
         [self saveUserDefaultWithArray:nil index:index];
         if (hud) {
             [hud hideAnimated:YES];
         }
     }];
}

-(void)saveUserDefaultWithArray:(NSArray *)array index:(NSString *)ind {
    NSString * userName = @"";
    NSString * imgUrl = @"";
    if (array && array.count>1) {
        userName = [array objectAtIndex:0];
        NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        if ([userName rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
            // userName consists only of the digits 0 through 9
            userName = @"";
        }
        imgUrl = [array objectAtIndex:1];
    }
    
    /* update db with user image url and name */
    NSMutableArray * userData = [CoreDataManager fetchUserDataForId:[ind longLongValue]];
    NSManagedObject * object = [userData lastObject];
    [object setValue:userName forKey:kUSER_NAME];
    [object setValue:imgUrl forKey:kUSER_IMAGE_URL];
    [CoreDataManager updateData];
    [self updateTableView];
}
-(void)updateTableView {
    self.dataArray = [CoreDataManager fetchAllUsers];
    [self.manageAccountTabkeView reloadData];
}
-(void)dealloc {
    NSLog(@"dealloc : ManageAccountViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
