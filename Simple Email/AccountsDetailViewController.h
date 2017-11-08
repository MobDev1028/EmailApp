//
//  AccountsDetailViewController.h
//  SimpleEmail
//
//  Created by Zahid on 26/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"
@interface AccountsDetailViewController : UIViewController
@property (nonatomic, weak) IBOutlet UITableView *accountsTableView;
@property (nonatomic, strong) NSManagedObject * object;
@end
