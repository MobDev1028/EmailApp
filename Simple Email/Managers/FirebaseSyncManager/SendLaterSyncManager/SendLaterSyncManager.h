//
//  SendLaterSyncManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"

@interface SendLaterSyncManager : NSObject
@property (nonatomic, strong) FirebaseManager * fireManager;
@property (nonatomic, strong) NSString * encodedEmail;
@property (nonatomic, strong) NSString * path;

-(id)initWithEmail:(NSString *)email userId:(NSString *)uid;
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary;
-(void)pushOneTimeLog:(NSMutableDictionary *)dictionary;
-(void)deleteSendLaterPreferenceForFirebaseId:(NSString *)firebaseId;
-(void)editSendLaterPreferenceForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
-(void)editDefaultOptionForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
@end
