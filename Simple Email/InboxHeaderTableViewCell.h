//
//  InboxHeaderTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 19/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InboxHeaderTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel * lbHeaderlTitle;
@property(nonatomic, weak) IBOutlet UILabel * lbHeaderlEmail;
@property(nonatomic, weak) IBOutlet UIButton * btnHeader;
@end
