//
//  EmailUpdateManager.h
//  SimpleEmail
//
//  Created by Zahid on 09/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
@class EmailUpdateManager;
@protocol EmailUpdateManagerDelegate <NSObject>
- (void)emailUpdateManager:(EmailUpdateManager*)manager didReceiveNewEmailWithId:(long)userId;
@end

@interface EmailUpdateManager : NSObject
@property (nonatomic, strong) MCOIMAPSession * imapSession;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) NSString * folderName;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * currentLoginMailAddress;
@property (assign, nonatomic) id <EmailUpdateManagerDelegate> delegate;
- (void)createUpdateSessionWithId:(NSString *)uid;
- (void)performFetchTask;
@end
