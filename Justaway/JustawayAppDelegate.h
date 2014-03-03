//
//  JustawayAppDelegate.h
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STTwitter.h"

@interface JustawayAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) STTwitterAPI *loginTwitter; // アカウント追加（Twitter認証）専用Twitterインスタンス
@property (strong, nonatomic) NSMutableArray *accounts;

- (STTwitterAPI *)getTwitterByIndex:(NSInteger *)index;
- (void)clearAccounts;
- (void)postTokenRequest;

@end
