//
//  EmailComposerViewController.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLTokenInputView.h"
#import "CoreDataManager.h"
#import <MailCore/MailCore.h>
#import "QuickLook/QuickLook.h"

@interface EmailComposerViewController : UIViewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate> {
    IBOutlet NSLayoutConstraint * fromTabHeight;
    IBOutlet NSLayoutConstraint * quickBtnBottom;
    
    IBOutlet NSLayoutConstraint * subjectTop;
    IBOutlet NSLayoutConstraint * webViewHeight;
    IBOutlet NSLayoutConstraint * quotedViewBottom;
    IBOutlet NSLayoutConstraint * attachmentViewBottom;
    IBOutlet NSLayoutConstraint * tableViewTopLayoutConstraint;
    IBOutlet NSLayoutConstraint * containerViewHeight;
    NSLayoutConstraint * editorHeight;
    __weak IBOutlet NSLayoutConstraint *autoCompleteContainerViewTopConstraint;
}

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property(nonatomic, strong)  NSString * strNavTitle;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tokenInputTopSpace;
@property (strong, nonatomic) IBOutlet CLTokenInputView *tokenInputView;
@property (strong, nonatomic) IBOutlet CLTokenInputView *ccTokenInputView;
@property (strong, nonatomic) IBOutlet CLTokenInputView *bccTokenInputView;
@property (strong, nonatomic) NSMutableArray * toAddresses;
@property (strong, nonatomic) NSMutableArray * ccAddresses;
@property (strong, nonatomic) NSMutableArray * bccAddresses;
@property (strong, nonatomic) NSMutableArray * toAddressesMap;
@property (strong, nonatomic) NSMutableArray * ccAddressesMap;
@property (strong, nonatomic) NSMutableArray * bccAddressesMap;
@property (strong, nonatomic) NSMutableArray * senderData;
@property (strong, nonatomic) NSMutableArray * sendingData;
@property (strong, nonatomic) NSMutableArray * attachments;
@property (nonatomic, strong) UIImageView *img;
//@property (nonatomic, weak)    IBOutlet UITextView * txtWritingArea;
@property (nonatomic, weak)    IBOutlet UIScrollView * scrollView;
@property (nonatomic, weak)    IBOutlet UITextField * fieldFrom;
@property (nonatomic, weak)    IBOutlet UIView * subjectView;
@property (nonatomic, assign)  int mailType;
@property (nonatomic, weak)    IBOutlet UITextField * fieldSubject;
@property (nonatomic, strong)  NSManagedObject * draftObject;
@property (nonatomic, strong)  NSManagedObject * quickResponseObject;
@property (nonatomic, strong) NSMutableDictionary * sendLaterObject;
@property (assign)    BOOL     isSendLater;
@property (assign)    BOOL     isDraft;
@property (nonatomic, strong)  MCOIMAPMessage * message;
@property (nonatomic, weak) IBOutlet  UIButton * btnQuickResponse;
@property (nonatomic, weak) IBOutlet  UIView * ccView;
@property (nonatomic, weak) IBOutlet  UIWebView * webView;
@property (nonatomic, weak) IBOutlet  UIButton * btnDropCcView;
@property (nonatomic, weak) IBOutlet  UIButton * btnShowQuote;
@property (nonatomic, weak) IBOutlet  UIButton * btnAttcahments;
@property (nonatomic, weak) IBOutlet  UIButton * btnCrossWebview;
@property (nonatomic, weak) IBOutlet  UIView * textEditorContainerView;
@property (nonatomic, weak) IBOutlet  UIView * containerView;
@property (nonatomic, weak) IBOutlet  UIView * toView;
@property (nonatomic, weak) IBOutlet  UIView * toContainerView;
@property (nonatomic, weak) IBOutlet  UIView * attachmentView;
@property (nonatomic, weak) IBOutlet  UILabel * lblFile;
@property (nonatomic, weak) IBOutlet  UILabel * lblTo;
@property (nonatomic, weak) IBOutlet  UIImageView * imgAttachment;
@property (nonatomic, weak) IBOutlet  UITableView * attachmentTableView;
@property (nonatomic, weak) IBOutlet  UITableView * autoCompleteTableView;
@property (nonatomic, weak) IBOutlet  UIView * autoCompleteContainerView;
@property (strong, nonatomic) NSArray *names;
@property (strong, nonatomic) NSArray *filteredNames;
@property (strong, nonatomic) NSMutableArray *selectedNames;
@property (nonatomic, strong) NSMutableArray * attachmentsTempUrl;
-(void)removeDelegates;
@end
