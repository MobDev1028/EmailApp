//
//  CustomTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 22/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel * lblCellTitle;
@property(nonatomic, weak) IBOutlet UIImageView* imgLeft;
@end
