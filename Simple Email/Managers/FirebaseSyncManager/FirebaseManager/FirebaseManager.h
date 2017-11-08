//
//  FirebaseManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
@import FirebaseDatabase;
@import Firebase;

@interface FirebaseManager : NSObject
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
/*@property (strong, nonatomic) FIRStorageReference *storageRef;*/
@property (nonatomic, strong) NSString * listnerPath;
@property (nonatomic, strong) NSString * listnerType;
@property (nonatomic, strong) NSString * userId;

-(void)listenNewAdditionAtPath:(NSString *)path
               completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                       onError:(void (^)(NSError* error))onError;
-(void)listenRemovedAtPath:(NSString *)path
           completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                   onError:(void (^)(NSError* error))onError;
-(void)listenMovedAtPath:(NSString *)path
         completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                 onError:(void (^)(NSError* error))onError;
-(void)listenAnyChangeAtPath:(NSString *)path
             completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                     onError:(void (^)(NSError* error))onError;
-(void)listenEditAtPath:(NSString *)path
        completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                onError:(void (^)(NSError* error))onError;

-(void)deleteAtPath:(NSString *)path firebaseId:(NSString *)uid;
-(void)removeObserverAtPath:(NSString *)path;
-(void)pushFirebaseServer:(NSMutableDictionary *)dictionary atPath:(NSString *)path;
-(void)editAtPath:(NSString *)path firebaseId:(NSString *)uid data:(NSDictionary *)dictionary;
-(void)isQuickResponseAdded:(NSString *)path
            completionBlock:(void (^)(FIRDataSnapshot *snapshot))completionBlock
                    onError:(void (^)(NSError* error))onError;
@end
