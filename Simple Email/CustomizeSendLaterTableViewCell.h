//
//  CustomizeSendLaterTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 22/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
@interface CustomizeSendLaterTableViewCell : MGSwipeTableCell
@property(nonatomic, weak) IBOutlet UIView * viewAddMoreButton;
@property(nonatomic, weak) IBOutlet UIView * viewSendLaterLabel;
@property(nonatomic, weak) IBOutlet UIButton * btnAddMore;
@property(nonatomic, weak) IBOutlet UILabel * lblSendLater;
@property(nonatomic, weak) IBOutlet UILabel * lblSendTime;
@end
