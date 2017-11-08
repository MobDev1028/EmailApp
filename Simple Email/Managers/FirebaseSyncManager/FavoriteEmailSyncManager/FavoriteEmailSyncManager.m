//
//  FavoriteEmailSyncManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "FavoriteEmailSyncManager.h"
#import "CoreDataManager.h"
#import "Constants.h"

@implementation FavoriteEmailSyncManager
-(id)init {
    return [self initWithEmail:nil userId:nil];
}
-(id)initWithEmail:(NSString *)email userId:(NSString *)uid {
    self = [super init];
    if (self != nil) {
        self.uid = uid;
        self.fireManager = [[FirebaseManager alloc] init];
        self.path = [NSString stringWithFormat:@"SimpleEmail/%@/favoriteEmails",email];
        [self startNewAdditionListener];
        [self startDeleteListener];
        [self startEditListener];
        /*[self startAllTypeListener];*/
    }
    return self;
}

-(void)changeFavoriteDatabaseWithDictionary:(NSMutableDictionary *)dictionary mark:(BOOL)mark {
    //NSMutableDictionary * dictionary = snapshot.value;
    uint64_t uniqueId = [[dictionary objectForKey:kEMAIL_UNIQUE_ID] longLongValue];
    uint64_t threadId = [[dictionary objectForKey:kEMAIL_THREAD_ID] longLongValue];
    NSMutableArray * array = [CoreDataManager fetchUserIdForEmail:[dictionary objectForKey:kUSER_EMAIL]];
    long userId = -1;
    if (array.count>=1) {
        NSManagedObject * object = [array objectAtIndex:0];
        userId = [[object valueForKey:kUSER_ID] longLongValue];
    }
    if (userId != -1) {
        if ([CoreDataManager isUniqueIdExist:uniqueId forUserId:userId entity:kENTITY_EMAIL]>0 && [CoreDataManager isThreadIdExist:threadId forUserId:userId forFolder:kFolderAllMail entity:kENTITY_EMAIL]>0) {
            
            NSMutableArray * emailArray =  [CoreDataManager fetchThreadForId:threadId userId:userId];
            
            //NSMutableArray * emailArray = [CoreDataManager fetchSingleEmailForUniqueId:uniqueId andUserId:userId];
            if (emailArray.count>0) {
                
                //NSManagedObject * emailObject = [emailArray objectAtIndex:0];
                if (mark) {
                    for (NSManagedObject * emailObject in emailArray) {
                        if (![[emailObject valueForKey:kIS_FAVORITE] boolValue]) {
                            [emailObject setValue:[NSNumber numberWithBool:YES] forKey:kIS_FAVORITE];
                            [emailObject setValue:[dictionary objectForKey:kFAVORITE_FIREBASE_ID] forKey:kFAVORITE_FIREBASE_ID];
                            [emailObject setValue:[NSNumber numberWithBool:[[dictionary objectForKey:kIS_COMPLETE_THREAD_FAVORITE] boolValue]] forKey:kIS_COMPLETE_THREAD_FAVORITE];
                            [CoreDataManager updateData];
                        }
                    }
                    [self postNotification];
                }
                else {
                    for (NSManagedObject * emailObject in emailArray) {
                        [emailObject setValue:[NSNumber numberWithBool:NO] forKey:kIS_FAVORITE];
                        [emailObject setValue:nil forKey:kFAVORITE_FIREBASE_ID];
                        [emailObject setValue:nil forKey:kIS_COMPLETE_THREAD_FAVORITE];
                        [CoreDataManager updateData];
                    }
                    [self postNotification];
                }
            }
        }
        else {
            /* email does not exist
             fetch it from IMAP Server*/
            ThreadFetchManager * threadFetchManager = [[ThreadFetchManager alloc] initWithUserId:self.uid snoozeSync:nil favoriteSync:self];
            
            [dictionary setObject:[NSNumber numberWithBool:mark] forKey:@"mark"];
            [threadFetchManager.threadIdArray addObject:dictionary];
        }
    }
    else {
        /* user Does not exist!!!!! */
    }
}
-(void)startNewAdditionListener {
    [self.fireManager listenNewAdditionAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"FavoriteEmailSyncManager - listenNewAdditionAtPath = %@",snapshot.value);
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
        [dictionary setObject:snapshot.key forKey:kFAVORITE_FIREBASE_ID];
        [self changeFavoriteDatabaseWithDictionary:dictionary mark:YES];
    }onError:^(NSError * Erorr) {
    }];
}
-(void)startDeleteListener {
    [self.fireManager listenRemovedAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"FavoriteEmailSyncManager - listenRemovedAtPath = %@",snapshot.value);
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] initWithDictionary:snapshot.value];
        [dictionary setObject:snapshot.key forKey:kFAVORITE_FIREBASE_ID];
        [self changeFavoriteDatabaseWithDictionary:dictionary mark:NO];
    }onError:^(NSError * Erorr) {
    }];
}
-(void)startEditListener {
    [self.fireManager listenEditAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"FavoriteEmailSyncManager - listenEditAtPath = %@",snapshot.value);
    }onError:^(NSError * Erorr) {
        
    }];
}

/*-(void)startAllTypeListener {
 [self.fireManager listenAnyChangeAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
 NSLog(@"FavoriteEmailSyncManager - listenAnyChangeAtPath = %@",snapshot.value);
 }onError:^(NSError * Erorr) {
 
 }];
 }*/

-(void)deleteFavoriteEmailForFirebaseId:(NSString *)firebaseId {
    [self.fireManager deleteAtPath:self.path firebaseId:firebaseId];
}

-(void)editFavoriteEmailForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:self.path firebaseId:firebaseId data:dictionary];
}

-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:self.path];
}

-(void)postNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_FAVORITE object:nil];
}
@end
