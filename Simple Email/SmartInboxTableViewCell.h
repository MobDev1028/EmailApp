//
//  SmartInboxTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 19/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
#import "JZSwipeCell.h"
#import <MailCore/MailCore.h>

@interface SmartInboxTableViewCell : JZSwipeCell



@property(nonatomic, weak) IBOutlet NSLayoutConstraint * contraintClockWidth;
@property(nonatomic, weak) IBOutlet UIImageView * imgProfile;
@property(nonatomic, weak) IBOutlet UILabel * lblDate;
@property(nonatomic, weak) IBOutlet UILabel * lblSenderName;
@property(nonatomic, weak) IBOutlet UILabel * lblSubject;
@property(nonatomic, weak) IBOutlet UILabel * lblDetail;
@property(nonatomic, weak) IBOutlet UILabel * lblNitificationCount;
@property(nonatomic, weak) IBOutlet UIImageView * imgNitificationCount;
@property(nonatomic, weak) IBOutlet UIButton * btnAttachment;
@property(nonatomic, weak) IBOutlet UIButton * btnFavorite;

@property (nonatomic, strong) MCOIMAPMessageRenderingOperation * messageRenderingOperation;
@property(nonatomic, weak) IBOutlet UIView * containerView;

@end
