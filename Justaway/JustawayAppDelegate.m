//
//  JustawayAppDelegate.m
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JustawayAppDelegate.h"
#import "JustawayFirstViewController.h"

@implementation JustawayAppDelegate

@synthesize twitter;

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
    return YES;
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

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString {
    
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
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([[url scheme] isEqualToString:@"justaway"] == NO) return NO;
    
    // callback_urlから必要なパラメーター取得し、JustawayFirstViewControllerに投げます
    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];
    NSString *token = d[@"oauth_token"];
    NSString *verifier = d[@"oauth_verifier"];

    // TODO: postAccessTokenRequestWithPIN はここでやって Notification するように書き換える
    // http://www.objectivec-iphone.com/foundation/NSNotification/postNotificationName.html
    UITabBarController *tabbarVC = (UITabBarController *)self.window.rootViewController;
    if ([tabbarVC.selectedViewController isKindOfClass:[JustawayFirstViewController class]]) {
        JustawayFirstViewController *justawayVC = (JustawayFirstViewController *)tabbarVC.selectedViewController;
        [justawayVC setOAuthToken:token oauthVerifier:verifier];
    }
    
    return YES;
}

@end
