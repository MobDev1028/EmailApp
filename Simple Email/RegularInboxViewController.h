//
//  RegularInboxViewController.h
//  SimpleEmail
//
//  Created by Zahid on 28/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "InboxManager.h"

@interface RegularInboxViewController : UIViewController <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSArray * emailMessages;
//@property (nonatomic, strong) NSMutableArray * messagesArray;
@property (nonatomic, weak) IBOutlet UITextField  * txtSearchField;
@property (nonatomic, weak) IBOutlet UITableView * regularInboxTableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * heightSearchBar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView  * uiactivityIndicatorView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) IBOutlet UILabel * lblNoEmailFoundMessage;
@property (nonatomic, assign) BOOL renderView;
@property (nonatomic, strong) NSIndexPath * swipeIndexPath;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxManagers;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxSearchManagers;
@property (nonatomic, assign) BOOL fetchMultipleAccount;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;
-(void)removeDelegates;

@end
