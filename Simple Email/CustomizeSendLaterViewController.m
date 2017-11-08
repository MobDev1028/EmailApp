//
//  CustomizeSendLaterViewController.m
//  SimpleEmail
//
//  Created by Zahid on 22/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "CustomizeSendLaterViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "CustomizeSendLaterTableViewCell.h"
#import "DefaultOptionTableViewCell.h"
#import "CoreDataManager.h"
#import "Utilities.h"
#import "Constants.h"
#import "SendLaterSyncManager.h"
#import "DatePickerView.h"

@interface CustomizeSendLaterViewController ()

@end

@implementation CustomizeSendLaterViewController {
    NSMutableArray * sendLaterData;
    NSString * userId;
    NSString *  currentEmail;
    NSIndexPath * selectedIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:kNSNOTIFICATIONCENTER_SEND_LATER object:nil];
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    
    currentEmail = [object valueForKey:kUSER_EMAIL];
    
    sendLaterData = [[NSMutableArray alloc] init];
    
    [self refreshTableView];
    [self setUpView];
}
#pragma - mark Private Methods
-(void)setUpView {
//    sendLaterData = [[NSArray alloc] initWithObjects:@"In 1 Hour",@"In 2 Hours",@"In 4 Hours", @"Tomorrow Morning", @"Tomorrow Afternon", @"Next Week", @"In a Month", @"Someday", @"", nil];
    [self.navigationController.navigationBar setHidden:NO];
    [self.customizeSendLaterTableView setBackgroundView:nil];
    [self.customizeSendLaterTableView setBackgroundColor:[UIColor clearColor]];
    self.customizeSendLaterTableView.allowsSelectionDuringEditing = YES;
    
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
    if (value == 1) {
        [self.customizeSendLaterTableView setEditing:NO];
    }
    else {
        [self.customizeSendLaterTableView setEditing:YES];
    }
    
    self.title = @"Customize Send Later";
    
    UIBarButtonItem * btncross = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(btnCrossAction:)];
    self.navigationItem.leftBarButtonItem = btncross;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] customizeNavigationBar:self.navigationController];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

-(void)refreshTableView {
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
    BOOL isDeafult = NO;
    if (value == 1) {
        isDeafult = YES;
    }
    sendLaterData = [CoreDataManager fetchSendlaterPreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
    [self.customizeSendLaterTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return sendLaterData.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < sendLaterData.count) {
        static NSString *tableIdentifier = @"CustomizeSendLaterCell";
        CustomizeSendLaterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomizeSendLaterTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
//        if (indexPath.row == sendLaterData.count) {
//            cell.viewAddMoreButton.hidden = NO;
//            cell.viewSendLaterLabel.hidden = YES;
//        }
//        else {
            
            NSManagedObject * object = [sendLaterData objectAtIndex:indexPath.row];
            
            NSLog(@"FIrebase ID %@", [object valueForKey:kSEND_PREFERENCES_FIREBASEID]);
            
            cell.lblSendLater.text = [object valueForKey:kSEND_LATER_TITLE];
            cell.lblSendTime.text = [NSString stringWithFormat:@"%@",[object valueForKey:kTIME_STRING]];
            cell.delegate = self;
            cell.allowsOppositeSwipe = NO;
            cell.allowsMultipleSwipe = YES;
            cell.viewAddMoreButton.hidden = YES;
            cell.viewSendLaterLabel.hidden = NO;
//        }
        return  cell;
    }
    else {
        static NSString *tableIdentifier = @"DefaultOptionsCell";
        DefaultOptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DefaultOptionTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
        if (value == 1) {
            [cell.btnSwitch setOn:YES];
        }
        else {
            [cell.btnSwitch setOn:NO];
        }
        [cell.btnSwitch addTarget:self action:@selector(setState:) forControlEvents:UIControlEventValueChanged];
        return  cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.5f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject * object = [sendLaterData objectAtIndex:selectedIndexPath.row];
    NSString * firebaseId = [object valueForKey:kSEND_PREFERENCES_FIREBASEID];
    if (![Utilities isValidString:firebaseId]) {
        return;
    }
    
    if (indexPath.row == [sendLaterData count] - 1) {
        return;
    }
    
    selectedIndexPath = indexPath;
    
    DatePickerView * datePickerView = [[[NSBundle mainBundle] loadNibNamed:@"DatePickerView" owner:self options:nil] objectAtIndex:0];
    
    datePickerView.delegate = self;
    
    if (indexPath.row == 0) {
        datePickerView.showHoursPicker = YES;
        [datePickerView setupViewWithTitle:@"Pick Hours"];
    }
    else  {
        datePickerView.showHoursPicker = NO;
        [datePickerView setupViewWithTitle:@"Pick Time"];
        [datePickerView setDatePickerMode:UIDatePickerModeTime];
    }
    [self.view addSubview:datePickerView];
    datePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:datePickerView forParent:self.view topValue:0.0f];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
    
    if (value == 1) {
        return NO;
    }
    if (indexPath.row < sendLaterData.count) {
        return YES;
    }
    return NO;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_SENDLATER_DEFAULT] intValue];
    
    if (value == 1) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject * object = [sendLaterData objectAtIndex:indexPath.row];
    [object setValue:[NSNumber numberWithBool:NO] forKey:kSNOOZE_IS_DEFAULT];
    NSString * firebaseId = [object valueForKey:kSEND_PREFERENCES_FIREBASEID];
    [CoreDataManager updateData];
    if ([Utilities isValidString:firebaseId]) {
        [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SendLaterSyncManager class] userId:userId performAction:kActionDelete firebaseId:firebaseId];
    }
}

-(NSMutableDictionary *)getDictionaryForObject:(NSManagedObject *)object {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[object valueForKey:kSEND_MINUTE_COUNT] forKey:kSEND_MINUTE_COUNT];
    [dictionary setObject:[object valueForKey:kSEND_HOUR_COUNT] forKey:kSEND_HOUR_COUNT];
    [dictionary setObject:[object valueForKey:kPREFERENCE_ID] forKey:kPREFERENCE_ID];
    [dictionary setObject:[object valueForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
    [dictionary setObject:[object valueForKey:kSEND_LATER_TITLE] forKey:kSEND_LATER_TITLE];
    
    [dictionary setObject:[object valueForKey:kSNOOZE_TIME_PERIOD] forKey:kSNOOZE_TIME_PERIOD];
    [dictionary setObject:[object valueForKey:kTIME_STRING] forKey:kTIME_STRING];
    [dictionary setObject:[NSNumber numberWithBool:[[object valueForKey:kSNOOZE_IS_DEFAULT] boolValue]] forKey:kSNOOZE_IS_DEFAULT];
    
    [dictionary setObject:[NSNumber numberWithBool:[[object valueForKey:kIS_PREFERENCE_ACTIVE] boolValue]] forKey:kIS_PREFERENCE_ACTIVE];
    [dictionary setObject:[NSNumber numberWithInt:1] forKey:kSEND_DATE];
    return dictionary;
}

#pragma - mark User Actions
- (void)setState:(id)sender
{
    BOOL state = [sender isOn];
    if (state) {
        [Utilities setUserDefaultWithValue:@"1" kUSE_SENDLATER_DEFAULT andKey:kUSE_SENDLATER_DEFAULT ];
        
        self.customizeSendLaterTableView.editing = NO;
        
        [self refreshTableView];
        
//        for (NSManagedObject *object in sendLaterData) {
//            [CoreDataManager deleteObject:object];
//        }
        
//        [self refreshTableView];
    }
    else {
        [Utilities setUserDefaultWithValue:@"0" kUSE_SENDLATER_DEFAULT andKey:kUSE_SENDLATER_DEFAULT ];
        
        self.customizeSendLaterTableView.editing = YES;
        
        [self refreshTableView];
    }
}

-(IBAction)btnCrossAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma - mark DatePickerViewDelegate
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    if (selectedIndexPath != nil) {
        NSManagedObject * object = [sendLaterData objectAtIndex:selectedIndexPath.row];
        NSString * firebaseId = [object valueForKey:kSEND_PREFERENCES_FIREBASEID];
        if (![Utilities isValidString:firebaseId]) {
            return;
        }
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"H-m-a"];
        NSString *stringDate = [df stringFromDate:date];
        int hours = [[[stringDate componentsSeparatedByString:@"-"] objectAtIndex:0] intValue];
        int minutes = [[[stringDate componentsSeparatedByString:@"-"] objectAtIndex:1] intValue];
        NSString * period = [[stringDate componentsSeparatedByString:@"-"] objectAtIndex:2];
        
        NSString * dateString = nil;
        if (selectedIndexPath.row == 4 || selectedIndexPath.row == 5) {
            [df setDateFormat:@"h:mm a"];
            NSString *stringDate1 = [df stringFromDate:date];
            if (selectedIndexPath.row == 4) {
                dateString = [NSString stringWithFormat:@"Sun, %@",stringDate1];
            }
            else {
                dateString = [NSString stringWithFormat:@"Mon, %@",stringDate1];
            }
        }
        else {
            [df setDateFormat:@"h:mm a"];
            dateString = [df stringFromDate:date];
        }
        [object setValue:[NSNumber numberWithInt:minutes] forKey:kSEND_MINUTE_COUNT];
        [object setValue:[NSNumber numberWithInt:hours] forKey:kSEND_HOUR_COUNT];
        [object setValue:period forKey:kSNOOZE_TIME_PERIOD];
        [object setValue:dateString forKey:kTIME_STRING];
        [CoreDataManager updateData];
        
        if ([Utilities isValidString:firebaseId]) {
            [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SendLaterSyncManager class] userId:userId performAction:kActionEdit firebaseId:firebaseId];
        }
        
        [sendLaterData removeAllObjects];
        [self refreshTableView];
    }
}

- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
    NSManagedObject * object = [sendLaterData objectAtIndex:selectedIndexPath.row];
    NSString * strHour = @"Hours";
    if (hour == 1) {
        strHour = @"Hour";
    }
    [object setValue:[NSString stringWithFormat:@"+%d %@",hour,strHour] forKey:kTIME_STRING];
    [object setValue:[NSNumber numberWithInt:hour] forKey:kSEND_HOUR_COUNT];
    [CoreDataManager updateData];
    NSString * firebaseId = [object valueForKey:kSEND_PREFERENCES_FIREBASEID];
    if ([Utilities isValidString:firebaseId]) {
        [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SendLaterSyncManager class] userId:userId performAction:kActionEdit firebaseId:firebaseId];
    }
    [sendLaterData removeAllObjects];
    [self refreshTableView];
}

-(void)dealloc {
    NSLog(@"dealloc - CustomizeSendLaterViewController");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
