//
//  SendLaterPendingViewController.h
//  SimpleEmail
//
//  Created by JCB on 8/6/17.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendLaterPendingViewController : UIViewController
@property (nonatomic, assign) BOOL fetchMultipleAccount;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end
