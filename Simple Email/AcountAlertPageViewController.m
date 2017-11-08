//
//  AcountAlertPageViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "AcountAlertPageViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ManageAccountViewController.h"

@interface AcountAlertPageViewController ()

@end

@implementation AcountAlertPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   /* UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_back"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(btnBackAction:)];*/
    
    
    UIBarButtonItem * btnMenu = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"menu_btn"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[self revealViewController]
                                                             action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    self.title = @"Manage Account";
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}
-(void)removeDelegates {}
#pragma - mark User Action

-(IBAction)btnBackAction:(id)sender {
    
}
-(IBAction)btnExistingAccountAction:(id)sender {
    ManageAccountViewController * manageAccountViewController = [[ManageAccountViewController alloc] initWithNibName:@"ManageAccountViewController" bundle:nil];
    manageAccountViewController.isViewPresented = NO;
    [self.navigationController pushViewController:manageAccountViewController animated:YES];
}
-(void)dealloc {
    NSLog(@"dealloc : AcountAlertPageViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
