//
//  wbviewViewController.m
//  SimpleEmail
//
//  Created by Zahid on 12/01/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import "wbviewViewController.h"

@interface wbviewViewController ()

@end

@implementation wbviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.productURL = @"<div style=\"padding-bottom: 20px;\"></div><div><html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<title></title>\n</head>\n<body>\n<div dir=\"ltr\"><br />\n<div class=\"gmail_quote\">---------- Forwarded mess";
    // Do any additional setup after loading the view from its nib.
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
//    NSURLRequest *URLRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.spacetelescope.org/static/archives/images/large/opo0328a.jpg"]];
//    [self.webView loadRequest:URLRequest];
    [self.webView loadHTMLString:self.productURL baseURL:nil];
    
    [self.webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && [object isKindOfClass:[WKWebView class]]) {
        WKWebView * webview = (WKWebView *)object;
        NSLog(@"%f", webview.estimatedProgress);
        if (webview.estimatedProgress == 1) {
            UIScrollView *scrollView = webview.scrollView;
            NSLog(@"New contentSize: %f x %f", scrollView.contentSize.width, scrollView.contentSize.height);
        }
        // estimatedProgress is a value from 0.0 to 1.0
        // Update your UI here accordingly
    }
    else {
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
