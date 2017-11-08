//
//  MessageDetailCell.h
//  SimpleEmail
//
//  Created by Zahid on 15/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageDetailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblCellTitle;
@property (weak, nonatomic) IBOutlet UIImageView *imgProfile;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblSubTitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * labelX;
@end
