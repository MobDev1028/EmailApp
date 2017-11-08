//
//  CustomizeSnoozesTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 22/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomizeSnoozesTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UIButton * btnSlection;
@property(nonatomic, weak) IBOutlet UILabel * lblSnoozeTitle;
@property(nonatomic, weak) IBOutlet UILabel * lblSnoozeTime;
@end
