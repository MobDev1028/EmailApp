//
//  MoveView.h
//  SimpleEmail
//
//  Created by Zahid on 18/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MoveViewDelegate <NSObject>
- (void)actionIndexString:(NSString *)string;
@end

@interface MoveView : UIView
@property (assign, nonatomic) id <MoveViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIView * container;
@property (nonatomic, weak) IBOutlet UIButton * btnEmailText;
@property (nonatomic, weak) IBOutlet UITableView * tableView;
@property (nonatomic, assign) int folderType;
@property (nonatomic, strong) NSArray * foldersArray;
-(void)setupView;
@end
