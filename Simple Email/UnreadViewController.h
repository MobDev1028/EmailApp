//
//  UnreadViewController.h
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface UnreadViewController : UIViewController
@property (nonatomic, weak) IBOutlet UITableView * unreadTableView;
@property (nonatomic, weak) IBOutlet UITextField  * txtSearchField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * heightSearchBar;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) IBOutlet UILabel * lblNoEmailFoundMessage;
@property (nonatomic, strong) NSIndexPath * swipeIndexPath;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
-(void)removeDelegates;
@end
