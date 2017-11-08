//
//  CustomKeyBoardToolBar.h
//  SimpleEmail
//
//  Created by Zahid on 25/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CustomKeyBoardToolBarDelegate <NSObject>

- (void) customKeyBoardBoldDelegate ;
- (void) customKeyBoardItalicDelegate;
- (void) customKeyBoardSendLaterDelegate;
- (void) customKeyBoardBulletsDelegate;
- (void) customKeyBoardNotesDelegate;
@end

@interface CustomKeyBoardToolBar : UIToolbar
@property (assign, nonatomic) id <CustomKeyBoardToolBarDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIButton * btnSendLater;
@end
