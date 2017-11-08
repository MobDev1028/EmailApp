//
//  MessageDetailView.h
//  SimpleEmail
//
//  Created by Zahid on 15/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MessageDetailView;
@protocol MessageDetailViewDelegate <NSObject>
- (void)messageDetailViewDidRemoveFromSuperView;
@end
@interface MessageDetailView : UIView
@property (assign, nonatomic) id <MessageDetailViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *lbldate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) NSMutableArray * dataArray;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) NSString * profileImageUrl;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * viewTop;
-(void)hideView;
-(void)setupView;
-(void)setViewPosition:(CGFloat)y screenHeight:(CGFloat)screenheight;
@end
