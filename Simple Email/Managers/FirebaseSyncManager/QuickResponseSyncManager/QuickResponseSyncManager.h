//
//  QuickResponseSyncManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"
#import "FirebaseStorageManager.h"

@interface QuickResponseSyncManager : NSObject
@property (nonatomic, strong) FirebaseManager * fireManager;
@property (nonatomic, strong) FirebaseStorageManager * firebaseStorageManager;
@property (nonatomic, strong) NSString * encodedEmail;
@property (nonatomic, strong) NSString * path;

-(id)initWithEmail:(NSString *)email userId:(NSString *)uid;
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary;
-(void)deleteQuickResponseForFirebaseId:(NSString *)firebaseId;
-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary;
-(void)editQuickResponseForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
-(void)uploadImageToFirebaseStorage:(NSMutableDictionary *)dictionary;
-(void) deleteFirebaseStorage:(NSMutableDictionary *)dictionary;
@end
