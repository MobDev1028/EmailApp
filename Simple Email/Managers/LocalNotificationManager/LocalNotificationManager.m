//
//  LocalNotificationManager.m
//  SimpleEmail
//
//  Created by Zahid on 09/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "LocalNotificationManager.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "Constants.h"

@implementation LocalNotificationManager

- (void)scheduleAlarmForDate:(NSDate*)theDate withBody:(NSString *)stringBody isNewEmailNotification:(BOOL)isNewEmailNotification forEmailId:(NSString * )emailId andUserId:(NSString * )userId firebaseId:(NSString * )firebaseId onlyIfNoReply:(BOOL)onlyIfNoReply userEmail:(NSString *)userEmail threadId:(NSString *)threadId {
    //if(SYSTEM_VERSION_LESS_THAN(@"10.0")) {
        
        UIApplication* app = [UIApplication sharedApplication];
        
        // Create a new notification.
        UILocalNotification* alarm = [[UILocalNotification alloc] init];
        
        if ([Utilities isValidString:emailId] && !isNewEmailNotification) {
            // cancel notification if any is already set for id
            [self cancelNotificationForEmailId:emailId];
            
            // save emailId in user info for reference
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      emailId,@"decimal_id",
                                      userId,kSELECTED_ACCOUNT,
                                      firebaseId, kSNOOZED_FIREBASE_ID,
                                      [NSNumber numberWithBool:onlyIfNoReply],kSNOOZED_ONLY_IF_NO_REPLY,
                                      userEmail,@"user_email",
                                      threadId, kTHREAD_DEC,
                                      nil];
            alarm.userInfo = userInfo;
        }
    
        if (alarm) {
            if (isNewEmailNotification) { // notification for new email arival
                theDate = [[NSDate date] dateByAddingTimeInterval:(1*2)];
            }
            alarm.fireDate = theDate;
            alarm.timeZone = [NSTimeZone systemTimeZone];
            alarm.repeatInterval = 0;
            alarm.alertBody = stringBody;
            //alarm.repeatInterval = kCFCalendarUnitDay;
            //alarm.applicationIconBadgeNumber = 0;
            [app scheduleLocalNotification:alarm];
            
            NSArray * notifications = [app scheduledLocalNotifications];
            NSLog(@"all notificarions = %@", notifications);
        }
//    }
//    else { /* This is iOS 10 or later */
//        
//        
//        NSLog(@"NSDate:%@",theDate);
//        
//        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//        if (isNewEmailNotification) { // notification for new email arival
//            theDate = [[NSDate date] dateByAddingTimeInterval:(1*2)];
//        }
//        [calendar setTimeZone:[NSTimeZone localTimeZone]];
//        
//        NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit|NSTimeZoneCalendarUnit fromDate:theDate];
//        
//        //NSDate *todaySehri = [calendar dateFromComponents:components]; //unused
//        
//        
//        
//        UNMutableNotificationContent *objNotificationContent = [[UNMutableNotificationContent alloc] init];
//        
//        
//        if ([Utilities isValidString:emailId] && !isNewEmailNotification) {
//            // cancel notification if any is already set for id
//            [self cancelNotificationForEmailId:emailId];
//            
//            // save emailId in user info for reference
//            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                      emailId,kEMAIL_THREAD_ID,
//                                      userId,kSELECTED_ACCOUNT,
//                                      firebaseId, kSNOOZED_FIREBASE_ID,
//                                      [NSNumber numberWithBool:onlyIfNoReply],kSNOOZED_ONLY_IF_NO_REPLY,
//                                      nil];
//            objNotificationContent.userInfo = userInfo;
//        }
//        
//        
//        
//        objNotificationContent.title = [NSString localizedUserNotificationStringForKey:@"Snooze Alert!" arguments:nil];
//        objNotificationContent.body = [NSString localizedUserNotificationStringForKey:stringBody
//                                                                            arguments:nil];
//        objNotificationContent.sound = [UNNotificationSound defaultSound];
//        
//        /// 4. update application icon badge number
//        //objNotificationContent.badge = @([[UIApplication sharedApplication] applicationIconBadgeNumber] + 1);
//        
//        
//        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
//        
//        
//        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"ten"
//                                                                              content:objNotificationContent trigger:trigger];
//        /// 3. schedule localNotification
//        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//            if (!error) {
//                NSLog(@"Local Notification succeeded");
//            }
//            else {
//                NSLog(@"Local Notification failed");
//            }
//        }];
//    }
}

-(void)cancelNotificationForEmailId:(NSString *)strId {
    UIApplication* app = [UIApplication sharedApplication];
    NSArray * oldNotifications = [app scheduledLocalNotifications];
    if (oldNotifications.count>0) {
        NSArray * notiArray = [oldNotifications objectsAtIndexes:[oldNotifications indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return [[[obj userInfo] valueForKey:@"decimal_id"] isEqualToString:strId]; }]];
        if (notiArray && notiArray.count>0) {
            UILocalNotification *row = [notiArray objectAtIndex:0];
            if (row) {
                NSLog(@"local notification removed");
                [[UIApplication sharedApplication] cancelLocalNotification:row];
            }
        }
    }
}
-(void)dealloc {
    NSLog(@"dealloc - LocalNotificationManager");
}

@end
