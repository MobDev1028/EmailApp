//
//  SnoozeEmailSyncManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SnoozeEmailSyncManager.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "LocalNotificationManager.h"

@implementation SnoozeEmailSyncManager {
    LocalNotificationManager * localNotificationManager;
}
-(id)init {
    return [self initWithEmail:nil userId:nil];
}
-(id)initWithEmail:(NSString *)email userId:(NSString *)uid {
    self = [super init];
    if (self != nil) {
        self.uid = uid;
        self.fireManager = [[FirebaseManager alloc] init];
        self.path = [NSString stringWithFormat:@"SimpleEmail/%@/snoozeEmails",email];
        [self startNewAdditionListener];
        [self startDeleteListener];
        [self startEditListener];
        /*[self startAllTypeListener];*/
    }
    return self;
}
-(void)changeSnoozeDatabaseWithDictionary:(NSMutableDictionary *)dictionary saveType:(int)type {
    /* type = 1 >> insertion
     type = 2 >> delete
     type = 3 >> edit
     */
    uint64_t uniqueId = [[dictionary objectForKey:kEMAIL_UNIQUE_ID] longLongValue];
    uint64_t threadId = [[dictionary objectForKey:kEMAIL_THREAD_ID] longLongValue];
    NSMutableArray * array = [CoreDataManager fetchUserIdForEmail:[dictionary objectForKey:kUSER_EMAIL]];
    long userId = -1;
    if (array.count>=1) {
        NSManagedObject * object = [array objectAtIndex:0];
        userId = [[object valueForKey:kUSER_ID] longValue];
    }
    if (userId != -1) {
        if ([CoreDataManager isUniqueIdExist:uniqueId forUserId:userId entity:kENTITY_EMAIL]>0 && [CoreDataManager isThreadIdExist:threadId forUserId:userId forFolder:kFolderAllMail entity:kENTITY_EMAIL]>0) {
            NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:threadId userId:userId];
            
            if (emailArray.count>0) {
                if (type == 1 || type == 3) { /* type = 1 >> insertion*/
                    /* type = 3 >> edit */
                    NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:threadId userId:userId];
                    for (NSManagedObject * emailObject in emailArray) {
                        if (type == 1) {
                            if ([[emailObject valueForKey:kIS_SNOOZED] boolValue]) {
                                return; /* already snoozed */
                            }
                        }
                        NSString * firebaseKey = [dictionary objectForKey:kSNOOZED_FIREBASE_ID];
                        [emailObject setValue:firebaseKey forKey:kSNOOZED_FIREBASE_ID];
                        [emailObject setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kIS_COMPLETE_THREAD_SNOOZED] boolValue]] forKey:kIS_COMPLETE_THREAD_SNOOZED];
                        NSTimeInterval timeStamp = [[dictionary objectForKey:kSNOOZED_DATE] doubleValue];
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
                        
                        NSTimeInterval snoozeMarkedAtTimestamp = [[dictionary objectForKey:kSNOOZED_MARKED_AT] doubleValue];
                        NSDate * snoozedMarkedAt = [NSDate dateWithTimeIntervalSince1970:snoozeMarkedAtTimestamp];
                        
                        
                        [emailObject setValue:[NSNumber numberWithBool:YES] forKey:kIS_SNOOZED];
                        [emailObject setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kSNOOZED_ONLY_IF_NO_REPLY] boolValue]] forKey:kSNOOZED_ONLY_IF_NO_REPLY];
                        [emailObject setValue:date forKey:kSNOOZED_DATE];
                        [emailObject setValue:snoozedMarkedAt forKey:kSNOOZED_MARKED_AT];
                        [CoreDataManager updateData];
                    }
                    
                    if (localNotificationManager == nil) {
                        localNotificationManager = [[LocalNotificationManager alloc] init];
                    }
                    NSTimeInterval timeStamp = [[dictionary objectForKey:kSNOOZED_DATE] doubleValue];
                    NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
                    NSMutableArray * emailArra = [CoreDataManager fetchSingleEmailForUniqueId:uniqueId andUserId:userId];
                    NSManagedObject * emailObject = [emailArra objectAtIndex:0];
                    BOOL onlyIfNoReply = [[dictionary objectForKey:kSNOOZED_ONLY_IF_NO_REPLY] boolValue];
                    NSString * email = [dictionary objectForKey:kUSER_EMAIL];
                    [localNotificationManager scheduleAlarmForDate:date withBody:[NSString stringWithFormat:@"Snoozed Alert: %@",[emailObject valueForKey:kEMAIL_TITLE]] isNewEmailNotification:NO forEmailId:[NSString stringWithFormat:@"%llu",uniqueId] andUserId:[NSString  stringWithFormat:@"%ld", userId] firebaseId:[dictionary objectForKey:kSNOOZED_FIREBASE_ID] onlyIfNoReply:onlyIfNoReply userEmail:email threadId:[NSString stringWithFormat:@"%llu",threadId]];
                    
                }
                else if (type == 2) { /* type = 2 >> delete */
                    if (localNotificationManager == nil) {
                        localNotificationManager = [[LocalNotificationManager alloc] init];
                    }
                    [localNotificationManager cancelNotificationForEmailId:[NSString stringWithFormat:@"%llu",threadId]];
                    NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:threadId userId:userId];
                    for (NSManagedObject * emailObject in emailArray) {
                        [emailObject setValue:nil forKey:kSNOOZED_FIREBASE_ID];
                        [emailObject setValue:nil forKey:kIS_COMPLETE_THREAD_SNOOZED];
                        [emailObject setValue:[NSNumber numberWithBool:NO] forKey:kIS_SNOOZED];
                        [emailObject setValue:nil forKey:kSNOOZED_ONLY_IF_NO_REPLY];
                        [emailObject setValue:nil forKey:kSNOOZED_DATE];
                        [emailObject setValue:nil forKey:kSNOOZED_MARKED_AT];
                        [CoreDataManager updateData];
                    }
                }
                
                [self postNotification];
            }
            else{
                NSLog(@"ELSE CASE !!!");
            }
        }
        else {
            
            if (type == 2) { /* type = 2 >> delete */
                if (localNotificationManager == nil) {
                    localNotificationManager = [[LocalNotificationManager alloc] init];
                }
                [localNotificationManager cancelNotificationForEmailId:[NSString stringWithFormat:@"%llu",threadId]];
                NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:threadId userId:userId];
                for (NSManagedObject * emailObject in emailArray) {
                    [emailObject setValue:nil forKey:kSNOOZED_FIREBASE_ID];
                    [emailObject setValue:nil forKey:kIS_COMPLETE_THREAD_SNOOZED];
                    [emailObject setValue:[NSNumber numberWithBool:NO] forKey:kIS_SNOOZED];
                    [emailObject setValue:nil forKey:kSNOOZED_ONLY_IF_NO_REPLY];
                    [emailObject setValue:nil forKey:kSNOOZED_DATE];
                    [CoreDataManager updateData];
                }
                return;
            }
            /* email does not exist
             fetch it from IMAP Server*/
            ThreadFetchManager * threadFetchManager = [[ThreadFetchManager alloc] initWithUserId:self.uid snoozeSync:self favoriteSync:nil];
            
            [dictionary setObject:[NSString stringWithFormat:@"%d",type] forKey:@"saveType"];
            [threadFetchManager.threadIdArray addObject:dictionary];
            [threadFetchManager startOperation];
        }
    }
    else {
        /* user Does not exist!!!!! */
    }
}

-(void)startNewAdditionListener {
    [self.fireManager listenNewAdditionAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozeEmailSyncManager - listenNewAdditionAtPath = %@",snapshot.value);
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
        [dictionary setObject:snapshot.key forKey:kSNOOZED_FIREBASE_ID];
        [self changeSnoozeDatabaseWithDictionary:dictionary saveType:1];
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startDeleteListener {
    [self.fireManager listenRemovedAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozeEmailSyncManager - listenRemovedAtPath = %@",snapshot.value);
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
        [dictionary setObject:snapshot.key forKey:kSNOOZED_FIREBASE_ID];
        [self changeSnoozeDatabaseWithDictionary:dictionary saveType:2];
        
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startEditListener {
    [self.fireManager listenEditAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozeEmailSyncManager - listenEditAtPath = %@",snapshot.value);
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
        [dictionary setObject:snapshot.key forKey:kSNOOZED_FIREBASE_ID];
        [self changeSnoozeDatabaseWithDictionary:dictionary saveType:3];
    }onError:^(NSError * Erorr) {
        
    }];
}
/*-(void)startAllTypeListener {
 [self.fireManager listenAnyChangeAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
 NSLog(@"SnoozeEmailSyncManager - listenAnyChangeAtPath = %@",snapshot.value);
 }onError:^(NSError * Erorr) {
 
 }];
 }*/
-(void)deleteSnoozeEmailForFirebaseId:(NSString *)firebaseId {
    [self.fireManager deleteAtPath:self.path firebaseId:firebaseId];
}

-(void)editSnoozeEmailForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:self.path firebaseId:firebaseId data:dictionary];
}

-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:self.path];
}

-(void)postNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_SNOOZE object:nil];
}
@end
