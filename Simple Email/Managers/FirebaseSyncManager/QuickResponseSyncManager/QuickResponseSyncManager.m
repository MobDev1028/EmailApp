//
//  QuickResponseSyncManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "QuickResponseSyncManager.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "FirebaseStorageManager.h"
@import FirebaseStorage;

@implementation QuickResponseSyncManager {
    NSString * quickResponseExistPath;
}
-(id)init {
    return [self initWithEmail:nil userId:nil];
}
-(id)initWithEmail:(NSString *)email userId:(NSString *)uid {
    self = [super init];
    if (self != nil) {
        self.fireManager = [[FirebaseManager alloc] init];
        self.firebaseStorageManager = [[FirebaseStorageManager alloc] init];
        self.path = [NSString stringWithFormat:@"SimpleEmail/%@/quickResponse",email];
        quickResponseExistPath = [NSString stringWithFormat:@"SimpleEmail/%@/quickResponseExist",email];
        [self quickResponseExistListenerWithEmail:email userId:uid];
        [self startNewAdditionListener];
        [self startDeleteListener];
        [self startEditListener];
        /*[self startAllTypeListener];*/
    }
    return self;
}
-(void)startNewAdditionListener {
    [self.fireManager listenNewAdditionAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
       // NSLog(@"QuickResponseSyncManager - listenNewAdditionAtPath = %@ and key = %@",snapshot.value ,snapshot.key);
        NSMutableArray * array = [CoreDataManager fetchQuickResponseForFirebaseId:snapshot.key];
        if (array.count<=0) {
            [CoreDataManager saveQuickResponsesWithSnapshot:snapshot];
            [self postNotificationWithFirebaseId:snapshot.key];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)quickResponseExistListenerWithEmail:(NSString *)email userId:(NSString *)userid {
    [self.fireManager isQuickResponseAdded:quickResponseExistPath completionBlock:^(FIRDataSnapshot *snapshot) {
        if ([snapshot.value isKindOfClass:[NSNull class]]) {
            [Utilities preloadQuickResponsesForEmail:email andUserId:userid];
            
            [Utilities syncToFirebase:[NSMutableDictionary dictionaryWithObjectsAndKeys:email,kUSER_EMAIL,
                                       nil] syncType:[QuickResponseSyncManager class] userId:userid performAction:kActionOnce firebaseId:nil];
        }
        
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startDeleteListener {
    [self.fireManager listenRemovedAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"QuickResponseSyncManager - listenRemovedAtPath = %@",snapshot.value);
        NSMutableArray * array = [CoreDataManager fetchQuickResponseForFirebaseId:snapshot.key];
        if (array.count>=1) {
            [CoreDataManager deleteObject:[array lastObject]];
            [CoreDataManager updateData];
            [self postNotificationWithFirebaseId:snapshot.key];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startEditListener {
    [self.fireManager listenEditAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"QuickResponseSyncManager - listenEditAtPath = %@",snapshot.value);
        
        NSMutableArray * array = [CoreDataManager fetchQuickResponseForFirebaseId:snapshot.key];
        if (array.count>=1) {
            [CoreDataManager deleteObject:[array lastObject]];
            [CoreDataManager updateData];
            
            /* save new snapshot in  */
            [CoreDataManager saveQuickResponsesWithSnapshot:snapshot];
            [self postNotificationWithFirebaseId:snapshot.key];
        }
    }onError:^(NSError * Erorr) {
        
    }];
}
-(void)startAllTypeListener {
    [self.fireManager listenAnyChangeAtPath:self.path completionBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"QuickResponseSyncManager - listenAnyChangeAtPath = %@",snapshot.value);
    }onError:^(NSError * Erorr) {
        
    }];
}

-(void)deleteQuickResponseForFirebaseId:(NSString *)firebaseId {
    [self.fireManager deleteAtPath:self.path firebaseId:firebaseId];
}

-(void)editQuickResponseForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary {
    [self.fireManager editAtPath:self.path firebaseId:firebaseId data:dictionary];
}
-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:quickResponseExistPath];
}
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary {
    [self.fireManager pushFirebaseServer:dictionary atPath:self.path];
}
-(void)postNotificationWithFirebaseId:(NSString *)firebaseId {
    NSDictionary * dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 firebaseId,kFIREBASE_ID,
                                 nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNSNOTIFICATIONCENTER_QUICKREPONSE object:self userInfo:dictionary];
}

#pragma mark - FirebaseStorageManager

-(void)uploadImageToFirebaseStorage:(NSMutableDictionary *)dictionary {
    [self.firebaseStorageManager uploadImageData:dictionary completionBlock:^(FIRStorageMetadata *storageMetadata ,NSString * firebaseId, NSString * uid) {
        NSDictionary * dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     firebaseId,kFIREBASE_ID,
                                     nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kIMAGE_UPLOADED object:self userInfo:dictionary];
        
//        NSLog(@"attachment successful");
//        NSLog(@"imageStorageLink = %@", storageMetadata.downloadURL.description);
//        NSLog(@"firebaseId = %@", firebaseId);
//        NSLog(@"userId = %@", uid);
        [self updateQuickResponse:firebaseId withUrl:[storageMetadata.downloadURL absoluteString] attachmentValue:@"1" uid:uid];
        
    }onError:^(NSError *error) {
        
    }progress:^(FIRStorageTaskSnapshot * snapshot) {
        
    }];
}

-(void) deleteFirebaseStorage:(NSMutableDictionary *)dictionary {
    [self.firebaseStorageManager deleteData:dictionary completionBlock:^(NSString * fireId, NSString * uid) {
        [self updateQuickResponse:fireId withUrl:@"" attachmentValue:@"0" uid:uid];
    }onError:^(NSError * error) {
        
    }];
}

-(void)updateQuickResponse:(NSString *)fireId withUrl:(NSString *)url attachmentValue :(NSString *)value uid:(NSString *)userId {
    NSMutableArray * array = [CoreDataManager fetchQuickResponseForFirebaseId:fireId];
    if (array.count>=1) {
        NSManagedObject * object = [array lastObject];
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setObject:[object valueForKey:kQUICK_REPONSE_Text] forKey:kQUICK_REPONSE_Text];
        [dictionary setObject:[object valueForKey:kQUICK_REPONSE_HTML] forKey:kQUICK_REPONSE_HTML];
        [dictionary setObject:url forKey:kQUICK_REPONSE_ATTACHMENT_PATH];
        [dictionary setObject:value forKey:kQUICK_REPONSE_ATTACHMENT_AVAILABLE];
        [dictionary setObject:[object valueForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
        //NSLog(@"email = %@", [object valueForKey:kUSER_EMAIL]);
        [Utilities syncToFirebase:dictionary syncType:[QuickResponseSyncManager class] userId:userId performAction:kActionEdit firebaseId:fireId];
    }
}
@end
