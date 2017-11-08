//
//  InboxViewController.h
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "InboxManager.h"
#import "UnreadFetchManager.h"

@interface InboxViewController : UIViewController  <NSFetchedResultsControllerDelegate> {
    IBOutlet NSLayoutConstraint * heightSearchBar;
}

@property (nonatomic, weak)   IBOutlet UITextField * txtSearchField;
@property (nonatomic, weak)   IBOutlet UITableView * tableview;
@property (nonatomic, weak)   IBOutlet UIView * viewSectionHeader;
@property (nonatomic, weak)   IBOutlet UILabel * lblHeadertTitle;
@property (nonatomic, weak)   IBOutlet UILabel * lblHeadertEmail;
@property (nonatomic, strong) NSIndexPath * swipeIndexPath;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray * allUserEmailsData;
@property (nonatomic, strong) NSMutableArray * loginAcounts;
@property (nonatomic, weak)   IBOutlet NSLayoutConstraint  * activityIndicatorHeightConstraint;
@property (nonatomic, weak)   IBOutlet UIActivityIndicatorView  * uiactivityIndicatorView;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxManagers;
@property (nonatomic, strong) NSMutableArray<InboxManager *> *inboxSearchManagers;
@property (nonatomic, strong) NSMutableDictionary *unreadFetchManagers;
@property (nonatomic, weak) IBOutlet UILabel * lblUndo;
@property (nonatomic, strong) NSMutableArray * undoArray;

-(void)removeDelegates;
@end
