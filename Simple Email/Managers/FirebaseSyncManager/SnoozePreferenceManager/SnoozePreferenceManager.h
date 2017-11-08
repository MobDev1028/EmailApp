//
//  SnoozePreferenceManager.h
//  SimpleEmail
//
//  Created by Zahid on 07/10/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"

@interface SnoozePreferenceManager : NSObject
@property (nonatomic, strong) FirebaseManager * fireManager;
@property (nonatomic, strong) NSString * encodedEmail;
@property (nonatomic, strong) NSString * path;

-(id)initWithEmail:(NSString *)email userId:(NSString *)uid;
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary;
-(void)deleteSnoozePreferenceForFirebaseId:(NSString *)firebaseId;
-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary;
-(void)editSnoozePreferenceForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
-(void)editDefaultOptionForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
@end
