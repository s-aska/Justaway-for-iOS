#import "JFISecret.h"
#import "JFIAccount.h"
#import "JFIAppDelegate.h"
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
        
        JFIAccount *account_ = [[JFIAccount alloc] initWithJsonString:jsonString];
        
        NSDictionary *account = [account_ dictionaryRepresentation];
        
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
                 forService:JFI_SERVICE
                    account:account.screenName
                      error:nil];
    
    [self loadAccounts];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveAccessToken"
                                                        object:self
                                                      userInfo:[account dictionaryRepresentation]];
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
    void(^errorBlock)(NSError *) = ^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    };
    void(^accessTokenSuccessBlock)(NSString *, NSString *, NSString *, NSString *) =
    ^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        [_loginTwitter getUsersShowForUserID:userID
                                orScreenName:nil
                             includeEntities:nil
                                successBlock:^(NSDictionary *user) {
                                    NSDictionary *directory =@{
                                                               @"userID" : userID,
                                                               @"screenName" : screenName,
                                                               @"profileImageUrl" : [user valueForKey:@"profile_image_url"],
                                                               @"oauthToken" : oauthToken,
                                                               @"oauthTokenSecret" : oauthTokenSecret
                                                               };
                                    [self saveAccount:[[JFIAccount alloc] initWithDictionary:directory]];
                                } errorBlock:errorBlock];
    };
    [_loginTwitter postAccessTokenRequestWithPIN:d[@"oauth_verifier"]
                                    successBlock:accessTokenSuccessBlock
                                      errorBlock:errorBlock];
    
    return YES;
}

- (BOOL)enableStreaming
{
    return NO;
}

@end
