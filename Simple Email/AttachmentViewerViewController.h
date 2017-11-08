//
//  AttachmentViewerViewController.h
//  SimpleEmail
//
//  Created by Zahid on 10/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttachmentViewerViewController : UIViewController
@property (nonatomic, weak) IBOutlet UIImageView * imgAttachment;
-(void)showImageWithUrl:(NSString *)imageUrl;
-(void)setNSDataImage:(NSData *)data;
@end
