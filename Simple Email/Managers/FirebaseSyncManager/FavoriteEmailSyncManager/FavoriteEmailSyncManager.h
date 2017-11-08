//
//  FavoriteEmailSyncManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"
#import "ThreadFetchManager.h"

@interface FavoriteEmailSyncManager : NSObject
@property (nonatomic, strong) FirebaseManager * fireManager;
@property (nonatomic, strong) NSString * encodedEmail;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * uid;

-(id)initWithEmail:(NSString *)email userId:(NSString *)uid;
-(void)pushDataToFirebase:(NSMutableDictionary *)dictionary;
-(void)deleteFavoriteEmailForFirebaseId:(NSString *)firebaseId;
-(void)editFavoriteEmailForFirebaseId:(NSString *)firebaseId data:(NSMutableDictionary *)dictionary;
-(void)changeFavoriteDatabaseWithDictionary:(NSMutableDictionary *)dictionary mark:(BOOL)mark;
@end
