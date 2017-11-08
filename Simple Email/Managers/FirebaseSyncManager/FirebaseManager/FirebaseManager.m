//
//  FirebaseManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "FirebaseManager.h"

@implementation FirebaseManager
FIRDatabaseHandle _refHandle;

- (id) init {
    self = [super init];
    if (self != nil) {
        _messages = [[NSMutableArray alloc] init];
        [self configureDatabase];
    }
    return self;
}

-(void)removeObserverAtPath:(NSString *)path {
    [[_ref child:path] removeObserverWithHandle:_refHandle];
}
-(void)listenNewAdditionAtPath:(NSString *)path
               completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                       onError:(void (^)(NSError* error))onError {
    _ref = [[FIRDatabase database] reference];
    
    // Listen for new messages in the Firebase database
    /* SimpleEmail/shehryaar786@gmail.com/favorite */
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        if (snapshot != nil) {
            completionBlock(snapshot);
        }
    }];
}
-(void)isQuickResponseAdded:(NSString *)path
               completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                       onError:(void (^)(NSError* error))onError {

    _ref = [[FIRDatabase database] reference];
    
    [[_ref child:path]  observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        completionBlock(snapshot);
        
        // ...
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
        onError(error);
    }];
}
-(void)listenRemovedAtPath:(NSString *)path
           completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                   onError:(void (^)(NSError* error))onError {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    /* SimpleEmail/shehryaar786@gmail.com/favorite */
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        if (snapshot != nil) {
            completionBlock(snapshot);
        }
    }];
}
-(void)listenEditAtPath:(NSString *)path
        completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                onError:(void (^)(NSError* error))onError {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    /* SimpleEmail/shehryaar786@gmail.com/favorite */
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        if (snapshot != nil) {
            completionBlock(snapshot);
        }
    }];
}
-(void)listenMovedAtPath:(NSString *)path
         completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                 onError:(void (^)(NSError* error))onError {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    /* SimpleEmail/shehryaar786@gmail.com/favorite */
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildMoved withBlock:^(FIRDataSnapshot *snapshot) {
        if (snapshot != nil) {
            completionBlock(snapshot);
        }
    }];
}
-(void)listenAnyChangeAtPath:(NSString *)path
             completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                     onError:(void (^)(NSError* error))onError {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    /* SimpleEmail/shehryaar786@gmail.com/favorite */
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        if (snapshot != nil) {
            completionBlock(snapshot);
        }
    }];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
}

-(void)deleteAtPath:(NSString *)path firebaseId:(NSString *)uid {
    /* Delete data from Firebase Database */
    [[[_ref child:path] child:uid]  setValue:nil];

}
-(void)editAtPath:(NSString *)path firebaseId:(NSString *)uid data:(NSDictionary *)dictionary {
    /* Edit data from Firebase Database */
    [[[_ref child:path] child:uid]  setValue:dictionary];
}

-(void)pushFirebaseServer:(NSMutableDictionary *)dictionary atPath:(NSString *)path {
    NSString * key = [[_ref child:path] childByAutoId].key;
    /* Push data to Firebase Database */
    [[[self.ref child:path] child:key] setValue:dictionary];
}

@end
