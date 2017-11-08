//
//  AccountDetailEditCell.h
//  SimpleEmail
//
//  Created by Zahid on 26/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountDetailEditCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIView *separator;
@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UITextField *txtEditor;
@end
