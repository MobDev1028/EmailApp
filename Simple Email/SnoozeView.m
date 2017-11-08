//
//  SnoozeView.m
//  SimpleEmail
//
//  Created by Zahid on 20/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SnoozeView.h"
#import "SnoozeTableViewCell.h"
#import "CustomTableViewCell.h"
#import "CustomCellHeader.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "QuickResponseTableViewCell.h"
#import "ComposeQuickResponseViewController.h"
#import "Utilities.h"
#import "QuickResponseSyncManager.h"

@interface SnoozeView ()

@end

@implementation SnoozeView {
    BOOL actionOnlyReply;
    BOOL allowTxtFieldEdit;
    NSString * uid;
    NSString * email;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectedIndex = -1;
    self.dataSourceArray = [[NSArray alloc] init];
    self.tableView.allowsSelectionDuringEditing = YES;
}
#pragma - mark UITableViewDataSource
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return allowTxtFieldEdit;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableViewType == 3) {
        
        return self.dataSourceArray.count+2;
    }
    else {
        if (tableViewType == 1) {
            return self.dataSourceArray.count + 1;
        }
        return self.dataSourceArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableViewType == 1) {
        
        static NSString *tableIdentifier = @"SnoozeTableCell";
        SnoozeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SnoozeTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return [self configureSnoozeTableViewCell:cell forRowAtIndexPath:indexPath];
    }
    else {
        if (tableViewType == 3 && indexPath.row == 1) {
            static NSString *tableIdentifier = @"CustomCellHeader";
            
            CustomCellHeader *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
            
            if (cell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomCellHeader" owner:self options:nil];
                cell = [nib objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            return  cell;
        }
        
        if (tableViewType == 2) {
            static NSString *tableIdentifier = @"QuickResponseCell";
            QuickResponseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
            if (cell == nil) {
                NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"QuickResponseTableViewCell" owner:self options:nil];
                cell = [nib objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.editingAccessoryType = UITableViewCellEditingStyleNone;
            }
            return [self customiseQuickResponseCell:cell forRowAtIndexPath:indexPath];
        }
        
        static NSString *tableIdentifier = @"CustomCell";
        CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return [self configureCustomTableViewCell:cell forRowAtIndexPath:indexPath];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (tableViewType == 3 && indexPath.row == 1) {
        return 64.0f;
    }
    return cellHeight;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    // Return the number of sections.
    if (tableViewType == 3) {
        return 2;
    }
    else {
        return 1;
    }
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *tableIdentifier = @"CustomCellHeader";
    
    CustomCellHeader *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomCellHeader" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return  cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.0f;
    }
    else {
        return 64.0f;
    }
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableViewType == 1) {
        SnoozeTableViewCell *cell = (SnoozeTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (indexPath.row == self.dataSourceArray.count) {
            cell.imgLeftImage.highlighted = !cell.imgLeftImage.highlighted;
            actionOnlyReply = !cell.imgLeftImage.highlighted;
        }
        else {
            [self removeFromSuperview];
            [self.delegate snoozeView:self didSelectRowAtIndex:(int)indexPath.row ifNoReply:actionOnlyReply];
        }
    }
    else if (tableViewType == 2) {
        
        if (allowTxtFieldEdit) {
            [Utilities editQuickReponseWithObject:[self.dataSourceArray objectAtIndex:indexPath.row]];
            return;
        }
        
        [self.delegate snoozeView:self didSelectRowAtIndex:(int)indexPath.row ifNoReply:NO];
        [self removeFromSuperview];
    }
    else if (tableViewType == 3) {
        if (indexPath.row == 0) {
            [self.delegate snoozeView:self didSelectRowAtIndex:(int)indexPath.row ifNoReply:NO];
            [self removeFromSuperview];
            return;
        }
        else if (indexPath.row >= 2) {
            NSManagedObject * object = [self.dataSourceArray objectAtIndex:indexPath.row-2];
            int prefId = [[object valueForKey:kPREFERENCE_ID] intValue];
            if (prefId == 6) {
                [self.delegate snoozeView:self didSelectRowAtIndex:0 ifNoReply:NO];
                [self removeFromSuperview];
                return;
            }
        }
        if (indexPath.row != 0 && indexPath.row != 1) {
            self.selectedIndex = (int)indexPath.row;
            [self.tableView reloadData];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject * object = [self.dataSourceArray objectAtIndex:indexPath.row];
    NSString * firebaseId = [object valueForKey:kFIREBASE_ID];
    if ([[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue]) {
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setObject:firebaseId forKey:kFIREBASE_ID];
        [dictionary setObject:uid forKey:kUSER_ID];
        NSString * path = [NSString stringWithFormat:@"%@/images/%@",[object valueForKey:kUSER_EMAIL],firebaseId];
        [dictionary setObject:path forKey:@"path"];
        [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:uid performAction:kActionDeleteAttachment firebaseId:nil];
    }
    [Utilities syncToFirebase:nil syncType:[QuickResponseSyncManager class] userId:uid performAction:kActionDelete firebaseId:firebaseId];
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
}

#pragma  - mark user Actions
-(IBAction)btnCancelAction:(id)sender {
    [self sendUpdateCall];
    self.tableView.editing = NO;
    allowTxtFieldEdit = NO;
    [self.btnEdit setTitle:@"Edit" forState:UIControlStateNormal];
    [self removeFromSuperview];
}
-(IBAction)btnCustomizeAction:(id)sender {
    if (tableViewType != 2) {
        if (tableViewType == 3 && self.selectedIndex == -1) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Alert!!" message:@"Please select date/time first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            return;
        }
        [self removeFromSuperview];
    }
    [self.delegate snoozeView:self didTapOnCustomizeButtonWithViewType:tableViewType ifNoReply:actionOnlyReply];
}
-(IBAction)btnEditAction:(id)sender {
    if (self.getTableViewType == 3) {
        [self.delegate snoozeView:self didTapEditButton:tableViewType];
        [self removeFromSuperview];
        return;
    }
    self.tableView.editing = !self.tableView.editing;
    allowTxtFieldEdit = !allowTxtFieldEdit;
    if (allowTxtFieldEdit) {
        [self.btnEdit setTitle:@"Done" forState:UIControlStateNormal];
    }
    else {
        [self sendUpdateCall];
        [self.btnEdit setTitle:@"Edit" forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
}
-(void)setDataSource:(NSArray *)dataSource {
    actionOnlyReply = YES;
    self.dataSourceArray = dataSource;
    [self.tableView reloadData];
    if (self.dataSourceArray.count>0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
    }
}
-(void)setTableViewType:(int)_tableViewType {
    [self.btnEdit setHidden:YES];
    if (_tableViewType == 2) {
        [self.btnEdit setHidden:NO];
    }
    if (_tableViewType == 3) {
        [self.btnEdit setHidden:NO];
        [self.btnEdit setTitle:@"Customize" forState:UIControlStateNormal];
    }
    tableViewType = _tableViewType;
}
-(int)getTableViewType {
    return tableViewType;
}
-(void)setButtonTitles:(NSString *)buttonTitle1  buttonTitle2:(NSString *)buttonTitle2 {
    [self.btnCustomize setTitle:buttonTitle1 forState: UIControlStateNormal];
    [self.btnCancel setTitle:buttonTitle2 forState: UIControlStateNormal];
}

-(void)setTableViewCellHeight:(CGFloat)_cellHeight; {
    cellHeight = _cellHeight;
}

-(void)setViewHeight:(CGFloat)height screenHeight:(CGFloat)screenHeight {
    [self setNeedsUpdateConstraints];
    if ((self.viewTopMarginConstaint.constant + height ) > screenHeight) {
        height = screenHeight;
        self.viewTopMarginConstaint.constant = 0.0f;
    }
    else if (tableViewType == 1) {
        if (screenHeight<510) {
            self.viewTopMarginConstaint.constant = 0.0f;
            height = screenHeight;
        }
        else {
            self.viewTopMarginConstaint.constant = 35.0f;
            height = screenHeight - 70;
        }
    }
    self.viewHeightConstaint.constant = height;
    [self layoutIfNeeded];
}

-(void)setViewXvalue:(CGFloat)xValue {
    [self setNeedsUpdateConstraints];
    self.viewTopMarginConstaint.constant = xValue;
    [self layoutIfNeeded];
}
-(void)setViewTitle:(NSString * )title {
    self.lblViewTitle.text = title;
}
-(void)setUserId:(NSString * )userId email:(NSString *)uemail {
    uid = userId;
    email = uemail ;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDataSpurce) name:kNSNOTIFICATIONCENTER_QUICKREPONSE object:nil];
}
-(void)sendUpdateCall {
    if([self.delegate respondsToSelector: @selector(updateResponseList)]) {
        [self.delegate updateResponseList];
    }
}
#pragma - mark Private Methods
-(void)updateDataSpurce {
    self.dataSourceArray = nil;
    self.dataSourceArray = [[NSArray alloc] init];
    self.dataSourceArray = [CoreDataManager fetchQuickResponsesForEmail:[Utilities encodeToBase64:email]];
    [self.tableView reloadData];
}
-(SnoozeTableViewCell *)configureSnoozeTableViewCell:(SnoozeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * strImgName = nil;
    NSString * strTitle = nil;
    NSString * dateTime = nil;
    cell.separator.hidden = NO;
    if (indexPath.row<self.dataSourceArray.count) {
        NSManagedObject * object = [self.dataSourceArray objectAtIndex:indexPath.row];
        dateTime = [object valueForKey:kTIME_STRING];
        strImgName = [object valueForKey:kIMAGE];
        strTitle = [object valueForKey:kSNOOZE_TITLE];
    }
    else {
        strImgName = @"snooze_ok";
        strTitle = @"Only if no one replies";
        cell.separator.hidden = YES;
        dateTime = @"";
    }
    cell.lblDateTime.text = dateTime;
    
    cell.lblTitle.text = strTitle;
    cell.imgLeftImage.image = [UIImage imageNamed:strImgName];
    return cell;
}
-(QuickResponseTableViewCell *)customiseQuickResponseCell:(QuickResponseTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject * object  = [self.dataSourceArray objectAtIndex:indexPath.row];
    NSLog(@"url = %@", [object valueForKey:kQUICK_REPONSE_ATTACHMENT_PATH]);
    cell.txtResponses.enabled = NO;
    cell.imgAttachment.hidden = ![[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue];
    cell.txtResponses.text = [object valueForKey:kQUICK_REPONSE_Title];
    cell.txtResponses.delegate = self;
    cell.txtResponses.tag = indexPath.row;
    return cell;
}
-(CustomTableViewCell *)configureCustomTableViewCell:(CustomTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableViewType == 2) {
        cell.imgLeft.image = [UIImage imageNamed:@"btn_attachment_bg"];
        NSManagedObject * object = [self.dataSourceArray objectAtIndex:indexPath.row];
        cell.imgLeft.hidden = ![[object valueForKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE] boolValue];
        cell.lblCellTitle.text = [object valueForKey:kQUICK_REPONSE_Text];
    }
    else {
        NSString * imgName = nil;
        if (indexPath.row == 0) {
            cell.imgLeft.hidden = NO;
            imgName = @"file_attach_arraow";
        }
        else {
            if (indexPath.row == self.selectedIndex) {
                imgName = @"selection_bg";
                cell.imgLeft.hidden = NO;
            }
            else {
                imgName = @"selection_bg";
                cell.imgLeft.hidden = YES;
            }
        }
        
        [cell.imgLeft setImage:[UIImage imageNamed:imgName]];
        if (indexPath.row == 0) {
            cell.lblCellTitle.text = @"Pick Date & Time";
        }
        else {
            NSManagedObject * object = [self.dataSourceArray objectAtIndex:indexPath.row-2];
            cell.lblCellTitle.text = [object valueForKey:kSEND_LATER_TITLE];
            NSLog(@"FIrebase ID %@", [object valueForKey:kSEND_PREFERENCES_FIREBASEID]);
        }
    }
    return cell;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNSNOTIFICATIONCENTER_QUICKREPONSE
                                                  object:nil];
    NSLog(@"dealloc : SnoozeView");
}
@end
