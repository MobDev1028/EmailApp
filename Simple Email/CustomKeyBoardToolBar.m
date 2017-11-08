//
//  CustomKeyBoardToolBar.m
//  SimpleEmail
//
//  Created by Zahid on 25/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "CustomKeyBoardToolBar.h"

@interface CustomKeyBoardToolBar ()

@end

@implementation CustomKeyBoardToolBar
#pragma  - mark User Actions
- (IBAction)btnBoldAction:(id)sender {
    NSLog(@"https://www.appcoda.com/intro-text-kit-ios-programming-guide/");
    [self.delegate customKeyBoardBoldDelegate];
}

-(IBAction)btnItalicAction:(id)sender {
    NSLog(@"https://www.appcoda.com/intro-text-kit-ios-programming-guide/");
    [self.delegate customKeyBoardItalicDelegate];
}

-(IBAction)btnSendLaterAction:(id)sender {
    [self.delegate customKeyBoardSendLaterDelegate];
}

-(IBAction)btnBulletsAction:(id)sender {
    NSLog(@"https://www.appcoda.com/intro-text-kit-ios-programming-guide/");
    [self.delegate customKeyBoardBulletsDelegate];
}

-(IBAction)btnAlignAction:(id)sender {
    NSLog(@"https://www.appcoda.com/intro-text-kit-ios-programming-guide/");
    [self.delegate customKeyBoardNotesDelegate];
}

@end
