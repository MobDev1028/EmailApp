//
//  MailThreadViewController.h
//  SimpleEmail
//
//  Created by Zahid on 19/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "CoreDataManager.h"
#import "QuickLook/QuickLook.h"

@interface MailThreadViewController : UIViewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate>
@property (nonatomic, strong) NSString * navigationBarTitle;
@property (nonatomic, weak) IBOutlet UITableView * threadTableView;
@property (assign) uint64_t selectedEmailThreadId;
@property (nonatomic, strong) NSString * folderName;
@property (nonatomic, strong) NSManagedObject * object;
@property (nonatomic, assign) BOOL isSnoozed;
@property (nonatomic, assign) BOOL isSent;
@property (nonatomic, weak) IBOutlet UIButton * btnArchive;
@property (nonatomic, weak) IBOutlet UIButton * btnTrash;
@property (nonatomic, weak) IBOutlet UIButton * btnReply;
@property (nonatomic, weak) IBOutlet UIButton * btnMore;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * contraintTableTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * contraintTableLeading;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * contraintTableTrailing;
@property (nonatomic, assign) int folderType;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * contraintTrailing;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * contraintLeading;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary * attachmentDictionary;
@property (nonatomic, strong) NSMutableArray * allAttachments;
@property (nonatomic, strong) NSDictionary * pushDatadictionary;
@property (nonatomic, assign) BOOL isViewPresented;

@end
