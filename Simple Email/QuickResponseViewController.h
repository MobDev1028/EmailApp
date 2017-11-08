//
//  QuickResponseViewController.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickResponseViewController : UIViewController
@property(nonatomic, weak) IBOutlet UITableView * responseTableView;
@property(nonatomic, strong) NSMutableArray * dataArray;
-(void)removeDelegates;
@end
