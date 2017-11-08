//
//  SharedInstanceManager.m
//  SimpleEmail
//
//  Created by Zahid on 29/09/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "SharedInstanceManager.h"

@implementation SharedInstanceManager
+ (SharedInstanceManager*)sharedInstance {
    static SharedInstanceManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}
-(id)init {
    self = [super init];
    if (self != nil) {
        self.firebaseSharedInstance = [[NSMutableDictionary alloc] init];
        self.imapSharedSessions = [[NSMutableDictionary alloc] init];
        self.imapSyncSessions = [[NSMutableDictionary alloc] init];
        self.sharedEmailListners = [[NSMutableDictionary alloc] init];
    }
    return self;
}
@end
