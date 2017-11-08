//
//  CustomizeSnoozesViewController.m
//  SimpleEmail
//
//  Created by Zahid on 22/07/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "CustomizeSnoozesViewController.h"
#import "CustomizeSnoozesTableViewCell.h"
#import "DefaultOptionTableViewCell.h"
#import "CoreDataManager.h"
#import "Utilities.h"
#import "Constants.h"
#import "DatePickerView.h"
#import "SnoozePreferenceManager.h"

@interface CustomizeSnoozesViewController ()

@end

@implementation CustomizeSnoozesViewController {
    //NSArray * snoozeDays;
    //NSArray * snoozeTimes;
    NSString * userId;
    NSString * currentEmail;
    NSMutableArray * array;
    NSIndexPath * selectedIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchPreferences) name:kNSNOTIFICATIONCENTER_SNOOZE_PREFERENCE object:nil];
    
    userId = [Utilities getUserDefaultWithValueForKey:kSELECTED_ACCOUNT];
    NSMutableArray * userArray = [CoreDataManager fetchUserDataForId:[userId longLongValue]];
    NSManagedObject * object = [userArray lastObject];
    
    currentEmail = [object valueForKey:kUSER_EMAIL];
    [self fetchPreferences];
    
    
    UIBarButtonItem * btnBack=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"btn_cross"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(btnBackAction:)];
    
    
    
    self.navigationItem.leftBarButtonItem = btnBack;
    self.title = @"Customize Snoozes";
    [self.customizeSnoozeTableView setBackgroundView:nil];
    [self.customizeSnoozeTableView setBackgroundColor:[UIColor clearColor]];
}
-(void)fetchPreferences {
    int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
    BOOL isDeafult = NO;
    if (value == 1) {
        isDeafult = YES;
    }
    array = [CoreDataManager fetchSnoozePreferencesForBool:isDeafult emailId:[Utilities encodeToBase64:currentEmail]];
    [self.customizeSnoozeTableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return array.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row <array.count) {
        
        
        static NSString *tableIdentifier = @"CustomizeSnoozesCell";
        
        CustomizeSnoozesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        
        if (cell == nil) {
            NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"CustomizeSnoozesTableViewCell" owner:self options:nil];
            cell      = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        NSManagedObject * object = [array objectAtIndex:indexPath.row];
        cell.lblSnoozeTitle.text = [object valueForKey:kSNOOZE_TITLE];
        cell.lblSnoozeTime.text = [NSString stringWithFormat:@"%@",[object valueForKey:kTIME_STRING]];
        [cell.btnSlection addTarget:self action:@selector(btnSlectionAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnSlection setSelected:[[object valueForKey:kIS_PREFERENCE_ACTIVE] boolValue]];
        cell.btnSlection.tag = indexPath.row;
        return  cell;
    }
    else {
        static NSString *tableIdentifier = @"DefaultOptionsCell";
        
        DefaultOptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
        
        if (cell == nil) {
            NSArray *nib    = [[NSBundle mainBundle] loadNibNamed:@"DefaultOptionTableViewCell" owner:self options:nil];
            cell      = [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        int value = [[Utilities getUserDefaultWithValueForKey:kUSE_DEFAULT] intValue];
        if (value == 1) {
            [cell.btnSwitch setOn:YES];
        }
        else {
            [cell.btnSwitch setOn:NO];
        }
        [cell.btnSwitch addTarget:self action:@selector(setState:) forControlEvents:UIControlEventValueChanged];
        return  cell;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row <array.count) {
        return 44.5f;
    }
    else {
        return 64.5f;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject * object = [array objectAtIndex:selectedIndexPath.row];
    NSString * firebaseId = [object valueForKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
    if (![Utilities isValidString:firebaseId]) {
        return;
    }
    
    
    if (indexPath.row == 7 || indexPath.row == 8) {
        CustomizeSnoozesTableViewCell *cell = (CustomizeSnoozesTableViewCell *)[self.customizeSnoozeTableView cellForRowAtIndexPath:indexPath];
        [self btnSlectionAction:cell.btnSlection];
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
    //    if (index>1) {
    //        [datePickerView setDatePickerMode:UIDatePickerModeDateAndTime ];
    //    }
    //    else {
    //        [datePickerView setDatePickerMode:UIDatePickerModeTime];
    //    }
    //    if (index == 1) {
    //        datePickerView.needToIncrementDay = YES;
    //        [datePickerView setDatePickerMinimumDate:nil];
    //    }
    //    else {
    //        datePickerView.needToIncrementDay = NO;
    //        [datePickerView setDatePickerMinimumDate:[NSDate date]];
    //    }
    [self.view addSubview:datePickerView];
    datePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [Utilities setLayoutConstarintsForView:datePickerView forParent:self.view topValue:0.0f];
}


#pragma - mark User Actions
- (void)setState:(id)sender
{
    BOOL state = [sender isOn];
    if (state) {
//        for (NSManagedObject *object in array) {
//            [CoreDataManager deleteObject:object];
//        }
        [Utilities setUserDefaultWithValue:@"1" kUSE_DEFAULT andKey:kUSE_DEFAULT ];
    }
    else {
        [Utilities setUserDefaultWithValue:@"0" kUSE_DEFAULT andKey:kUSE_DEFAULT ];
    }
    [self fetchPreferences];
}
-(IBAction)btnBackAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
-(IBAction)btnSlectionAction:(id)sender {
    UIButton * btn = (UIButton *)sender;
    NSManagedObject * object = [array objectAtIndex:btn.tag];
    NSString * firebaseId = [object valueForKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
    if (![Utilities isValidString:firebaseId]) {
        return;
    }
    
    if (btn.selected) {
        [btn setSelected:NO];
        [object setValue:[NSNumber numberWithBool:NO] forKey:kIS_PREFERENCE_ACTIVE];
    }
    else {
        [object setValue:[NSNumber numberWithBool:YES] forKey:kIS_PREFERENCE_ACTIVE];
        [btn setSelected:YES];
    }
    [CoreDataManager updateData];
    if ([Utilities isValidString:firebaseId]) {
        [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SnoozePreferenceManager class] userId:userId performAction:kActionEdit firebaseId:firebaseId];
    }
}

#pragma - mark DatePickerViewDelegate
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date {
    if (selectedIndexPath != nil) {
        NSManagedObject * object = [array objectAtIndex:selectedIndexPath.row];
        NSString * firebaseId = [object valueForKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
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
        [object setValue:[NSNumber numberWithInt:minutes] forKey:kSNOOZE_MINUTE_COUNT];
        [object setValue:[NSNumber numberWithInt:hours] forKey:kSNOOZE_HOUR_COUNT];
        [object setValue:period forKey:kSNOOZE_TIME_PERIOD];
        [object setValue:dateString forKey:kTIME_STRING];
        [CoreDataManager updateData];
        
        if ([Utilities isValidString:firebaseId]) {
            [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SnoozePreferenceManager class] userId:userId performAction:kActionEdit firebaseId:firebaseId];
        }
        
        [array removeAllObjects];
        [self fetchPreferences];
    }
}
-(NSMutableDictionary *)getDictionaryForObject:(NSManagedObject *)object {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[object valueForKey:kSNOOZE_MINUTE_COUNT] forKey:kSNOOZE_MINUTE_COUNT];
    [dictionary setObject:[object valueForKey:kSNOOZE_HOUR_COUNT] forKey:kSNOOZE_HOUR_COUNT];
    [dictionary setObject:[object valueForKey:kSNOOZE_TIME_PERIOD] forKey:kSNOOZE_TIME_PERIOD];
    [dictionary setObject:[object valueForKey:kUSER_EMAIL] forKey:kUSER_EMAIL];
    [dictionary setObject:[object valueForKey:kTIME_STRING] forKey:kTIME_STRING];
    
    [dictionary setObject:[object valueForKey:kIMAGE] forKey:kIMAGE];
    [dictionary setObject:[object valueForKey:kPREFERENCE_ID] forKey:kPREFERENCE_ID];
    [dictionary setObject:[NSNumber numberWithBool:[[object valueForKey:kSNOOZE_IS_DEFAULT] boolValue]] forKey:kSNOOZE_IS_DEFAULT];
    
    [dictionary setObject:[NSNumber numberWithBool:[[object valueForKey:kIS_PREFERENCE_ACTIVE] boolValue]] forKey:kIS_PREFERENCE_ACTIVE];
    [dictionary setObject:[object valueForKey:kSNOOZE_TITLE] forKey:kSNOOZE_TITLE];
    [dictionary setObject:[NSNumber numberWithInt:1] forKey:kSNOOZE_DATE];
    return dictionary;
}
- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour {
    NSManagedObject * object = [array objectAtIndex:selectedIndexPath.row];
    NSString * strHour = @"Hours";
    if (hour == 1) {
        strHour = @"Hour";
    }
    [object setValue:[NSString stringWithFormat:@"+%d %@",hour,strHour] forKey:kTIME_STRING];
    [object setValue:[NSNumber numberWithInt:hour] forKey:kSNOOZE_HOUR_COUNT];
    [CoreDataManager updateData];
    NSString * firebaseId = [object valueForKey:kSNOOZE_PREFERENCE_FIREBASE_ID];
    if ([Utilities isValidString:firebaseId]) {
        [Utilities syncToFirebase:[self getDictionaryForObject:object] syncType:[SnoozePreferenceManager class] userId:userId performAction:kActionEdit firebaseId:firebaseId];
    }
    [array removeAllObjects];
    [self fetchPreferences];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNSNOTIFICATIONCENTER_SNOOZE_PREFERENCE
                                                  object:nil];
    NSLog(@"dealloc : RegularInboxViewController");
}
@end
