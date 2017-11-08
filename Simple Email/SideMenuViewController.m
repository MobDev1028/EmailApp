//
//  SideMenuViewController.m
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SideMenuViewController.h"

#import "Utilities.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "SentViewController.h"
#import "InboxViewController.h"
#import "TrashViewController.h"
#import "DraftViewController.h"
#import "UnreadViewController.h"
#import "SnoozedViewController.h"
#import "SideMenuTableViewCell.h"
#import "ArchiveViewController.h"
#import "SWRevealViewController.h"
#import "RegularInboxViewController.h"
#import "FavoriteMailsViewController.h"
#import "QuickResponseViewController.h"
#import "AcountAlertPageViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HeaderCell.h"
#import "EmailListenerManager.h"
#import "SharedInstanceManager.h"
#import "UtilityImapSessionManager.h"
#import "SignupViewController.h"
#import "ManageAccountViewController.h"
#import "WebServiceManager.h"
#import "MBProgressHUD.h"
#import "SettingsViewController.h"
#import "SendLaterPendingViewController.h"

@interface SideMenuViewController ()

@end

@implementation SideMenuViewController {
    NSArray * menuIcons;
    NSArray * menuTitle;
    NSInteger _presentedRow;
    NSInteger _presentedSection;
    UIViewController *newFrontController;
    NSMutableArray * notificationCountArray;
    UIColor * headerColor;
    MBProgressHUD *hud;
    NSString * logoutUserMail;
    NSString * logoutUserId;
    NSMutableArray * selectedUserIndexes;
    NSArray * individualMenuIcons;
    NSArray * individualMenuTitle;
    int selRow;
    BOOL openMultipleAccount;
    BOOL isSecondSectionCall;
    NSUInteger oldUserCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    openMultipleAccount = YES;
    isSecondSectionCall = NO;
    oldUserCount = 0;
    SWRevealViewController *parentRevealController = self.revealViewController;
    SWRevealViewController *grandParentRevealController = parentRevealController.revealViewController;
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                                         style:UIBarButtonItemStylePlain target:grandParentRevealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"SideMenuBGColor"]];
    [self.menuTableView setBackgroundView:nil];
    [self.menuTableView setBackgroundColor:[UIColor clearColor]];
    
    menuIcons = [[NSArray alloc] initWithObjects:@"icon_smart_inbox", @"icon_inbox",@"icon_clock", @"icon_archive", @"icon_star", @"icon_unread", @"icon_quick_response",@"icon_draft",@"icon_sent", @"icon_clock",@"icon_delete",@"icon_settings",@"icon_logout", nil];
    
    menuTitle = [[NSArray alloc] initWithObjects:@"Smart Inbox", @"Inbox",@"Snoozed", @"Archive", @"Favorite", @"Unread", @"Quick Response",@"Draft",@"Sent",@"Send Later Pending",@"Trash",@"Settings",@"Logout", nil];
    
    individualMenuIcons = [[NSArray alloc] initWithObjects:@"icon_inbox",@"icon_clock", @"icon_archive", @"icon_star",@"icon_draft",@"icon_sent",@"icon_clock",@"icon_delete", nil];
    individualMenuTitle = [[NSArray alloc] initWithObjects:@"Inbox",@"Snoozed", @"Archive", @"Favorite", @"Draft",@"Sent",@"Send Later Pending",@"Trash", nil];
    headerColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"side_menu_header_color"]];
    
    self.header1.backgroundColor = headerColor;
    [self.menuTableView setSeparatorColor:headerColor];
}
-(NSUInteger )fetchUnreadCountForUserId {
    NSError *error;
    NSFetchedResultsController * fetchedResultsController = nil;
    fetchedResultsController = [CoreDataManager fetchedUnreadEmailsForController:fetchedResultsController forUser:-1 isSearching:NO searchText:nil];
    if (![fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    NSUInteger count = [fetchedResultsController fetchedObjects].count;
    fetchedResultsController = nil;
    return count;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (notificationCountArray == nil) {
        notificationCountArray = [[NSMutableArray alloc] init];
    }
    [notificationCountArray removeAllObjects];
    NSFetchedResultsController * fetchedResultsController = nil;
    for (int i = 0; i < 12; ++i) {
        NSString * value = @"-";
        if (i == 0) { /* fetch smart inbox count */
            //            NSMutableArray * users = [CoreDataManager fetchAllUsers];
            //            NSUInteger totalCount = 0;
            //            for (NSManagedObjectContext * obj in users) {
            //                NSString * uid = [NSString stringWithFormat:@"%@",[obj valueForKey:kUSER_ID]];
            NSUInteger count = [self fetchUnreadCountForUserId];
            //                totalCount += count;
            //            }
            
            if (count>0) {
                value = [NSString stringWithFormat:@"%lu",(unsigned long)count];
            }
        }
        else if (i == 1) { /* fetch regular inbox count */
            NSUInteger count = [self fetchUnreadCountForUserId];
            if (count>0) {
                value = [NSString stringWithFormat:@"%lu",(unsigned long)count];
            }
        }
        else if (i == 2) { /*fetch Snoozed count */
            NSError *error;
            fetchedResultsController = [CoreDataManager fetchedSnoozedEmailsForController:fetchedResultsController forUser:-1 isSearching:NO searchText:@""];
            if (![fetchedResultsController performFetch:&error]) {
                // Update to handle the error appropriately.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                exit(-1);  // Fail
            }
            NSUInteger count = [fetchedResultsController fetchedObjects].count;
            fetchedResultsController = nil;
            if (count>0) {
                value = [NSString stringWithFormat:@"%lu",(unsigned long)count];
            }
            
        }
        else if (i == 3) {  /*fetch Archive count */
            
        }
        else if (i == 7) {  /*fetch Draft count */
            NSError *error;
            
            fetchedResultsController = [CoreDataManager initFetchedResultsController:fetchedResultsController forUser:-1 isSearching:NO searchText:@"" fetchArchive:NO fetchDraft:YES isSent:NO entity:kENTITY_EMAIL];
            if (![fetchedResultsController performFetch:&error]) {
                // Update to handle the error appropriately.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                exit(-1);  // Fail
            }
            NSUInteger count = [fetchedResultsController fetchedObjects].count;
            fetchedResultsController = nil;
            if (count>0) {
                value = [NSString stringWithFormat:@"%lu",(unsigned long)count];
            }
        }
        
        [notificationCountArray addObject:value];
    }
    self.header2.backgroundColor = headerColor;
    self.users = nil;
    self.users = [CoreDataManager fetchAllUsers];
    if (oldUserCount != self.users.count) { /* THIS MEANS NEW LOGIN OR LOGOUT OCCUR */
        oldUserCount = self.users.count;
        [selectedUserIndexes removeAllObjects];
        selectedUserIndexes = nil;
    }
    //if ([Utilities isValidString:currentAccount]) {
    //self.users = nil;
    //self.users = [CoreDataManager fetchAllUsers];
    
    /* below code is fore showing current selected user on side panel top */
    
    /*
     NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[currentAccount longLongValue]];
     NSManagedObject * object = [userArray lastObject];
     
     NSString * email = [object valueForKey:kUSER_EMAIL];
     self.lblProfileEmail.text = email;
     
     NSString * name = [object valueForKey:kUSER_NAME];
     if (![Utilities isValidString:name]) {
     name = [[email componentsSeparatedByString: @"@"] objectAtIndex:0];
     }
     self.lblProfileName.text = name;
     
     NSString * url = [object valueForKey:kUSER_IMAGE_URL];
     
     [self.imgProfile sd_setImageWithURL:[NSURL URLWithString:url]
     placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];*/
    
    //}
    [self.menuTableView reloadData];
    SWRevealViewController *grandParentRevealController = self.revealViewController.revealViewController;
    grandParentRevealController.bounceBackOnOverdraw = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    SWRevealViewController *grandParentRevealController = self.revealViewController.revealViewController;
    grandParentRevealController.bounceBackOnOverdraw = YES;
}
-(IBAction)btnNavSearchAction:(id)sender {
    CGFloat value = self.menuTableView.frame.size.height;
    if (tableViewBottom.constant == value) {
        tableViewBottom.constant = 0.0f;
    }
    else {
        tableViewBottom.constant = value;
    }
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        if (selectedUserIndexes.count>0) {
            return self.users.count + selectedUserIndexes.count;
        }
        return self.users.count;
    }
    return [menuIcons count]/2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"SideMenuCell";
    
    SideMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SideMenuTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    int calculatedIndex = (int)indexPath.row;
    
    if (indexPath.section == 1) {
        calculatedIndex+=6;
    }
    if (indexPath.section == 0 || indexPath.section == 1) {
        cell.imgLeftIcon.image = [UIImage imageNamed:[menuIcons objectAtIndex:calculatedIndex]];
        cell.lblTitle.text = [menuTitle objectAtIndex:calculatedIndex];
        
        NSString * notificationCount = [notificationCountArray objectAtIndex:calculatedIndex];
        if ([notificationCount isEqualToString:@"-"]) {
            cell.lblNotificationCount.hidden = YES;
            cell.imgNotification.hidden = YES;
        }
        else {
            cell.lblNotificationCount.text = notificationCount;
            cell.lblNotificationCount.hidden = NO;
            cell.imgNotification.hidden = NO;
        }
        cell.lblEmail.text = @"";
        cell.imgLeftIcon.layer.cornerRadius = 0.0f;
        cell.imgLeftIcon.layer.masksToBounds = NO;
    }
    else {
        cell.lblNotificationCount.hidden = YES;
        cell.imgNotification.hidden = YES;
        int indx = (int)indexPath.row-(selRow+1);
        if (selectedUserIndexes != nil) {
            BOOL containIndex = [selectedUserIndexes containsObject:[NSString stringWithFormat:@"%d",calculatedIndex]];
            if (containIndex) {
                cell.imgLeftIcon.image = [UIImage imageNamed:[individualMenuIcons objectAtIndex:indx]];
                cell.lblTitle.text = [individualMenuTitle objectAtIndex:indx];
                cell.lblEmail.text = @"";
                cell.imgLeftIcon.layer.cornerRadius = 0.0f;
                cell.imgLeftIcon.layer.masksToBounds = NO;
                cell.backgroundColor = [UIColor clearColor];
                return cell;
            }
        }
        
        if (calculatedIndex>self.users.count-1) {
            calculatedIndex = calculatedIndex - (int)(selectedUserIndexes.count);
        }
        NSManagedObject * object = [self.users objectAtIndex:calculatedIndex];
        NSString * email = [object valueForKey:kUSER_EMAIL];
        cell.lblEmail.text = email;
        
        NSString * url = [object valueForKey:kUSER_IMAGE_URL];
        [cell.imgLeftIcon sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"] options:SDWebImageHighPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //... completion code here ...
        }];
        cell.imgLeftIcon.layer.cornerRadius = 11.5f;
        cell.imgLeftIcon.layer.masksToBounds = YES;
        cell.lblTitle.text = @"";
        
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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
    cell.contentView.backgroundColor = headerColor;
    return  cell.contentView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.0f;
    }
    else {
        return 22.0f;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Grab a handle to the reveal controller, as if you'd do with a navigtion controller via self.navigationController.
    if (!isSecondSectionCall) {
        openMultipleAccount = YES;
    }
    else {
        NSManagedObject * object = [self.users objectAtIndex:selRow];
        NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
        [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
    }
    SWRevealViewController *revealController = self.revealViewController;
    
    // selecting row
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    // if we are trying to push the same row or perform an operation that does not imply frontViewController replacement
    // we'll just set position and return
    
    if (row == _presentedRow && section == _presentedSection) {
        //[revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        // return;
    }
    if ([revealController.frontViewController isKindOfClass:[UINavigationController class]]) {
        BOOL removeDelegate = YES;
        if (section == 2) {
            if (selectedUserIndexes != nil) {
                NSString * str = [NSString stringWithFormat:@"%d",(int)row];
                BOOL containIndex = [selectedUserIndexes containsObject:str];
                if (!containIndex) {
                    removeDelegate = NO;
                }
            }
            else {
                removeDelegate = NO;
            }
        }
        if (removeDelegate) {
            UINavigationController * nav = (UINavigationController*)revealController.frontViewController;
            UIViewController * vc = [nav.viewControllers lastObject];
            [Utilities removeDelegatesForViewController:vc];
        }
    }
    newFrontController = nil;
    if (row == 0 && section == 0) {
        InboxViewController *inboxViewController = [[InboxViewController alloc] init];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:inboxViewController];
    }
    else if ((row == 1 && section == 0)) {
        if (isSecondSectionCall) {
            NSManagedObject * object = [self.users objectAtIndex:selRow];
            NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
            [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
        }
        RegularInboxViewController *regularInboxViewController = [[RegularInboxViewController alloc] init];
        regularInboxViewController.renderView = YES;
        regularInboxViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:regularInboxViewController];
        row = 1;
        section = 0;
    }
    else if (row == 2 && section == 0) {
        SnoozedViewController *snoozedViewController = [[SnoozedViewController alloc] init];
        snoozedViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:snoozedViewController];
    }
    else if (row == 3 && section == 0) {
        ArchiveViewController *archiveViewController = [[ArchiveViewController alloc] init];
        archiveViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:archiveViewController];
    }
    else if (row == 4 && section == 0) {
        FavoriteMailsViewController *favoriteMailsViewController = [[FavoriteMailsViewController alloc] init];
        favoriteMailsViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:favoriteMailsViewController];
    }
    else if (row == 5 && section == 0) {
        UnreadViewController *unreadViewController = [[UnreadViewController alloc] init];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:unreadViewController];
    }
    
    else if (row == 0 && section == 1) {
        QuickResponseViewController *quickResponseViewController = [[QuickResponseViewController alloc] init];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:quickResponseViewController];
    }
    else if (row == 1 && section == 1) {
        DraftViewController *draftViewController = [[DraftViewController alloc] init];
        draftViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:draftViewController];
    }
    else if (row == 2 && section == 1) {
        SentViewController *sentViewController = [[SentViewController alloc] init];
        sentViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:sentViewController];
    }
    else if (row == 3 && section == 1) {
        SendLaterPendingViewController *sendlaterPendingController = [[SendLaterPendingViewController alloc] init];
        sendlaterPendingController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:sendlaterPendingController];
    }
    else if (row == 4 && section == 1) {
        TrashViewController *trashViewController = [[TrashViewController alloc] init];
        trashViewController.fetchMultipleAccount = openMultipleAccount;
        newFrontController = [[UINavigationController alloc] initWithRootViewController:trashViewController];
    }
    else if (row == 5 && section == 1) {
        //AcountAlertPageViewController *acountAlertPageViewController = [[AcountAlertPageViewController alloc] init];
        SettingsViewController * settingsViewController = [[SettingsViewController alloc] init];
        newFrontController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    }
    else if (row == 6 && section == 1) {
        NSMutableArray * users = [CoreDataManager fetchAllUsers];
        if (users.count == 1) {
            NSManagedObject * obj = [users lastObject];
            long intId = [[obj valueForKey:kUSER_ID] integerValue];
            logoutUserId = [NSString stringWithFormat:@"%ld",intId];
            logoutUserMail = [obj valueForKey:kUSER_EMAIL];
            [self showLogoutAlert];
        }
        else if (users.count > 1){
            ManageAccountViewController * manageAccountViewController = [[ManageAccountViewController alloc] initWithNibName:@"ManageAccountViewController" bundle:nil];
            manageAccountViewController.isViewPresented = YES;
            manageAccountViewController.isComingFromMail = NO;
            newFrontController = [[UINavigationController alloc] initWithRootViewController:manageAccountViewController];
            SWRevealViewController *revealController = self.revealViewController;
            [revealController pushFrontViewController:newFrontController animated:YES];
        }
        return;
    }
    else if (section == 2) {
        if (selectedUserIndexes == nil) {
            selectedUserIndexes = [[NSMutableArray alloc] init];
            int counter = (int)indexPath.row;
            selRow = counter;
            for (int i = 0; i<7; ++i) {
                counter++;
                [selectedUserIndexes addObject:[Utilities getStringFromInt:counter]];
            }
        }
        else {
            NSString * str = [NSString stringWithFormat:@"%d",(int)row];
            BOOL containIndex = [selectedUserIndexes containsObject:str];
            int indexOf = (int)[selectedUserIndexes indexOfObject:str];
            if (containIndex) {
                int sec = 0;
                row = row-selRow;
                if (indexOf>=4) {
                    sec = 1;
                    row = row-4;
                }
                openMultipleAccount = NO;
                isSecondSectionCall = YES;
                [self tableView:self.menuTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:sec]];
            }
            else {
                [selectedUserIndexes removeAllObjects];
                selectedUserIndexes = nil;
            }
        }
        [self setPresentedRow:row andSection:section];
        [self.menuTableView reloadData];
        CGPoint offset = CGPointMake(0, self.menuTableView.contentSize.height - self.menuTableView.frame.size.height);
        [self.menuTableView setContentOffset:offset animated:YES];
        return;
    }
    else {
        [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        return;
    }
    isSecondSectionCall = NO;
    [revealController pushFrontViewController:newFrontController animated:YES];
    [self setPresentedRow:row andSection:section];
}
-(void)setPresentedRow:(NSInteger)row andSection:(NSInteger)section {
    _presentedRow = row;  // <- store the presented row
    _presentedSection = section; // <- store the presented section
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
        //NSMutableArray * array = [[NSMutableArray alloc] initWithObjects:@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",nil];
        
        [self showProgressHudWithTitle:@"Removing Account"];
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        //        for (int i = 0; i<array.count; ++i) {
        //            uniqueIdentifier = [array objectAtIndex:i];
        //            if ([uniqueIdentifier isEqualToString:@""]) {
        //                return;
        //            }
        [dictionary setObject:logoutUserMail forKey:@"user_email"];
        [dictionary setObject:uniqueIdentifier forKey:@"device_udid"];
        [dictionary setObject:kSECRET forKey:@"secret"];
        
        [[WebServiceManager sharedServiceManager] deleteUser:dictionary completionBlock:^(id response) {
            if (response) {
                id data = [Utilities dataToDictionary:response];
                NSString * unreadCount = [data valueForKey:@"deviceUnreadCount"];
                AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate setBadgeCount:[unreadCount integerValue]];
                
                //id data = [Utilities dataToDictionary:response];
                NSLog(@"user deleted: %@",unreadCount);
                //NSDictionary *userInfo = [NSDictionary dictionaryWithObject:logoutUserId forKey:kUSER_ID];
                //[[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_LOGOUT object:nil userInfo:userInfo];
                
                NSError * error = [CoreDataManager wipeUser:logoutUserId];
                if(error == nil) {
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    /* Remove email listners for deleted user */
                    [appDelegate removeEmailListnersForId:logoutUserId];
                    
                    /* remove imap shared instances for deleted user */
                    [appDelegate removeImapSessionsForId:logoutUserId];
                    
                    NSMutableDictionary * firebaseDictionary = [[SharedInstanceManager sharedInstance] firebaseSharedInstance];
                    NSMutableArray * inst = [firebaseDictionary objectForKey:logoutUserId];
                    if (inst != nil) {
                        [firebaseDictionary removeObjectForKey:logoutUserId];
                    }
                    
                    [Utilities setUserDefaultWithValue:nil andKey:kSELECTED_ACCOUNT];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [appDelegate setRootViewForSignUp];
                    });
                    
                    /* code to be executed on the main queue after delay */
                    //  SignupViewController * signupViewController = [[SignupViewController alloc] initWithNibName:@"SignupViewController" bundle:nil];
                    //            signupViewController.isViewPresented = YES;
                    //            UINavigationController * nv = [[UINavigationController alloc] initWithRootViewController:signupViewController];
                    //            [[appDelegate getRootView] presentViewController:nv animated:YES completion:nil];
                }
                //            else if(users.count == 1) {
                //                NSManagedObject * object = [users objectAtIndex:0];
                //                NSString * selectedId = [NSString stringWithFormat:@"%@",[object valueForKey:kUSER_ID]];
                //                [Utilities setUserDefaultWithValue:selectedId andKey:kSELECTED_ACCOUNT];
                //
                //                double delayInSeconds = 0.0;
                //                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                //                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                //                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:3];
                //                    [self tableView:self.menuTableView didSelectRowAtIndexPath:indexPath];
                //                });
                //            }
                //            else if (users.count> 1) {
                //
                //                ManageAccountViewController * manageAccountViewController = [[ManageAccountViewController alloc] initWithNibName:@"ManageAccountViewController" bundle:nil];
                //                manageAccountViewController.isViewPresented = YES;
                //
                //                newFrontController = [[UINavigationController alloc] initWithRootViewController:manageAccountViewController];
                //                SWRevealViewController *revealController = self.revealViewController;
                //                [revealController pushFrontViewController:newFrontController animated:YES];
                //            }
            }
            
            
            [self hideProgressHud];
        }onError:^(NSString * message, int errorCode) {
            [self hideProgressHud];
            UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Cannot remove account. please try again."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
            [myAlert show];
        }onProgress:^(NSProgress * progress) {
            
        }];
    }
    //}
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
    }*/
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
