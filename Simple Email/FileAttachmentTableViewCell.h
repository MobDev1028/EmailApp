//
//  FileAttachmentTableViewCell.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileAttachmentTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel * lblFileName;
@property(nonatomic, weak) IBOutlet UIImageView * imgFile;
@property(nonatomic, weak) IBOutlet UIView * viewSep;
@property(nonatomic, weak) IBOutlet UIView * viewSep1;
@property(nonatomic, weak) IBOutlet UIView * bgview;
@property(nonatomic, weak) IBOutlet UIView * arrowView;
@property(nonatomic, weak) IBOutlet UIButton * btnRemoveAttachment;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * activityIndicator;
@end
