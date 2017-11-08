//
//  TextEditorViewController.m
//  SimpleEmail
//
//  Created by Zahid on 27/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "TextEditorViewController.h"
#import "Constants.h"

@interface TextEditorViewController ()

@end

@implementation TextEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.alwaysShowToolbar = YES;
    self.receiveEditorDidChangeEvents = YES;
    self.toolbarItemTintColor = [UIColor colorWithRed:143.0f/255.0f green:143.0f/255.0f blue:143.0f/255.0f alpha:1.0f];
    self.toolbarItemTintColor = [UIColor colorWithRed:143.0f/255.0f green:143.0f/255.0f blue:143.0f/255.0f alpha:1.0f];
    // Choose which toolbar items to show
    self.enabledToolbarItems = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarItalic,ZSSRichTextEditorToolbarOrderedList,ZSSRichTextEditorToolbarJustifyLeft,ZSSRichTextEditorToolbarJustifyCenter,ZSSRichTextEditorToolbarJustifyRight];
    /* ZSSRichTextEditorToolbarInsertImageFromDevice ,ZSSRichTextEditorToolbarUnorderedList*/
    // Create the custom buttons
    UIButton *btnSendLater = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 99, 43.0f)];
    [btnSendLater setImage:[UIImage imageNamed:@"btn_keyboard_send_later"] forState:UIControlStateNormal];
    [btnSendLater addTarget:self
                     action:@selector(btnSendLaterAction:)
           forControlEvents:UIControlEventTouchUpInside];
    [self addCustomToolbarItemWithButton:btnSendLater];
    
    // HTML Content to set in the editor
    /*NSString *html = @"<!-- This is an HTML comment -->"
     "<p>This is a test of the <strong>ZSSRichTextEditor</strong> by <a title=\"Zed Said\" href=\"http://www.zedsaid.com\">Zed Said Studio</a></p>";*/
    
    // Set the base URL if you would like to use relative links, such as to images.
    self.baseURL = [NSURL URLWithString:@"http://www.zedsaid.com"];
    self.shouldShowKeyboard = NO;
    self.alwaysShowToolbar = NO;
    // Set the HTML contents of the editor
    [self setPlaceholder:@"Compose email..."];
    //[self setHTML:html];
}

- (void)showInsertURLAlternatePicker {
    
    [self dismissAlertView];
    
    //    ZSSDemoPickerViewController *picker = [[ZSSDemoPickerViewController alloc] init];
    //    picker.demoView = self;
    //    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    //    nav.navigationBar.translucent = NO;
    //    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showInsertImageAlternatePicker {
    
    [self dismissAlertView];
    
    //    ZSSDemoPickerViewController *picker = [[ZSSDemoPickerViewController alloc] init];
    //    picker.demoView = self;
    //    picker.isInsertImagePicker = YES;
    //    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    //    nav.navigationBar.translucent = NO;
    //    [self presentViewController:nav animated:YES completion:nil];
    
}


- (NSString *)exportHTML {
    return [self getHTML];
    //NSLog(@"%@", [self getText]);
    
    //For testing issues with returning to the editor from another view.
    
    //DemoModalViewController *destViewController = [[DemoModalViewController alloc] init];
    //[self presentViewController:destViewController animated:NO completion:nil];
    
}

- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html {
    
    //NSLog(@"Text Has Changed: %@", text);
    
    //NSLog(@"HTML Has Changed: %@", html);
    
}

- (void)hashtagRecognizedWithWord:(NSString *)word {
    NSLog(@"Hashtag has been recognized: %@", word);
}

- (void)mentionRecognizedWithWord:(NSString *)word {
    NSLog(@"Mention has been recognized: %@", word);
}
#pragma - mark UserAction
-(IBAction)btnSendLaterAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFICATION_SEND_LATER object:nil];
}

#pragma - mark Private Methods
-(void)dismissToolbar {
    [self hideToolbar];
}

-(void)displayToolbar {
    [self showToolbar];
}

- (NSString *)exportHtml {
    return [self getHTML];
}

- (NSString *)exportText {
    return [self getText];
}

- (void)importHtml:(NSString *)html {
    [self setHTML:html];
}

- (void)insertHtml:(NSString *)html {
    [self insertHTML:html];
}

-(void)dealloc {
    NSLog(@"dealloc - TextEditorViewController");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
