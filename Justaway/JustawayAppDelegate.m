//
//  JustawayAppDelegate.m
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JustawayAppDelegate.h"
#import "JustawayFirstViewController.h"
#import <SSKeychain/SSKeychain.h>

@implementation JustawayAppDelegate

@synthesize twitter;

static NSString * const JFI_SERVICE = @"JustawayService";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // Supporting Files/secret.plist からAPIの設定を読み込む
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* path = [bundle pathForResource:@"secret" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];

    // STTwitterAPIのインスタンスをセット
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:[dictionary objectForKey:@"consumer_key"]
                                                 consumerSecret:[dictionary objectForKey:@"consumer_secret"]];

    // KeyChainから全アカウント情報を取得
    NSArray* dictionaries = [SSKeychain accountsForService:JFI_SERVICE];
    
    NSLog(@"-- dictionaries: %lu", (unsigned long)[dictionaries count]);

    // アカウントリスト初期化
    self.accounts = [@[] mutableCopy];

    // KeyChain上のアカウント情報はJSONでシリアライズしているので、これをデシリアライズする
    for (NSDictionary *dictionary in dictionaries) {

        NSLog(@"-- account: %@", [dictionary objectForKey:@"acct"]);

        // KeyChain => NSString
        NSString *jsonString = [SSKeychain passwordForService:JFI_SERVICE
                                                      account:[dictionary objectForKey:@"acct"]
                                                        error:nil];

        // NSString => NSData
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        // NSData => NSDictionary
        NSDictionary *account = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

        // 最後にpush
        [self.accounts addObject:account];
        
        NSLog(@"-- data: %@", jsonString);
        NSLog(@"-- userID: %@", [account objectForKey:@"userID"]);
        NSLog(@"-- screenName: %@", [account objectForKey:@"screenName"]);
        NSLog(@"-- oauthToken: %@", [account objectForKey:@"oauthToken"]);
        NSLog(@"-- oauthTokenSecret: %@", [account objectForKey:@"oauthTokenSecret"]);
    }
    
    return YES;
}

- (STTwitterAPI *)getTwitterByIndex:(NSInteger *)index
{
    // Supporting Files/secret.plist からAPIの設定を読み込む
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* path = [bundle pathForResource:@"secret" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];

    NSDictionary *account = [self.accounts objectAtIndex:*index];
    
    return [STTwitterAPI twitterAPIWithOAuthConsumerKey:[dictionary objectForKey:@"consumer_key"]
                                         consumerSecret:[dictionary objectForKey:@"consumer_secret"]
                                             oauthToken:[account objectForKey:@"oauthToken"]
                                       oauthTokenSecret:[account objectForKey:@"oauthTokenSecret"]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString
{
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *s in queryComponents) {
        NSArray *pair = [s componentsSeparatedByString:@"="];
        if([pair count] != 2) continue;
        
        NSString *key = pair[0];
        NSString *value = pair[1];
        
        md[key] = value;
    }
    
    return md;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // スキーマチェック
    if ([[url scheme] isEqualToString:@"justaway"] == NO) {
        return NO;
    }
    
    // callback_urlから必要なパラメーター取得し
    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];

    // AccessToken取得
    [twitter postAccessTokenRequestWithPIN:d[@"oauth_verifier"] successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        NSLog(@"-- screenName: %@", screenName);
        
        // 通知先に渡すデータを生成
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  userID, @"userID",
                                  screenName, @"screenName", nil];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        // 通知する
        [nc postNotificationName:@"receiveAccessToken"
                          object:self
                        userInfo:userInfo];

        // アカウント情報
        NSDictionary *account = @{
                                  @"userID" : userID,
                                  @"screenName" : screenName,
                                  @"oauthToken" : oauthToken,
                                  @"oauthTokenSecret" : oauthTokenSecret
                                  };

        // アカウント情報 => NSData
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:account
                                                           options:kNilOptions error:nil];

        // NSData => NSString
        NSString *jsonString= [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        // NSString => KeyChain
        [SSKeychain setPassword:jsonString
                     forService:JFI_SERVICE
                        account:screenName
                          error:nil];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];

    return YES;
}

@end
