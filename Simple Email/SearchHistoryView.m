//
//  SearchHistoryViewController.m
//  SimpleEmail
//
//  Created by Zahid on 23/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "SearchHistoryView.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "HistoryCell.h"
@interface SearchHistoryView ()

@end

@implementation SearchHistoryView
- (void)awakeFromNib {
    [super awakeFromNib];
    self.historyArray = [CoreDataManager fetchHistory:YES];
    self.isRecent = YES;
    [self.historyTable reloadData];
}
-(void)hideView {
    [self removeFromSuperview];
}
-(void)setUpView {
}
-(void)saveHistory:(NSString *)str isSaved:(BOOL)saved {
    NSMutableArray *ar = [CoreDataManager isHistoryStringExist:str isRecent:YES];
    if (ar.count == 1) {
        NSManagedObject * object = [ar lastObject];
        [object setValue:[NSDate date] forKey:kHISTORY_DATE];
    }
    else {
        [CoreDataManager mapHistoryData:[NSDate date] title:str isRecent:YES];
        NSMutableArray * recents = [CoreDataManager fetchHistory:YES];
        if (recents.count>5) {
            for (int i = 5; i< recents.count; ++i) {
                NSManagedObject * object = [recents objectAtIndex:i];
                [CoreDataManager deleteObject:object];
            }
        }
    }
    [CoreDataManager updateData];
    if (saved) {
        NSMutableArray *ar = [CoreDataManager isHistoryStringExist:str isRecent:NO];
        if (ar.count>0) {
        }
        else {
            [CoreDataManager mapHistoryData:[NSDate date] title:str isRecent:NO];
        }
    }
    
    self.historyArray = [CoreDataManager fetchHistory:self.isRecent];
    [self.historyTable reloadData];
}
-(IBAction)btnActions:(id)sender {
    UIButton * btn = (UIButton *)sender;
    if (btn.tag == 10) { /* btn recent action */
        self.underlineLeading.constant = 0.0f;
        self.isRecent = YES;
    }
    else {
        self.isRecent = NO;
        self.underlineLeading.constant = 77.0f;
    }
    [self.superview setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.superview layoutIfNeeded];
    }];
    self.historyArray = [CoreDataManager fetchHistory:self.isRecent];
    [self.historyTable reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyArray.count;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *emailData = [self.historyArray objectAtIndex:indexPath.row];
    
    NSString * title = [emailData valueForKey:kHISTORY_TITLE];
    [self.delegate actionIndexString:title];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *tableIdentifier = @"HistoryCellIden";
    HistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HistoryCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSManagedObject *emailData = [self.historyArray objectAtIndex:indexPath.row];
    
    NSString * title = [emailData valueForKey:kHISTORY_TITLE];
    cell.lblTitle.text = title;
    return  cell;
}

@end
