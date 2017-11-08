//
//  AddAccountFormViewController.m
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "AddAccountFormViewController.h"
#import "AppDelegate.h"

@interface AddAccountFormViewController ()

@end

@implementation AddAccountFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem * btnMenu=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_back"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(btnBackAction:)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    self.title = @"Add Account";
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if ([self.txtEmail respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor colorWithRed:141.0f/255.0f green:141.0f/255.0f blue:141.0f/255.0f alpha:1.0f];
        self.txtEmail.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: color}];
        self.txtPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: color}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
        // TODO: Add fall-back code to set placeholder color.
    }
}

#pragma - mark User Action
-(IBAction)btnBackAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
-(void)dealloc {
    NSLog(@"dealloc : AddAccountFormViewController");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
