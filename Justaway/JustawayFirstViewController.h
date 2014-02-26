//
//  JustawayFirstViewController.h
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JustawayFirstViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) NSArray *statuses;

@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *accountsPickerView;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;

- (IBAction)loginInSafariAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
