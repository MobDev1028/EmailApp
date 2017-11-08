//
//  SnoozePreferenceManager.m
//  SimpleEmail
//
//  Created by Zahid on 07/10/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SnoozePreferenceManager.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "Utilities.h"

@implementation SnoozePreferenceManager{
    NSString * preferenceExistPath;
}
-(id)init {
    return [self initWithEmail:nil userId:nil];
}
-(id)initWithEmail:(NSString *)email userId:(NSString *)uid {
    self = [super init];
    if (self != nil) {
        self.fireManager = [[FirebaseManager alloc] init];
        self.path = [NSString stringWithFormat:@"SimpleEmail/%@/SnoozePreference",email];
        preferenceExistPath = [NSString stringWithFormat:@"SimpleEmail/%@/snoozePreferenceSelectedOption",email];
        [self quickResponseExistListenerWithEmail:email userId:uid];
        [self startNewAdditionListener];
        [self startDeleteListener];
        [self startEditListener];
        [self startEditListenerForDefault];
        /*[self startAllTypeListener];*/
    }
    return self;
}-(void)startNewAdditionListener {
    [self.fireManager listenNewAdditionAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"SnoozePreferenceManager - listenNewAdditionAtPath = %@ and key = %@",snapshot.value ,snapshot.key);
        
        NSMutableArray * array = [CoreDataManager fetchSnoozePreferenceForFirebaseId:snapshot.key];
        if (array.count<=0) {
            NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
            [dictionary setObject:[NSNumber numberWithBool:NO] forKey:kSNOOZE_IS_DEFAULT];
            [dictionary setObject:snapshot.key forKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
            [CoreDataManager saveSnoozePreferencesWithData:dictionary];
            //[self postNotification];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}

-(void)quickResponseExistListenerWithEmail:(NSString *)email userId:(NSString *)userid {
    [self.fireManager isQuickResponseAdded:preferenceExistPath completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozePreferenceManager - listenNewAdditionAtPath = %@ and key = %@",snapshot.value ,snapshot.key);
        
        if ([snapshot.value isKindOfClass:[NSNull class]]) {
    
            [Utilities preloadSnoozePreferencesForEmail:email andUserId:userid saveLocally:NO];
            
            [Utilities syncToFirebase:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"1",kUSE_DEFAULT,                                       nil] syncType:[SnoozePreferenceManager class] userId:userid performAction:kActionOnce firebaseId:nil];
        }
        else {
//            [Utilities setUserDefaultWithValue:kUSE_DEFAULT andKey:[snapshot.value objectForKey:kUSE_DEFAULT] ];
//            [Utilities setUserDefaultWithValue:kSNOOZE_PREFERENCE_FIREBASE_ID andKey:snapshot.key];
        }
        
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startDeleteListener {
    [self.fireManager listenRemovedAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"SnoozePreferenceManager - listenRemovedAtPath = %@",snapshot.value);
        NSMutableArray * array = [CoreDataManager fetchSnoozePreferenceForFirebaseId:snapshot.key];
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
        //NSLog(@"SnoozePreferenceManager - listenEditAtPath = %@",snapshot.value);
        
        NSMutableArray * array = [CoreDataManager fetchSnoozePreferenceForFirebaseId:snapshot.key];
        if (array.count>=1) {
            NSMutableDictionary * dic = snapshot.value;
            
            NSManagedObject * object = [array objectAtIndex:0];
            [object setValue:[NSNumber numberWithBool:NO] forKey:kSNOOZE_IS_DEFAULT];
            [object setValue:snapshot.key forKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
            [object setValue:[NSNumber numberWithInt:[[dic objectForKey:@"snoozeHourCount"] intValue]] forKey:@"snoozeHourCount"];
            [object setValue:[NSNumber numberWithInt:[[dic objectForKey:@"snoozeMinuteCount"] intValue]] forKey:@"snoozeMinuteCount"];
            [object setValue:[dic objectForKey:@"timePeriod"] forKey:@"timePeriod"];
            [object setValue:[dic objectForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
            [object setValue:[dic objectForKey:@"timeString"] forKey:@"timeString"];
            [object setValue:[NSNumber numberWithBool:[[dic objectForKey:@"isPreferenceActive"] boolValue]] forKey:@"isPreferenceActive"];
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
        [Utilities setUserDefaultWithValue:snapshot.key andKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
        [self postNotification];
        
    }onError:^(NSError * Erorr) {
        
    }];
}
/*-(void)startAllTypeListener {
    [self.fireManager listenAnyChangeAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"SnoozePreferenceManager - listenAnyChangeAtPath = %@",snapshot.value);
    }onError:^(NSError * Erorr) {
        
    }];
}*/

-(void)deleteSnoozePreferenceForFirebaseId:(NSString *)firebaseId {
    [self.fireManager deleteAtPath:self.path firebaseId:firebaseId];
}

-(void)editSnoozePreferenceForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:self.path firebaseId:firebaseId data:dictionary];
}
-(void)editDefaultOptionForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:preferenceExistPath firebaseId:firebaseId data:dictionary];
}
-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:preferenceExistPath];
}
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:self.path];
}
-(void)postNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_SNOOZE_PREFERENCE object:nil];
}
@end
