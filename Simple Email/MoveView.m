//
//  MoveView.m
//  SimpleEmail
//
//  Created by Zahid on 18/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "MoveView.h"
#import "MoveCell.h"
#import "Constants.h"

@interface MoveView ()
@end

@implementation MoveView
- (void)awakeFromNib {
    [super awakeFromNib];
}
-(void)setupView {
    self.container.layer.masksToBounds = YES;
    self.container.layer.cornerRadius = 5.0f;
    if (self.folderType == kFolderInboxMail) {
        self.foldersArray = [[NSArray alloc] initWithObjects:@"Spam",@"Trash",@"Starred",nil ];
    }
    else if (self.folderType == kFolderSnoozeMail) {
        self.foldersArray = [[NSArray alloc] initWithObjects:@"Inbox", @"Spam",@"Trash",@"Starred",nil ];
    }
    else if (self.folderType == kFolderArchiveMail) {
        self.foldersArray = [[NSArray alloc] initWithObjects:@"Inbox", @"Spam",@"Trash",@"Starred",nil ];
    }
    else if (self.folderType == kFolderTrashMail) {
        self.foldersArray = [[NSArray alloc] initWithObjects:@"Inbox", @"Spam",@"Starred",nil ];
    }
    else if (self.folderType == kFolderSentMail) {
        self.foldersArray = [[NSArray alloc] initWithObjects:@"Trash",@"Starred",nil ];
    }
    [self.tableView reloadData];
}
#pragma mark user actions
-(IBAction)btnHideView:(id)sender {
    [self hideView];
}
#pragma -mark Private Methods
-(void)hideView {
    [self removeFromSuperview];
    //[self.delegate messageDetailViewDidRemoveFromSuperView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"MoveCellIden";
    MoveCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MoveCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString * title = [self.foldersArray objectAtIndex:indexPath.row];
    cell.lblTitle.text = title;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}
#pragma - mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.foldersArray.count;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

#pragma - mark UITableView delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate actionIndexString:[self.foldersArray objectAtIndex:indexPath.row]];
}

@end
