//
//  CellConfigureManager.h
//  SimpleEmail
//
//  Created by Zahid on 25/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmartInboxTableViewCell.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "Utilities.h"
#import "MCOIMAPFetchContentOperationManager.h"
#import <UIKit/UIKit.h>

@interface CellConfigureManager : NSObject
+(SmartInboxTableViewCell *)configureInboxCell:(SmartInboxTableViewCell *)cell withData:(NSManagedObject *)data andContentFetchManager:(MCOIMAPFetchContentOperationManager*)contentFetchManager view:(UIView*)view atIndexPath:(NSIndexPath *)indexPath isSent:(BOOL)isSent;
+(SmartInboxTableViewCell *)configureInboxCell:(SmartInboxTableViewCell *)cell withData:(NSDictionary *)data view:(UIView*)view atIndexPath:(NSIndexPath *)indexPath isSent:(BOOL)isSent;
+(void)didTapOnEmail:(NSManagedObject *)data folderType:(int)type;
@end
