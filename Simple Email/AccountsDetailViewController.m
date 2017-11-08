//
//  AccountsDetailViewController.m
//  SimpleEmail
//
//  Created by Zahid on 26/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "AccountsDetailViewController.h"
#import "HeaderCell.h"
#import "NotificationPreferencesCell.h"
#import "AccountDetailEditCell.h"
#import "ButtonCell.h"
#import "Constants.h"
#import "Utilities.h"
#import "MBProgressHUD.h"
#import "WebServiceManager.h"
#import "AppDelegate.h"
#import "SharedInstanceManager.h"

@interface AccountsDetailViewController ()

@end

@implementation AccountsDetailViewController {
    MBProgressHUD *hud;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.object != nil) {
        NSString * name = [self.object valueForKey:kUSER_NAME];
        NSString * email = [self.object valueForKey:kUSER_EMAIL];
        if (![Utilities isValidString:name]) {
            NSArray *subStrings = [email componentsSeparatedByString:@"@"];
            if (subStrings.count>0) {
                NSString *firstString = [subStrings objectAtIndex:0];
                [self.object setValue:firstString forKey:kUSER_NAME];
                [CoreDataManager updateData];
            }
        }
    }
}
-(AccountDetailEditCell *)configureEditCell:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    static NSString *tableIdentifier = @"AccountDetailEditCellIden";
    AccountDetailEditCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AccountDetailEditCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.row == 0) {
        cell.lblTitle.text = @"Name";
        cell.txtEditor.text = [self.object valueForKey:kUSER_NAME];
        [cell.separator setHidden:NO];
    }
    else {
        cell.lblTitle.text = @"Title";
        cell.txtEditor.text = [self.object valueForKey:kACCOUNT_TITLE];;
        [cell.separator setHidden:YES];
    }
    cell.txtEditor.tag = indexPath.row;
    [cell.txtEditor addTarget:self action:@selector(updateTableContentsOfTextField:) forControlEvents:UIControlEventEditingChanged];
    
    return cell;
}
- (void)updateTableContentsOfTextField:(id)sender {
    UITextField * textField = (UITextField *)sender;
    NSString * key = kACCOUNT_TITLE;
    if (textField.tag == 0) {
        key = kUSER_NAME;
    }
    NSString * txt = [NSString stringWithFormat:@"%@", ((UITextField *)sender).text];
    [self.object setValue:txt forKey:key];
    [CoreDataManager updateData];
}
-(NotificationPreferencesCell *)configurePreferencesCell:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    static NSString *tableIdentifier = @"NotificationPreferencesCellIden";
    NotificationPreferencesCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationPreferencesCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString * imageName = nil;
    int lastSelection = [[self.object valueForKey:kNOTIFICATION_PREFERENCES] intValue];
    if (lastSelection == indexPath.row) {
        imageName = @"btn_check";
    }
    else {
        imageName = @"btn_uncheck";
    }
    [cell.checkButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    if (indexPath.row == 0) {
        cell.lblTitle.text = @"All";
        cell.lblDetail.text = @"Sends notification for every incoming e-mail";
        [cell.viewTopLine setHidden:YES];
        [cell.viewBottomLine setHidden:NO];
        [cell.viewSeparator setHidden:NO];
    }
    else if(indexPath.row == 1) {
        cell.lblTitle.text = @"Smart";
        cell.lblDetail.text = @"Mutes strangers and automated e-mails";
        [cell.viewTopLine setHidden:NO];
        [cell.viewBottomLine setHidden:NO];
        [cell.viewSeparator setHidden:NO];
    }
    else {
        cell.lblTitle.text = @"No Notifications";
        cell.lblDetail.text = @"Turn of Notifications";
        [cell.viewTopLine setHidden:NO];
        [cell.viewBottomLine setHidden:YES];
        [cell.viewSeparator setHidden:YES];
    }
    return cell;
}
-(ButtonCell *)configureButtonCell:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    static NSString *tableIdentifier = @"ButtonCellIden";
    ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [cell.button setBackgroundImage:[UIImage imageNamed:@"btn_remove_bg"] forState:UIControlStateNormal];
    [cell.button addTarget:self action:@selector(removeUser:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma - mark UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    else if (section == 1) {
        return 3;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [self configureEditCell:indexPath tableView:tableView];
    }
    else if (indexPath.section == 1) {
        return [self configurePreferencesCell:indexPath tableView:tableView];
    }
    else {
        return [self configureButtonCell:indexPath tableView:tableView];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 40.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *tableIdentifier = @"HeaderCellIdentifier";
    HeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HeaderCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.lblCenter.text = @"";
    cell.lblLeftBottom.text = @"";
    cell.lblLeft.text = @"";
    if (section == 0) {
        cell.lblCenter.text = [self.object valueForKey:kUSER_EMAIL];
    }
    else if (section == 1) {
        cell.lblLeftBottom.text = @"Notification Preferences";
    }
    else {
        cell.lblLeftBottom.text = @"";
    }
    return  cell.contentView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 60.0f;
    }
    else if (section == 1) {
        return 30.0f;
    }
    return 0.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        int lastSelection = [[self.object valueForKey:kNOTIFICATION_PREFERENCES] intValue];
        if (lastSelection == indexPath.row) {
            return;
        }
        [self.object setValue:[NSNumber numberWithInteger:indexPath.row] forKey:kNOTIFICATION_PREFERENCES];
        [CoreDataManager updateData];
        [self.accountsTableView reloadData];
    }
}
-(IBAction)removeUser:(id)sender {
    [self showLogoutAlert];
}
-(void)showProgressViewWithTitle:(NSString *)title {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
}
-(void)deleteUser {
    NSString* uniqueIdentifier = [Utilities getDeviceIdentifier]; // IOS 6+
    if ([Utilities isValidString:uniqueIdentifier]) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        NSString * email = [self.object valueForKey:kUSER_EMAIL];
        [dictionary setObject:email forKey:@"user_email"];
        [dictionary setObject:uniqueIdentifier forKey:@"device_udid"];
        [dictionary setObject:kSECRET forKey:@"secret"];
        
        [self showProgressViewWithTitle:@"Removing Account"];
        [[WebServiceManager sharedServiceManager] deleteUser:dictionary completionBlock:^(id response) {
            id data = [Utilities dataToDictionary:response];
            NSString * unreadCount = [data valueForKey:@"deviceUnreadCount"];
            AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate setBadgeCount:[unreadCount integerValue]];
            
            NSString * selectedUserId = [NSString stringWithFormat:@"%@",[self.object valueForKey:kUSER_ID]];
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
                    [self.navigationController popViewControllerAnimated:YES];
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
        }
                                                  onProgress:^(NSProgress * progress) {
                                                      
                                                  }];
    }
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
        [[GIDSignIn sharedInstance] signOut];
        [self deleteUser];
    }
}
-(void)dealloc {
    NSLog(@"dealloc - SettingsViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
