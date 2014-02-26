//
//  JustawayFirstViewController.m
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JustawayAppDelegate.h"
#import "JustawayFirstViewController.h"

@interface JustawayFirstViewController ()

@end

@implementation JustawayFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // 通知センターにオブザーバ（通知を受け取るオブジェクト）を追加
    [nc addObserver:self
           selector:@selector(receiveAccessToken:)
               name:@"receiveAccessToken"
             object:delegate];
    
    NSLog(@"-- find accounts: %lu", (unsigned long)[delegate.accounts count]);
    
    self.accountsPickerView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finalize
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // 通知の登録を解除
    [nc removeObserver:self];
    
    [super finalize];
}

- (IBAction)loginInSafariAction:(id)sender
{

    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];

    _loginStatusLabel.text = @"Trying to login with Safari...";

    [delegate.twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
        NSLog(@"-- url: %@", url);
        NSLog(@"-- oauthToken: %@", oauthToken);
        
        [[UIApplication sharedApplication] openURL:url];
    } forceLogin:@(YES)
                    screenName:nil
                 oauthCallback:@"justaway://twitter_access_tokens/"
                    errorBlock:^(NSError *error) {
                        NSLog(@"-- error: %@", error);
                        _loginStatusLabel.text = [error localizedDescription];
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

    _loginStatusLabel.text = screenName;
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

@end
