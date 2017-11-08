//
//  ComposeQuickResponseViewController.h
//  SimpleEmail
//
//  Created by Zahid on 21/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataManager.h"

@interface ComposeQuickResponseViewController : UIViewController <UIImagePickerControllerDelegate>
//@property (nonatomic, weak) IBOutlet UITextView * txtView;
@property (nonatomic, weak) NSManagedObject * object;
@property (nonatomic, weak) IBOutlet UIView * textEditorContainerView;
@end
