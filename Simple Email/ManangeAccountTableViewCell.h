//
//  ManangeAccountTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ManangeAccountTableViewCell : UITableViewCell
@property(nonatomic,weak) IBOutlet UIView *sepView;
@property(nonatomic,weak) IBOutlet UILabel *lblName;
@property(nonatomic,weak) IBOutlet UILabel *lblMail;
@property(nonatomic,weak) IBOutlet UIImageView *imgProfilePic;
@end
