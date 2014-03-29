#import "JFISecret.h"
#import "JFIConstants.h"
#import "JFIAccount.h"
#import "JFIAppDelegate.h"
#import <SSKeychain/SSKeychain.h>

@implementation JFIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // アカウント情報をKeyChainから読み込み
    [self loadAccounts];
    
    return YES;
}

- (void)loadAccounts
{
    // KeyChainから全アカウント情報を取得
    NSArray *dictionaries = [SSKeychain accountsForService:JFIAccessTokenService];
    
    NSLog(@"[JFIAppDelegate] loadAccounts accounts:%lu", (unsigned long)[dictionaries count]);
    
    // アカウントリスト初期化
    self.accounts = [@[] mutableCopy];
    
    // KeyChain上のアカウント情報はJSONでシリアライズしているので、これをデシリアライズする
    for (NSDictionary *dictionary in dictionaries) {
        
        NSLog(@"-- account: %@", [dictionary objectForKey:@"acct"]);
        
        // KeyChain => NSString
        NSString *jsonString = [SSKeychain passwordForService:JFIAccessTokenService
                                                      account:[dictionary objectForKey:@"acct"]
                                                        error:nil];
        
        JFIAccount *account = [[JFIAccount alloc] initWithJsonString:jsonString];
        
        // 最後にpush
        [self.accounts addObject:account];
    }
    
    // 通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAccounts"
                                                        object:self
                                                      userInfo:nil];
}

- (void)saveAccount:(JFIAccount *)account
{
    [SSKeychain setPassword:[account jsonStringRepresentation]
                 forService:JFIAccessTokenService
                    account:account.screenName
                      error:nil];
    
    [self loadAccounts];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveAccessTokenNotification
                                                        object:self
                                                      userInfo:[account dictionaryRepresentation]];
}

- (void)clearAccounts
{
    NSArray *dictionaries = [SSKeychain accountsForService:JFIAccessTokenService];
    for (NSDictionary *dictionary in dictionaries) {
        [SSKeychain deletePasswordForService:JFIAccessTokenService account:[dictionary objectForKey:@"acct"]];
    }
    self.accounts = [@[] mutableCopy];
}

- (void)postTokenRequest
{
    self.loginTwitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:JFITwitterConsumerKey
                                                      consumerSecret:JFITwitterConsumerSecret];
    
    [self.loginTwitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
        [[UIApplication sharedApplication] openURL:url];
    }
                             forceLogin:@(YES)
                             screenName:nil
                          oauthCallback:@"justaway://twitter_access_tokens/"
                             errorBlock:^(NSError *error) {
                                 NSLog(@"-- error: %@", error);
                             }];
}

- (void)loginUsingIOSAccount
{
    [JFIAccount loginUsingIOSAccountWithSuccessBlock:^(JFIAccount *account) {
        [self saveAccount:account];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error:%@", [error localizedDescription]);
    }];
}

- (STTwitterAPI *)getTwitter
{
    NSInteger index = 0;
    return [self getTwitterByIndex:&index];
}

- (STTwitterAPI *)getTwitterByIndex:(NSInteger *)index
{
    JFIAccount *account = [self.accounts objectAtIndex:*index];
    
    return [STTwitterAPI twitterAPIWithOAuthConsumerKey:JFITwitterConsumerKey
                                         consumerSecret:JFITwitterConsumerSecret
                                             oauthToken:account.oAuthToken
                                       oauthTokenSecret:account.oAuthTokenSecret];
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
    
    // callback_urlから必要なパラメーター取得
    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];
    
    // AccessToken取得
    void(^errorBlock)(NSError *) = ^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    };
    void(^accessTokenSuccessBlock)(NSString *, NSString *, NSString *, NSString *) =
    ^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        [self.loginTwitter getUsersShowForUserID:userID
                                    orScreenName:nil
                                 includeEntities:nil
                                    successBlock:^(NSDictionary *user) {
                                        
                                        NSDictionary *directory = @{JFIAccountUserIDKey          : userID,
                                                                    JFIAccountScreenNameKey      : screenName,
                                                                    JFIAccountDisplayNameKey     : user[@"name"],
                                                                    JFIAccountProfileImageURLKey : user[@"profile_image_url"],
                                                                    JFIAccountOAuthTokenKey      : oauthToken,
                                                                    JFIAccountOAuthTokenSecretKey: oauthTokenSecret};
                                        
                                        [self saveAccount:[[JFIAccount alloc] initWithDictionary:directory]];
                                    } errorBlock:errorBlock];
    };
    
    [self.loginTwitter postAccessTokenRequestWithPIN:d[@"oauth_verifier"]
                                        successBlock:accessTokenSuccessBlock
                                          errorBlock:errorBlock];
    
    return YES;
}

- (BOOL)enableStreaming
{
    return NO;
}

@end
