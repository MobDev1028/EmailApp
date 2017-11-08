//
//  MessageGroupCell.h
//  SimpleEmail
//
//  Created by Zahid on 21/12/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageGroupCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIWebView * lblHtmlView;
@property (nonatomic, weak) IBOutlet UILabel * lblTitle;
@property (nonatomic, weak) IBOutlet UILabel * lblDate;
@property (nonatomic, weak) IBOutlet UIButton * btnDetail;
@property (nonatomic, weak) IBOutlet UIButton * btnMore;
@property (nonatomic, weak) IBOutlet UILabel * lblPreview;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, weak) IBOutlet UIView * activityContainer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint  * bottomBar;
@end
