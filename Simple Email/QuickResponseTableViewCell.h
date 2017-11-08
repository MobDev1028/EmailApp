//
//  QuickResponseTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface QuickResponseTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UITextField * txtResponses;
@property (nonatomic, weak) IBOutlet UIImageView * imgAttachment;
@end
