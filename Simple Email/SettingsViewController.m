//
//  SettingsViewController.m
//  SimpleEmail
//
//  Created by Zahid on 26/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsCell.h"
#import "HeaderCell.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "ManageAccountViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /* E-MAIL ICON COLOR HEX: #49A9FF */
    self.title = @"Settings";
    SWRevealViewController *revealController = [self revealViewController];
    
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:revealController
                                                             action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    [self.tableview setBackgroundView:nil];
    [self.tableview setBackgroundColor:[UIColor whiteColor]];
}
#pragma - mark UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"SettingsCellIden";
    
    SettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SettingsCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.lblTitle.text = @"Mail Accounts";
    cell.image.image = [UIImage imageNamed:@"mail_accounts"];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 40.0f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *tableIdentifier = @"HeaderCellIdentifier";
    HeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HeaderCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.lblLeft.text = @"Accounts";
    return  cell.contentView;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ManageAccountViewController * manageAccountViewController = [[ManageAccountViewController alloc] initWithNibName:@"ManageAccountViewController" bundle:nil];
        manageAccountViewController.isViewPresented = NO;
        manageAccountViewController.isComingFromMail = YES;
        [self.navigationController pushViewController:manageAccountViewController animated:YES];
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
