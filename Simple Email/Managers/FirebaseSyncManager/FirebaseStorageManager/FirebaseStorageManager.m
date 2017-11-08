//
//  FirebaseStorageManager.m
//  SimpleEmail
//
//  Created by Zahid on 07/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "FirebaseStorageManager.h"
#import "Constants.h"

@implementation FirebaseStorageManager

-(void)uploadImageData:(NSMutableDictionary*)dictionary
       completionBlock:(void (^)(FIRStorageMetadata *metaData , NSString * firebaseId ,NSString * userId))completionBlock
               onError:(void (^)(NSError* error))onError
              progress:(void (^)(FIRStorageTaskSnapshot *snapshot))progress {
    NSData * data = (NSData*)[dictionary objectForKey:@"data"];
    
    NSString * str = [dictionary objectForKey:@"path"];
    NSString * firId = [dictionary objectForKey:kFIREBASE_ID];
    NSString * uuid = [dictionary objectForKey:kUSER_ID];
    //int action = [[dictionary objectForKey:@"action"] intValue];

    // Get a reference to the storage service, using the default Firebase App
    FIRStorage *storage = [FIRStorage storage];
    
    // Create a storage reference from our storage service
    FIRStorageReference *storageRef = [storage referenceForURL:kSTORAGE_REFERENCE];
    FIRStorageReference *imgRef = [storageRef child:str];
    
    // Local file you want to upload
    //NSURL *localFile = nil;
    
    // Create the file metadata
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/jpeg";
    // Upload file and metadata to the object 'images/mountains.jpg'
    //FIRStorageUploadTask *uploadTask = [storageRef putFile:localFile metadata:metadata];
    
    FIRStorageUploadTask *uploadTask = [imgRef putData:data metadata:metadata completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error != nil) {
            // Uh-oh, an error occurred!
            onError(error);
        } else {
            // Metadata contains file metadata such as size, content-type, and download URL.
            NSURL *downloadURL = metadata.downloadURL;
            NSLog(@"uploaded image url = %@", downloadURL.description);
            completionBlock(metadata, firId, uuid);
        }
    }];
    
    // Listen for state changes, errors, and completion of the upload.
    [uploadTask observeStatus:FIRStorageTaskStatusResume handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload resumed, also fires when the upload starts
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusPause handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload paused
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload reported progress
        double percentComplete = 100.0 * (snapshot.progress.completedUnitCount) / (snapshot.progress.totalUnitCount);
        NSLog(@"progress = %f", percentComplete);
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload completed successfully
    }];
    
    // Errors only occur in the "Failure" case
    [uploadTask observeStatus:FIRStorageTaskStatusFailure handler:^(FIRStorageTaskSnapshot *snapshot) {
        if (snapshot.error != nil) {
            switch (snapshot.error.code) {
                case FIRStorageErrorCodeObjectNotFound:
                    // File doesn't exist
                    onError(snapshot.error);
                    break;
                    
                case FIRStorageErrorCodeUnauthorized:
                    // User doesn't have permission to access file
                    onError(snapshot.error);
                    break;
                    
                case FIRStorageErrorCodeCancelled:
                    // User canceled the upload
                    onError(snapshot.error);
                    break;
                    
                case FIRStorageErrorCodeUnknown:
                    // Unknown error occurred, inspect the server response
                    onError(snapshot.error);
                    break;
            }
        }
    }];
}

-(void)deleteData:(NSMutableDictionary*)dictionary
       completionBlock:(void (^)(NSString * firebaseId ,NSString * userId))completionBlock
               onError:(void (^)(NSError* error))onError {
    
    NSString * str = [dictionary objectForKey:@"path"];
    NSString * firId = [dictionary objectForKey:kFIREBASE_ID];
    NSString * uuid = [dictionary objectForKey:kUSER_ID];
    //int action = [[dictionary objectForKey:@"action"] intValue];
    
    // Get a reference to the storage service, using the default Firebase App
    FIRStorage *storage = [FIRStorage storage];
    
    // Create a storage reference from our storage service
    FIRStorageReference *storageRef = [storage referenceForURL:kSTORAGE_REFERENCE];
    FIRStorageReference *imgRef = [storageRef child:str];

    // Delete the file
    [imgRef deleteWithCompletion:^(NSError *error){
        if (error != nil) {
            onError(error);
            // Uh-oh, an error occurred!
        } else {
            completionBlock(firId, uuid);
            // File deleted successfully
        }
    }];
}
@end
