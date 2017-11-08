//
//  SnoozeTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SnoozeTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel* lblTitle;
@property (nonatomic, weak) IBOutlet UILabel* lblDateTime;
@property (nonatomic, weak) IBOutlet UIImageView * imgLeftImage;
@property (nonatomic, weak) IBOutlet UIView * separator;
@end
