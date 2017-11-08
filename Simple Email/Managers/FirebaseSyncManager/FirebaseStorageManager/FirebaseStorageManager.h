//
//  FirebaseStorageManager.h
//  SimpleEmail
//
//  Created by Zahid on 07/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseManager.h"
@import FirebaseStorage;

@interface FirebaseStorageManager : NSObject
-(void)uploadImageData:(NSMutableDictionary*)dictionary
       completionBlock:(void (^)(FIRStorageMetadata *metaData, NSString * firebaseId, NSString * userId))completionBlock
               onError:(void (^)(NSError* error))onError
              progress:(void (^)(FIRStorageTaskSnapshot *snapshot))progress;
-(void)deleteData:(NSMutableDictionary*)dictionary
  completionBlock:(void (^)(NSString * firebaseId ,NSString * userId))completionBlock
          onError:(void (^)(NSError* error))onError;
@end
