//
//  DatePickerView.h
//  SimpleEmail
//
//  Created by Zahid on 09/08/2016.
//  Copyright © 2016 Maxxsol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DatePickerView;
@protocol DatePickerViewDelegate <NSObject>
- (void)datePickerView:(DatePickerView *)pickerView didSelectDate:(NSDate *)date;
- (void)datePickerView:(DatePickerView *)pickerView didSelectHour:(int)hour;
@end
@interface DatePickerView : UIView
@property (assign, nonatomic) id <DatePickerViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIDatePicker * datePicker;
@property (weak, nonatomic) IBOutlet UIPickerView * pickerView;
@property (weak, nonatomic) IBOutlet UILabel * lblTitle;
@property (assign, nonatomic) BOOL needToIncrementDay;
-(void)setDatePickerMode:(UIDatePickerMode)datePickerMode;
-(void)setDatePickerMinimumDate:(NSDate *)date;
@property (nonatomic, assign) BOOL showHoursPicker;
-(void)setupViewWithTitle:(NSString *)title;
@end
