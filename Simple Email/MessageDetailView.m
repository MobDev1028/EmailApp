//
//  MessageDetailView.m
//  SimpleEmail
//
//  Created by Zahid on 15/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "MessageDetailView.h"
#import "MessageDetailCell.h"
#import "Utilities.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MessageDetailView ()

@end

@implementation MessageDetailView

- (void)awakeFromNib {
    [super awakeFromNib];

    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.containerView.layer.shadowOpacity = 0.5f;
}

-(void)setupView {
    self.lbldate.text = @"";
    if (self.date != nil) {
        self.lbldate.text = [Utilities getStringFromDate:self.date withFormat:@"MMM d, hh:mm a"];
    }
    [self.tableView reloadData];
}
-(void)setViewPosition:(CGFloat)y screenHeight:(CGFloat)screenheight {
    CGFloat size = y + 215 + 15;
    if (size>screenheight) {
        size = y - 215;
    }
    else {
        size = y + 20;
    }
    self.viewTop.constant = size;
    [self.superview setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.25f animations:^{
        [self.superview layoutIfNeeded];
    }];
}
#pragma -mark Private Methods
-(void)hideView {
    [self removeFromSuperview];
    [self.delegate messageDetailViewDidRemoveFromSuperView];
}

#pragma -mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return  self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"";
    
    MessageDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MessageDetailCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        NSUInteger row = indexPath.row;
        if (row == 0 && indexPath.section == 0) {
            [cell.imgProfile setHidden:NO];
            [cell.imgProfile sd_setImageWithURL:[NSURL URLWithString:self.profileImageUrl] placeholderImage:[UIImage imageNamed:@"profile_image_placeholder"]];
            cell.labelX.constant = 33.0f;
        }
        else {
            [cell.imgProfile setHidden:YES];
            cell.labelX.constant = -3.0f;
        }
        [cell setNeedsUpdateConstraints];
        [cell layoutIfNeeded];
        
        NSMutableDictionary * dictionary = [self.dataArray objectAtIndex:row];
        cell.lblCellTitle.text = [dictionary objectForKey:@"cellTitle"];
        NSString * title = [dictionary objectForKey:@"title"];
        if (row == self.dataArray.count-1) {
            if (![Utilities isValidString:title]) {
                title = @"(no subject)";
            }
            cell.lblTitle.numberOfLines = 2;
        }
        cell.lblTitle.text = title;
        cell.lblSubTitle.text = [dictionary objectForKey:@"subTitle"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
#pragma -mark UITableViewDelegate

#pragma - mark UserActions
-(IBAction)btnHideView:(id)sender {
    [self hideView];
}
-(void)dealloc {
    NSLog(@"MessageDetailView - dealloc");
}
@end
