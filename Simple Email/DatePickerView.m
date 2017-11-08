//
//  DatePickerView.m
//  SimpleEmail
//
//  Created by Zahid on 09/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import "DatePickerView.h"
#import "Utilities.h"

@interface DatePickerView ()

@end

@implementation DatePickerView {
    NSMutableArray * pickerData;
    int pickerValue;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (void)awakeFromNib {
    [super awakeFromNib];
}
-(void)setupViewWithTitle:(NSString *)title {
    self.lblTitle.text = title;
    if (self.showHoursPicker) {
        pickerValue = 1;
        [self.datePicker setHidden:YES];
        [self.pickerView setHidden:NO];
        // Initialize Data
        if (pickerData == nil) {
            pickerData = [[NSMutableArray alloc] init];
        }
        
        for (int i = 1; i<=24; i++) {
            NSString * hour = @"Hours";
            if (i == 1) {
                hour = @"Hour";
            }
            [pickerData addObject:[NSString stringWithFormat:@"+%d %@",i ,hour]];
        }
        // Connect data
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
    }
    else {
        [self.datePicker setHidden:NO];
        [self.pickerView setHidden:YES];
        [self.datePicker addTarget:self action:@selector(dateDidChange:) forControlEvents:UIControlEventValueChanged];
        self.datePicker.timeZone = [NSTimeZone localTimeZone];
    }
}
#pragma - mark Private Methods
-(void)setDatePickerMode:(UIDatePickerMode)datePickerMode {
    self.datePicker.datePickerMode = datePickerMode;
}
-(void)setDatePickerMinimumDate:(NSDate *)date {
    self.datePicker.minimumDate = date;
}
#pragma - mark User Actions
-(IBAction)btnCancelAction:(id)sender {
    [self removeFromSuperview];
}

-(IBAction)btnDoneAction:(id)sender {
    if (self.showHoursPicker) {
        [self.delegate datePickerView:self didSelectHour:pickerValue];
    }
    else {
        NSDate * pickedDate = self.datePicker.date;
        //    if (self.needToIncrementDay) { // add one day
        //        pickedDate = [pickedDate dateByAddingTimeInterval:60*60*24*1];
        //    }
        if (![Utilities isDateInFuture:pickedDate]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:@"Please select date/time in future."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        [self.delegate datePickerView:self didSelectDate:pickedDate];
    }
    [self removeFromSuperview];
}
-(void)dateDidChange:(id)picker {
    NSLog(@"picker date = %@", self.datePicker.date);
}

#pragma - mark UIPickerViewDataSource
// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return pickerData.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return pickerData[row];
}
#pragma - mark UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    pickerValue = (int)row+1;
}
-(void)dealloc {
    NSLog(@"dealloc : DatePickerView");
}
@end
