//
//  SendLaterSyncManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SendLaterSyncManager.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "FirebaseManager.h"
#import "Utilities.h"

@implementation SendLaterSyncManager {
    NSString * preferenceExistPath;
}

-(id)init {
    return [self initWithEmail:nil userId:nil];
}
-(id)initWithEmail:(NSString *)email userId:(NSString *)uid {
    self = [super init];
    if (self != nil) {
        self.fireManager = [[FirebaseManager alloc] init];
        self.path = [NSString stringWithFormat:@"SimpleEmail/%@/sendLaterPreference",email];
        preferenceExistPath = [NSString stringWithFormat:@"SimpleEmail/%@/sendLaterPreferenceSelectedOption",email];
        [self quickResponseExistListenerWithEmail:email userId:uid];
        [self startNewAdditionListener];
        [self startDeleteListener];
        [self startEditListener];
        //[self startEditListenerForDefault];
        //[self startAllTypeListener];
    }
    return self;
}
-(void)startNewAdditionListener {
    [self.fireManager listenNewAdditionAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSMutableArray * array = [CoreDataManager fetchSendlaterPreferencesForFirebaseId:snapshot.key];
        if (array.count<=0) {
            NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
            [dictionary setObject:[NSNumber numberWithBool:NO] forKey:kSNOOZE_IS_DEFAULT];
            [dictionary setObject:snapshot.key forKey:kSEND_PREFERENCES_FIREBASEID];
            [CoreDataManager saveSendLaterPreferencesWithData:dictionary];
            //[self postNotification];
        }
        
    }onError:^(NSError * Erorr) {
        
    }];
}

-(void)quickResponseExistListenerWithEmail:(NSString *)email userId:(NSString *)userid {
    [self.fireManager isQuickResponseAdded:preferenceExistPath completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozePreferenceManager - listenNewAdditionAtPath = %@ and key = %@",snapshot.value ,snapshot.key);
        
        if ([snapshot.value isKindOfClass:[NSNull class]]) {
            
            [Utilities preloadSendLaterPreferencesForEmail:email andUserId:userid saveLocally:NO];
            
            [Utilities syncToFirebase:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"1",kUSE_DEFAULT,                                       nil] syncType:[SendLaterSyncManager class] userId:userid performAction:kActionOnce firebaseId:nil];
        }
        else {
            NSLog(@"Print Send Later");
            //            [Utilities setUserDefaultWithValue:kUSE_DEFAULT andKey:[snapshot.value objectForKey:kUSE_DEFAULT] ];
            //            [Utilities setUserDefaultWithValue:kSNOOZE_PREFERENCE_FIREBASE_ID andKey:snapshot.key];
        }
        
    }onError:^(NSError * Erorr) {
        
    }];
}

-(void)startDeleteListener {
    [self.fireManager listenRemovedAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSMutableArray * array = [CoreDataManager fetchSendlaterPreferencesForFirebaseId:snapshot.key];
        if (array.count>=1) {
            [CoreDataManager deleteObject:[array lastObject]];
            [CoreDataManager updateData];
            [self postNotification];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startEditListener {
    [self.fireManager listenEditAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSMutableArray * array = [CoreDataManager fetchSendlaterPreferencesForFirebaseId:snapshot.key];
        if (array.count>=1) {
            NSMutableDictionary * dic = snapshot.value;
            
            NSManagedObject * object = [array objectAtIndex:0];
            [object setValue:[NSNumber numberWithBool:NO] forKey:kSNOOZE_IS_DEFAULT];
            [object setValue:snapshot.key forKey:kSEND_PREFERENCES_FIREBASEID];
            [object setValue:[NSNumber numberWithInt:[[dic objectForKey:kSEND_MINUTE_COUNT] intValue]] forKey:kSEND_MINUTE_COUNT];
            [object setValue:[NSNumber numberWithInt:[[dic objectForKey:kSEND_HOUR_COUNT] intValue]] forKey:kSEND_HOUR_COUNT];
            [object setValue:[dic objectForKey:@"timePeriod"] forKey:@"timePeriod"];
            [object setValue:[dic objectForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
            [object setValue:[dic objectForKey:kSEND_LATER_TITLE] forKey:kSEND_LATER_TITLE];
            [object setValue:[NSNumber numberWithBool:[[dic objectForKey:kIS_PREFERENCE_ACTIVE] boolValue]] forKey:kIS_PREFERENCE_ACTIVE];
            [CoreDataManager updateData];
            [self postNotification];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startEditListenerForDefault {
    [self.fireManager listenEditAtPath:preferenceExistPath completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"SnoozePreferenceManager - startEditListenerForDefault = %@",snapshot.value);
        [Utilities setUserDefaultWithValue:[snapshot.value objectForKey:kUSE_DEFAULT] andKey: kUSE_DEFAULT];
        [Utilities setUserDefaultWithValue:snapshot.key andKey:kSEND_PREFERENCES_FIREBASEID];
        [self postNotification];
        
    }onError:^(NSError * Erorr) {
        
    }];
}

-(void)editDefaultOptionForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:preferenceExistPath firebaseId:firebaseId data:dictionary];
}

-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:preferenceExistPath];
}

-(void)deleteSendLaterPreferenceForFirebaseId:(NSString *)firebaseId {
    [self.fireManager deleteAtPath:self.path firebaseId:firebaseId];
}

-(void)editSendLaterPreferenceForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:self.path firebaseId:firebaseId data:dictionary];
}
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:self.path];
}
-(void)postNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_SEND_LATER object:nil];
}
@end
