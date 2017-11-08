//
//  SnoozedViewController.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModelEmail.h"
#import "CoreDataManager.h"

@interface SnoozedViewController : UIViewController
@property (nonatomic, weak) IBOutlet UITableView * snoozedTableView;
//@property (nonatomic, strong) NSMutableArray * snoozedEmails;
@property (nonatomic, strong) ModelEmail * modelEmail;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * heightSearchBar;
@property (nonatomic, weak) IBOutlet UITextField  * txtSearchField;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) IBOutlet UILabel * lblNoEmailFoundMessage;
@property (nonatomic, assign) BOOL fetchMultipleAccount;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
-(void)removeDelegates;
@end
