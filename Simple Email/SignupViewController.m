//
//  SignupViewController.m
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SignupViewController.h"
#import "Utilities.h"
#import "ModelUser.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "OAuthManager.h"
#import "MBProgressHUD.h"
#import "CoreDataManager.h"
#import "WebServiceManager.h"
#import "SWRevealViewController.h"
#import "SideMenuViewController.h"
#import "RegularInboxViewController.h"


@interface SignupViewController ()<OAuthManagerDelegate>

@end

@implementation SignupViewController {
    MBProgressHUD *hud;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocalNotificationReceived:) name:nil object:nil];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma - mark Private Methods
-(void)getUserProfileForEmail:(NSString *)email withIndex:(NSString *)index {
    
    [[WebServiceManager sharedServiceManager] getProfileForEmail:email completionBlock:^(id response) {
        if ( response != nil ) {
            [self saveUserDefaultWithArray:[Utilities parseProfile:response] index:index];
            if (self.isViewPresented) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate updateRootViewWithSideMenu];
            }
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
         //UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Something went wrong!!!" message:resultMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         //[av show];
         if (self.isViewPresented) {
             [self dismissViewControllerAnimated:YES completion:nil];
         }
         else {
             AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
             [appDelegate updateRootViewWithSideMenu];
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
    
    //[Utilities setUserDefaultWithValue:userName andKey:[NSString stringWithFormat:@"%@%@",kACCOUNT_NAME,ind]];
    //[Utilities setUserDefaultWithValue:imgUrl andKey:[NSString stringWithFormat:@"%@%@",kIMG_ACCOUNT,ind]];
    
    /* update db with user image url and name */
    NSMutableArray * userData = [CoreDataManager fetchUserDataForId:[ind longLongValue]];
    NSManagedObject * object = [userData lastObject];
    [object setValue:userName forKey:kUSER_NAME];
    [object setValue:imgUrl forKey:kUSER_IMAGE_URL];
    [CoreDataManager updateData];
}

#pragma - mark User Action
-(IBAction)signInGmailAction:(id)sender {
    [self.navigationController.navigationBar setHidden:NO];
    [OAuthManager sharedOAuthManager].isFirstLogin = YES;
    [OAuthManager sharedOAuthManager].delegate = self;
    [[OAuthManager sharedOAuthManager] startOAuth];
//    [[OAuthManager sharedOAuthManager] signInGoogle];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"Fetching Profile";
     });
}
-(IBAction)signUpAction:(id)sender {
}

#pragma - mark OAuthManagerDelegate
-(void)oAuthManager:(OAuthManager *)manager accountAddedsuccessfullyForEmail:(NSString *)email forIndex:(NSString *)index {
    
    [self.navigationController.navigationBar setHidden:YES];
    [self getUserProfileForEmail:email withIndex:index];
}
-(void)oAuthManager:(OAuthManager *)manager didReceiveError:(NSError *)error {
    [self.navigationController.navigationBar setHidden:YES];
    
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    if (hud) {
        [hud hideAnimated:YES];
    }
    // });
    
    if(error != nil){
        NSString * strError = [error.userInfo objectForKey:@"error"];
        if([Utilities isValidString:strError]) {

            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:strError message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    

}

- (void) onLocalNotificationReceived:(NSNotification*) notification{
    if ([[notification name] isEqualToString:@"LOCAL_NOTIFICATION_GOOGLE_SIGNUP_SHOW"]) {
        UIViewController *viewController = [notification object];
        [self presentViewController:viewController animated:YES completion:nil];
    }
    if ([[notification name] isEqualToString:@"LOCAL_NOTIFICATION_GOOGLE_SIGNUP_HIDE"]) {
//        UIViewController *viewController = [notification object];
        [self dismissViewControllerAnimated:YES completion:nil];
    }

}

@end
