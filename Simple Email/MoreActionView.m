//
//  MoreActionView.m
//  SimpleEmail
//
//  Created by Zahid on 18/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "MoreActionView.h"
#import "Constants.h"

@interface MoreActionView ()

@end

@implementation MoreActionView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.containerView.layer.shadowOpacity = 0.5f;
    
    self.threadMoreView.layer.masksToBounds = YES;
    self.threadMoreView.layer.cornerRadius = 5.0f;
    
    self.messageMoreView.layer.masksToBounds = YES;
    self.messageMoreView.layer.cornerRadius = 5.0f;
    
    UIColor * borderColor = [UIColor colorWithRed:228.0f/255.0f green:228.0f/255.0f blue:228.0f/255.0f alpha:1.0];
    
    [self setBorder:self.btnMove color:borderColor];
    [self setBorder:self.btnSpam color:borderColor];
    [self setBorder:self.btnDelete color:borderColor];
    [self setBorder:self.btnViewDetail color:borderColor];
    [self setBorder:self.btnPrint color:borderColor];
    
    [self setBorder:self.btnReply color:borderColor];
    [self setBorder:self.btnForward color:borderColor];
    [self setBorder:self.btnDelete1 color:borderColor];
    [self setBorder:self.btnPrint1 color:borderColor];
}
-(void)setBorder:(UIButton *)button color:(UIColor *)color {
    button.layer.borderColor = color.CGColor;
    button.layer.borderWidth = 0.5f;
    button.layer.cornerRadius = 5.0f;
    button.layer.masksToBounds = YES;
}
-(void)viewType:(int)type {
    self.viewType = type;
    if (type == kMORE_VIEW_TYPE_MSG) {
        [self.messageMoreView setHidden:NO];
        [self.threadMoreView setHidden:YES];
    }
    else {
        [self.messageMoreView setHidden:YES];
        [self.threadMoreView setHidden:NO];
    }
}
-(void)setViewPosition:(CGFloat)y screenHeight:(CGFloat)screenheight {
    CGFloat size = y + 268 + 15;
    if (size>screenheight) {
        size = y - 268;
    }
    else {
        size = y + 20;
    }
    self.top.constant = size;
    [self.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.superview layoutIfNeeded];
    }];
}
-(void)setupView {
    if (self.folderType == kFolderSentMail) {
        [self.btnViewDetail setHidden:YES];
    }
}
#pragma -mark Private Methods
-(void)hideView {
    [self removeFromSuperview];
    //[self.delegate messageDetailViewDidRemoveFromSuperView];
}

#pragma - mark UserActions
-(IBAction)btnHideView:(id)sender {
    [self hideView];
}
-(IBAction)btnActions:(id)sender {
    [self hideView];
    UIButton *btn = (UIButton *)sender;
    /* COMPLETE THREAD MORE_VIEW
     Move.tag = 101;
     Delete.tag = 102;
     Print.tag = 103;
     Spam.tag.tag = 104;
     View Detail.tag = 105; */
    
    /* MESSAGE MORE_VIEW 
     Reply.tag = 201;
     Forward.tag = 202;
     Print.tag = 203;
     Delete.tag = 204; */
    [self.delegate buttonTapped:(int)btn.tag onView:self.viewType];
}
-(void)dealloc {
    NSLog(@"MoreActionView - dealloc");
}
@end
