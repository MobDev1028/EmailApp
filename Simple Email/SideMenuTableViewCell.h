//
//  SideMenuTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 19/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideMenuTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UIImageView * imgLeftIcon;
@property(nonatomic, weak) IBOutlet UILabel * lblTitle;
@property(nonatomic, weak) IBOutlet UILabel * lblEmail;
@property(nonatomic, weak) IBOutlet UILabel * lblNotificationCount;
@property(nonatomic, weak) IBOutlet UIImageView * imgNotification;
@end
