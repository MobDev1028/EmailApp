//
//  ModelUser.h
//  SimpleEmail
//
//  Created by Zahid on 03/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelUser : NSObject
@property (nonatomic, assign) int userId;
@property (nonatomic, strong) NSString * userName;
@property (nonatomic, strong) NSString * userEmail;
@property (nonatomic, strong) NSString * userImageUrl;
@property (nonatomic, strong) NSString * refreshToken;
@property (nonatomic, strong) NSDate   * tokenExpireDate;
@property (nonatomic, strong) NSString * userKeychainItemName;
@property (nonatomic, strong) NSString * userOAuthAccessToken;
@end
