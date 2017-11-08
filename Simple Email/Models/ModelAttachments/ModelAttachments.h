//
//  ModelAttachments.h
//  SimpleEmail
//
//  Created by Zahid on 06/02/2017.
//  Copyright © 2017 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelAttachments : NSObject
@property (nonatomic, assign) long userId;
@property (nonatomic, assign) uint64_t emailId;
@property (nonatomic, assign) uint64_t emailUniqueId;
@property (nonatomic, assign) uint64_t emailThreadiD;
@property (nonatomic, assign) NSMutableArray * attachments;
-(id)initWithAttachments:(NSMutableArray *)attachments userId:(long)userId emailUniqueId:(uint64_t)emailUniqueId;
@end
