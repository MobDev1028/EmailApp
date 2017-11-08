//
//  ManageAccountViewController.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ManageAccountViewController : UIViewController
@property(nonatomic, weak) IBOutlet UITableView * manageAccountTabkeView;
@property(nonatomic, weak) IBOutlet UIButton * btnAddAccount;
@property(nonatomic, assign) BOOL isViewPresented;
@property(nonatomic, assign) BOOL isComingFromMail;
@property(nonatomic, strong) NSMutableArray * dataArray;
@end
