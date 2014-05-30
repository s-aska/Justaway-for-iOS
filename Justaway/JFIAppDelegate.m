#import "JFISecret.h"
#import "JFIAccount.h"
#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "STHTTPRequest+STTwitter.h"
#import <SSKeychain/SSKeychain.h>
#import "Reachability.h"

@interface JFIAppDelegate ()

@property (nonatomic) STHTTPRequest *streamingRequest;
@property (nonatomic) Reachability *reachability;
@end

@implementation JFIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.streamingStatus = StreamingDisconnected;
    self.streamingMode = YES;
    self.currentAccountIndex = 0;
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // アカウント情報をKeyChainから読み込み
    [self loadAccounts];
    
    // ネットワーク接続状況の監視
    self.reachability = [Reachability reachabilityWithHostName:@"api.twitter.com"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifiedNetworkStatus:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self.reachability startNotifier];
    
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
    
    self.currentAccountIndex = [self.accounts count] - 1;
    
    if (self.streamingMode) {
        [self restartStreaming];
    }
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
    return [self getTwitterByIndex:self.currentAccountIndex];
}

- (STTwitterAPI *)getTwitterByIndex:(NSInteger)index
{
    JFIAccount *account = [self.accounts objectAtIndex:index];
    
    return [STTwitterAPI twitterAPIWithOAuthConsumerKey:JFITwitterConsumerKey
                                         consumerSecret:JFITwitterConsumerSecret
                                             oauthToken:account.oAuthToken
                                       oauthTokenSecret:account.oAuthTokenSecret];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if (self.streamingMode) {
        if (self.streamingStatus == StreamingDisconnecting || self.streamingStatus == StreamingDisconnected) {
            Reachability* currentReachability = [Reachability reachabilityForInternetConnection];
            NetworkStatus setworkStatus = [currentReachability currentReachabilityStatus];
            if (setworkStatus != NotReachable) {
                [self startStreaming];
            }
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
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


#pragma mark - Streaming

- (void)notifiedNetworkStatus:(NSNotification *)notification
{
    NetworkStatus networkStatus = [self.reachability currentReachabilityStatus];
    if (networkStatus != ReachableViaWiFi &&
        networkStatus != ReachableViaWWAN) {
        NSLog(@"[JFIAppDelegate] notifiedNetworkStatus disconnected.");
        return;
    }
    NSLog(@"[JFIAppDelegate] notifiedNetworkStatus connected.");
    if (self.streamingMode) {
        [self startStreaming];
    }
}

#pragma mark - Streaming

- (BOOL)enableStreaming
{
    return NO;
}

- (void)startStreaming
{
    NSLog(@"[JFIAppDelegate] startStreaming");
    if (self.streamingStatus == StreamingConnecting ||
        self.streamingStatus == StreamingConnected) {
        NSLog(@"[JFIAppDelegate] streaming is connected or connecting.");
        return;
    }
    if ([self.accounts count] == 0) {
        return;
    }
    
    self.streamingStatus = StreamingConnecting;
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIStreamingConnectionNotification
                                                        object:self
                                                      userInfo:nil];
    
    UIApplication *app = [UIApplication sharedApplication];
    self.backgroundTaskIdentifier = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    
    STTwitterAPI *twitter = [self getTwitter];
    self.streamingRequest = [twitter getUserStreamDelimited:nil
                                              stallWarnings:nil
                        includeMessagesFromFollowedAccounts:nil
                                             includeReplies:nil
                                            keywordsToTrack:nil
                                      locationBoundingBoxes:nil
                                              progressBlock:^(id response) {
                                                  if (self.streamingStatus != StreamingConnected) {
                                                      NSLog(@"[JFIAppDelegate] connect streaming");
                                                      self.streamingStatus = StreamingConnected;
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIStreamingConnectionNotification
                                                                                                          object:self
                                                                                                        userInfo:nil];
                                                  }
                                                  if ([response valueForKey:@"text"]) {
                                                      if ([response valueForKey:@"text"] == nil) {
                                                          return;
                                                      }
                                                      JFIEntity *tweet = [[JFIEntity alloc] initWithStatus:response];
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveStatusNotification
                                                                                                          object:self
                                                                                                        userInfo:@{@"tweet": tweet}];
                                                      
                                                  }
                                              } stallWarningBlock:nil
                                                 errorBlock:^(NSError *error) {
                                                     // 自分で止めた時 ... Connection was cancelled.
                                                     // 機内モード ... The network connection was lost.
                                                     // ネットワークエラー ... The network connection was lost.
                                                     NSLog(@"[JFIAppDelegate] disconnect streaming [code:%i] %@", [error code], [error localizedDescription]);
                                                     self.streamingStatus = StreamingDisconnected;
                                                     [[NSNotificationCenter defaultCenter] postNotificationName:JFIStreamingConnectionNotification
                                                                                                         object:self
                                                                                                       userInfo:nil];
                                                 }];
}

- (void)stopStreaming
{
    if (self.streamingStatus == StreamingDisconnecting ||
        self.streamingStatus == StreamingDisconnected) {
        NSLog(@"[JFIAppDelegate] streaming is disconnected or disconnecting.");
        return;
    }
    
    self.streamingStatus = StreamingDisconnecting;
    [self.streamingRequest cancel];
    
    UIApplication *app = [UIApplication sharedApplication];
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    NSLog(@"[JFIAppDelegate] stopStreaming");
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIStreamingConnectionNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)restartStreaming
{
    [self stopStreaming];
    [self performSelector:@selector(startStreaming) withObject:nil afterDelay:2.f];
}

@end
