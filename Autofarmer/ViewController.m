//
//  ViewController.m
//  Autofarmer
//
//  Created by vuquangnam on 5/18/20.
//  Copyright © 2020 vuquangnam. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSArray *devices;
}
@property (weak, nonatomic) IBOutlet UILabel *AppSelectBox;
@property (weak, nonatomic) IBOutlet UIPickerView *pickApp;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    devices = @[@"Facebook",@"Instagram",@"Twitter",@"Youtube"];
    self.pickApp.dataSource = self;
    self.pickApp.delegate = self;
    self.pickApp.hidden = YES;
    
    
    UITapGestureRecognizer *tapAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lblClick:)];
    tapAction.delegate = self;
    tapAction.numberOfTapsRequired = 1;

    //Enable the lable UserIntraction
    _AppSelectBox.userInteractionEnabled = YES;
    [_AppSelectBox addGestureRecognizer:tapAction];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    
}
- (IBAction)btnAction:(id)sender {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/355356557838717"]];
    }
}

- (void)dismissKeyboard
{
    self.btnStart.hidden = NO;
    self.pickApp.hidden = YES;

}
- (void)lblClick:(UITapGestureRecognizer *)tapGesture {
    self.btnStart.hidden = YES;
    self.pickApp.hidden = NO;

}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return devices.count;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return devices[row];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.AppSelectBox.text = devices[row];
}
@end
