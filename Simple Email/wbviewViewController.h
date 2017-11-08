//
//  wbviewViewController.h
//  SimpleEmail
//
//  Created by Zahid on 12/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface wbviewViewController : UIViewController
@property (nonatomic, strong) WKWebView * webView;
@property (strong, nonatomic) NSString *productURL;
@end
