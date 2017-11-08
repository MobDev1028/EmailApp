//
//  SyncManager.h
//  SimpleEmail
//
//  Created by Zahid on 16/12/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncManager : NSObject
-(void)syncEmailForFolder:(NSString *)folder;
@property (nonatomic, assign) BOOL invalidateTimer;
@property (nonatomic, strong) NSMutableDictionary * dictionaryToDelete;
@property (nonatomic, strong) NSString * folder;
@end
