#import "JFIAppDelegate.h"
#import "JFIFirstViewController.h"
#import "JFISecret.h"
#import <SSKeychain/SSKeychain.h>

@implementation JFIAppDelegate

static NSString * const JFI_SERVICE = @"JustawayService";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // アカウント情報をKeyChainから読み込み
    [self loadAccounts];
    
    return YES;
}

- (void)loadAccounts
{
    // KeyChainから全アカウント情報を取得
    NSArray *dictionaries = [SSKeychain accountsForService:JFI_SERVICE];
    
    NSLog(@"[JFIAppDelegate] dictionaries: %lu", (unsigned long)[dictionaries count]);
    
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
        NSLog(@"-- profileImageUrl: %@", [account objectForKey:@"profileImageUrl"]);
        NSLog(@"-- oauthToken: %@", [account objectForKey:@"oauthToken"]);
        NSLog(@"-- oauthTokenSecret: %@", [account objectForKey:@"oauthTokenSecret"]);
    }
    
    // 通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAccounts"
                                                        object:self
                                                      userInfo:nil];
}

- (void)clearAccounts
{
    NSArray *dictionaries = [SSKeychain accountsForService:JFI_SERVICE];
    for (NSDictionary *dictionary in dictionaries) {
        [SSKeychain deletePasswordForService:JFI_SERVICE account:[dictionary objectForKey:@"acct"]];
    }
    self.accounts = [@[] mutableCopy];
}

- (void)postTokenRequest
{
    _loginTwitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:JFI_ConsumerKey
                                                  consumerSecret:JFI_ConsumerSecret];
    
    [_loginTwitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
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

- (STTwitterAPI *)getTwitter
{
    NSInteger index = 0;
    return [self getTwitterByIndex:&index];
}

- (STTwitterAPI *)getTwitterByIndex:(NSInteger *)index
{
    NSDictionary *account = [self.accounts objectAtIndex:*index];
    
    return [STTwitterAPI twitterAPIWithOAuthConsumerKey:JFI_ConsumerKey
                                         consumerSecret:JFI_ConsumerSecret
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
    [_loginTwitter postAccessTokenRequestWithPIN:d[@"oauth_verifier"] successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        NSLog(@"-- screenName: %@", screenName);
        
        [_loginTwitter getUsersShowForUserID:userID orScreenName:nil includeEntities:nil successBlock:^(NSDictionary *user) {
            
            NSString *profileImageUrl = [user valueForKey:@"profile_image_url"];
            
            // アカウント情報
            NSDictionary *account = @{
                                      @"userID" : userID,
                                      @"screenName" : screenName,
                                      @"profileImageUrl" : profileImageUrl,
                                      @"oauthToken" : oauthToken,
                                      @"oauthTokenSecret" : oauthTokenSecret
                                      };
            
            // アカウント情報 => NSData
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:account
                                                               options:kNilOptions error:nil];
            
            // NSData => NSString
            NSString *jsonString= [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            // NSString => KeyChain (insert or update?)
            [SSKeychain setPassword:jsonString
                         forService:JFI_SERVICE
                            account:screenName
                              error:nil];
            
            // アカウント情報をKeyChainから再読み込み
            [self loadAccounts];
            
            // 通知先に渡すデータを生成
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      userID, @"userID",
                                      screenName, @"screenName",
                                      profileImageUrl, @"profileImageUrl", nil];
            
            // 通知する
            NSLog(@"[JFIAppDelegate.h] postNotificationName:receiveAccessToken");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveAccessToken"
                                                                object:self
                                                              userInfo:userInfo];
        } errorBlock:^(NSError *error) {
            NSLog(@"-- %@", [error localizedDescription]);
        }];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
    
    return YES;
}

- (BOOL)enableStreaming
{
    return NO;
}

@end
