//
//  SideMenuViewController.h
//  Simple Email
//
//  Created by Zahid on 18/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    IBOutlet NSLayoutConstraint * tableViewBottom;
}
@property(nonatomic, weak) IBOutlet UIImageView * imgProfile;
@property(nonatomic, weak) IBOutlet UILabel * lblProfileName;
@property(nonatomic, weak) IBOutlet UILabel * lblProfileEmail;

@property(nonatomic, weak) IBOutlet UITableView * menuTableView;
@property(nonatomic, weak) IBOutlet UIView * header1;
@property(nonatomic, weak) IBOutlet UIView * header2;
@property(nonatomic, strong) NSMutableArray * users;
-(void)setPresentedRow:(NSInteger)row andSection:(NSInteger)section;
@end
