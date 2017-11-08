//
//  SharedInstanceManager.h
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedInstanceManager : NSObject
+ (SharedInstanceManager*)sharedInstance;
@property (nonatomic, strong) NSMutableDictionary * firebaseSharedInstance;
@property (nonatomic, strong) NSMutableDictionary * imapSharedSessions;
@property (nonatomic, strong) NSMutableDictionary * imapSyncSessions;
@property (nonatomic, strong) NSMutableDictionary * sharedEmailListners;
@property (nonatomic, assign) BOOL isEmailDetailOpened;
@end
