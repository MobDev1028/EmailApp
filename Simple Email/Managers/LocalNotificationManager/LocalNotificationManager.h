//
//  LocalNotificationManager.h
//  SimpleEmail
//
//  Created by Zahid on 09/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface LocalNotificationManager : NSObject
- (void)scheduleAlarmForDate:(NSDate*)theDate withBody:(NSString *)stringBody isNewEmailNotification:(BOOL)isNewEmailNotification forEmailId:(NSString * )emailId andUserId:(NSString * )userId firebaseId:(NSString * )firebaseId onlyIfNoReply:(BOOL)onlyIfNoReply userEmail:(NSString *)userEmail threadId:(NSString *)threadId;
-(void)cancelNotificationForEmailId:(NSString *)strId;
@end
