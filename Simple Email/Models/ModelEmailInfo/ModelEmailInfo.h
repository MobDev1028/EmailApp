//
//  ModelEmailInfo.h
//  SimpleEmail
//
//  Created by Zahid on 28/11/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@interface ModelEmailInfo : NSObject
@property (nonatomic, assign) long       userId;
@property (nonatomic, assign) uint64_t   emailId;
@property (nonatomic, assign) uint64_t   emailUniqueId;
@property (nonatomic, assign) uint64_t   emailThreadiD;
@property (nonatomic, strong) NSDate   * emailDate;
@property (nonatomic, strong) NSString * emailFolderName;

-(id)initWithMessage:(MCOIMAPMessage *)message userId:(NSString *)uid folderName:(NSString *)folder;
@end
