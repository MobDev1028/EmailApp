//
//  SnoozeEmailSyncManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"
#import "ThreadFetchManager.h"

@interface SnoozeEmailSyncManager : NSObject
@property (nonatomic, strong) FirebaseManager * fireManager;
@property (nonatomic, strong) NSString * encodedEmail;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * uid;

-(id)initWithEmail:(NSString *)email userId:(NSString *)uid;
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary;
-(void)deleteSnoozeEmailForFirebaseId:(NSString *)firebaseId;
-(void)editSnoozeEmailForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
-(void)changeSnoozeDatabaseWithDictionary:(NSMutableDictionary *)dictionary saveType:(int)type;
@end
