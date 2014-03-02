//
//  JustawaySecondViewController.m
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JustawayAppDelegate.h"
#import "JustawaySecondViewController.h"

@interface JustawaySecondViewController ()

@end

@implementation JustawaySecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    
    self.accountsPickerView.delegate = self;
    
    // 背景をタップしたら、キーボードを隠す
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSoftKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    // 枠をつける
    self.statusTextField.layer.borderWidth = 1;
    self.statusTextField.layer.borderColor = [[UIColor blackColor] CGColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginInSafariAction:(id)sender
{
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    [delegate.twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
        NSLog(@"-- url: %@", url);
        NSLog(@"-- oauthToken: %@", oauthToken);
        
        [[UIApplication sharedApplication] openURL:url];
    } forceLogin:@(YES)
                            screenName:nil
                         oauthCallback:@"justaway://twitter_access_tokens/"
                            errorBlock:^(NSError *error) {
                                NSLog(@"-- error: %@", error);
                            }];
}

- (IBAction)postAction:(id)sender {
    
    NSLog(@"postAction status:%@", [_statusTextField text]);
    
    NSInteger selectedRow = [_accountsPickerView selectedRowInComponent:0];
    
    NSLog(@"postAction selectedRow:%ld", (long)selectedRow);
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&selectedRow];
    
    [twitter postStatusUpdate:[_statusTextField text]
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     // ...
                 } errorBlock:^(NSError *error) {
                     // ...
                 }];
}

- (void)receiveAccessToken:(NSNotification *)center
{
    NSString *userID = [center.userInfo objectForKey:@"userID"];
    NSString *screenName = [center.userInfo objectForKey:@"screenName"];
    
    NSLog(@"receiveAccessToken userID:%@ screenName:%@", userID, screenName);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)accountsPickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)accountsPickerView numberOfRowsInComponent :(NSInteger)component
{
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    return (unsigned long)[delegate.accounts count];
}

- (NSString *)pickerView:(UIPickerView *)accountsPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *account = [delegate.accounts objectAtIndex:row];
    return [account objectForKey:@"screenName"];
}

// キーボードを隠す処理
- (void)closeSoftKeyboard {
    [self.view endEditing:YES];
}

@end
