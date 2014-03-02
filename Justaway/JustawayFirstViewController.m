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


@end
