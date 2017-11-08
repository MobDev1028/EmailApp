//
//  NotificationPreferencesCell.h
//  SimpleEmail
//
//  Created by Zahid on 26/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationPreferencesCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UIView * viewTopLine;
@property(nonatomic, weak) IBOutlet UIView * viewBottomLine;
@property(nonatomic, weak) IBOutlet UIView * viewSeparator;

@property(nonatomic, weak) IBOutlet UILabel * lblTitle;
@property(nonatomic, weak) IBOutlet UILabel * lblDetail;
@property(nonatomic, weak) IBOutlet UIButton * checkButton;
@end
