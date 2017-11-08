//
//  DraftTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface DraftTableViewCell : MGSwipeTableCell
@property (nonatomic, weak) IBOutlet UILabel * lblSubject;
@property (nonatomic, weak) IBOutlet UILabel * lblPreview;
@property (nonatomic, weak) IBOutlet UIImageView * imgDraft;
@end
