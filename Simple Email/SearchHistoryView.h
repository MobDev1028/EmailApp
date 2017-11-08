//
//  SearchHistoryViewController.h
//  SimpleEmail
//
//  Created by Zahid on 23/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SearchHistoryViewDelegate <NSObject>
- (void)actionIndexString:(NSString *)string;
@end
@interface SearchHistoryView : UIView
@property (assign, nonatomic) id <SearchHistoryViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * underlineLeading;
@property (nonatomic, strong) NSMutableArray * historyArray;
@property (nonatomic, weak) IBOutlet UITableView * historyTable;
@property (nonatomic, assign) BOOL isRecent;
-(void)saveHistory:(NSString *)str isSaved:(BOOL)saved;
-(void)hideView;
-(void)setUpView;
@end
