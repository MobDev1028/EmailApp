//
//  QuickReplyCell.h
//  SimpleEmail
//
//  Created by Zahid on 16/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickReplyCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIButton * btnMore;
@property (nonatomic, weak) IBOutlet UIButton * btnQR1;
@property (nonatomic, weak) IBOutlet UIButton * btnQR2;
@property (nonatomic, weak) IBOutlet UIButton * btnQR3;
@property (nonatomic, weak) IBOutlet UIView * container;
@end
