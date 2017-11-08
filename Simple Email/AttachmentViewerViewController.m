//
//  AttachmentViewerViewController.m
//  SimpleEmail
//
//  Created by Zahid on 10/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "AttachmentViewerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "Utilities.h"

@interface AttachmentViewerViewController ()

@end

@implementation AttachmentViewerViewController {
    NSString * imgUrl;
    MBProgressHUD *hud;
    NSData * imageData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    
    self.title = @"Attachment";
    UIBarButtonItem * btnLeftCross = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(btnLeftCrossAction:)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:btnLeftCross, nil];
    [self showProgressHudWithTitle:@""];
    if ([Utilities isValidString:imgUrl]) {
        [self.imgAttachment sd_setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:nil options:SDWebImageHighPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //... completion code here ...
            [self hideProgressHud];
        }];
    }
    else {
        [self hideProgressHud];
        self.imgAttachment.image = [UIImage imageWithData:imageData];
    }
}
-(void)setNSDataImage:(NSData *)data {
    imageData = data;
}
-(void)showImageWithUrl:(NSString *)imageUrl {
    imgUrl = imageUrl;
}

#pragma mark - PrivateMethods
-(void)showProgressHudWithTitle:(NSString *)title {
    /*hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = title;
     */
}
-(void)hideProgressHud {
    /*if (hud) {
        [hud hideAnimated:YES];
    }
     */
}
#pragma mark - UserActions
-(IBAction)btnLeftCrossAction:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc {
    NSLog(@"dealloc - AttachmentViewerViewController");
}
@end
