//
//  DraftViewController.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"
#import "InboxManager.h"
#import "EmailUpdateManager.h"

@interface DraftViewController : UIViewController
@property(nonatomic, weak) IBOutlet UITableView * draftTableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) IBOutlet  UITextField *txtSearchField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * heightSearchBar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView  * uiactivityIndicatorView;
@property (nonatomic, weak) IBOutlet UILabel * lblNoEmailFoundMessage;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxManagers;
@property (nonatomic, strong) NSMutableArray<EmailUpdateManager *> *updateManagers;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxSearchManagers;
@property (nonatomic, assign) BOOL fetchMultipleAccount;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;
-(void)removeDelegates;
@end
