//
//  MoreActionView.h
//  SimpleEmail
//
//  Created by Zahid on 18/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MoreActionView;
@protocol MoreActionViewDelegate <NSObject>
- (void)buttonTapped:(int)btnIndex onView:(int)viewType;
@end
@interface MoreActionView : UIView
@property (assign, nonatomic) id <MoreActionViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIView * containerView;
@property (nonatomic, weak) IBOutlet UIView * threadMoreView;
@property (nonatomic, weak) IBOutlet UIView * messageMoreView;
@property (nonatomic, weak) IBOutlet UIButton * btnDelete;
@property (nonatomic, weak) IBOutlet UIButton * btnMove;
@property (nonatomic, weak) IBOutlet UIButton * btnSpam;
@property (nonatomic, weak) IBOutlet UIButton * btnPrint;
@property (nonatomic, weak) IBOutlet UIButton * btnViewDetail;
@property (nonatomic, weak) IBOutlet UIButton * btnReply;
@property (nonatomic, weak) IBOutlet UIButton * btnForward;
@property (nonatomic, weak) IBOutlet UIButton * btnDelete1;
@property (nonatomic, weak) IBOutlet UIButton * btnPrint1;
@property (nonatomic, assign) int viewType;
@property (nonatomic, assign) int folderType;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * top;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * height;
-(void)setViewPosition:(CGFloat)y screenHeight:(CGFloat)screenheight;
-(void)hideView;
-(void)viewType:(int)type;
-(void)setupView;
@end
