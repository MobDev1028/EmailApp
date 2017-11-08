//
//  ArchiveViewController.h
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"

@interface ArchiveViewController : UIViewController
@property (nonatomic, weak) IBOutlet UITableView * archiveTableView;
@property (nonatomic, weak) IBOutlet UITextField  * txtSearchField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * heightSearchBar;
@property (nonatomic, strong) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, strong) NSIndexPath * swipeIndexPath;
@property (nonatomic, assign) BOOL fetchMultipleAccount;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;
-(void)removeDelegates;
@end
