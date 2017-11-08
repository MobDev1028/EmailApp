//
//  SnoozeView.h
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SnoozeView;
@protocol SnoozeViewDelegate <NSObject>
@optional
-(void)updateResponseList;
@required
- (void) snoozeView:(SnoozeView *)view didTapOnCustomizeButtonWithViewType:(int)viewType ifNoReply:(BOOL)ifNoReply;
- (void) snoozeView:(SnoozeView *)view didSelectRowAtIndex:(int)Index ifNoReply:(BOOL)ifNoReply;
- (void) snoozeView:(SnoozeView *)view didTapEditButton:(int)viewType;
@end


@interface SnoozeView : UIView {
    CGFloat cellHeight;
    int tableViewType;
}

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * viewTopMarginConstaint;
@property (nonatomic, weak)IBOutlet NSLayoutConstraint * viewHeightConstaint;

@property (assign, nonatomic) id <SnoozeViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView * tableView;
@property (nonatomic, weak) IBOutlet UIButton * btnCustomize;
@property (nonatomic, weak) IBOutlet UIButton * btnCancel;
@property (nonatomic, weak) IBOutlet UIButton * btnEdit;
@property (nonatomic, weak) IBOutlet UILabel  * lblViewTitle;
@property (nonatomic, strong) NSArray * dataSourceArray;
@property (nonatomic, assign) int selectedIndex;
-(void)setDataSource:(NSArray * )dataSource;
-(void)setTableViewType:(int)_tableViewType;
-(int)getTableViewType;
-(void)setButtonTitles:(NSString *)buttonTitle1  buttonTitle2:(NSString *)buttonTitle2;
-(void)setTableViewCellHeight:(CGFloat)_cellHeight;
-(void)setViewHeight:(CGFloat)height screenHeight:(CGFloat)screenHeight;
-(void)setViewXvalue:(CGFloat)xValue;
-(void)setViewTitle:(NSString * )title;
-(void)setUserId:(NSString * )userId email:(NSString *)email;

@end
