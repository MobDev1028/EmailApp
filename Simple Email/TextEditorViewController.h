//
//  TextEditorViewController.h
//  SimpleEmail
//
//  Created by Zahid on 27/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
@interface TextEditorViewController : ZSSRichTextEditor
- (void)dismissToolbar;
- (void)displayToolbar;
- (NSString *)exportHtml;
- (NSString *)exportText;
- (void)importHtml:(NSString *)html;
- (void)insertHtml:(NSString *)html;
@end
