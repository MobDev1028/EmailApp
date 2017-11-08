//
//  EmailDetailViewController.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModelEmail.h"
#import "CoreDataManager.h"

@interface EmailDetailViewController : UIViewController <UIActionSheetDelegate>
@property(nonatomic, weak) IBOutlet UITableView * fileAtachmentTable;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint * blurImageBottom;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint * blurViewBottom;
@property(nonatomic, weak) IBOutlet UIButton * archiveWidth;
@property(nonatomic, weak) IBOutlet UIImageView * imgBlur;
@property(nonatomic, weak) IBOutlet UILabel * topLabel;
@property(nonatomic, weak) IBOutlet UILabel * lblName;
@property(nonatomic, weak) IBOutlet UILabel * lblTime;
@property(nonatomic, weak) IBOutlet UIButton * btnShowDetail;
@property(nonatomic, weak) IBOutlet UIImageView * imgProfile;
@property(nonatomic, weak) IBOutlet UITextView * txtMailContent;
@property(nonatomic, weak) IBOutlet UIWebView * mailContentWebView;
@property(nonatomic, strong) ModelEmail * modelEmail;
@property(nonatomic, strong) NSManagedObject * object;
@property(nonatomic, assign) int folderType;
@property(nonatomic, assign) BOOL isViewPresented;
@property(nonatomic, strong) NSDictionary * pushDatadictionary;
@property (nonatomic, strong) MCOIMAPSession * imapSession;
@end
