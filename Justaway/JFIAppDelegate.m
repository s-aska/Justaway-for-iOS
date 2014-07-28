#import "JFISecret.h"
#import "JFIAccount.h"
#import "JFIEntity.h"
#import "JFITheme.h"
#import "JFIActionStatus.h"
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
    self.streamingMode = NO;
    self.currentAccountIndex = 0;
    [self setTheme];
    
    // アカウント情報をKeyChainから読み込み
    [self loadAccounts];
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:nil];
    
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

- (JFIAccount *)findAccount:(NSString *)userID
{
    for (JFIAccount *account in self.accounts) {
        if ([account.userID isEqualToString:userID]) {
            return account;
        }
    }
    return nil;
}

- (void)refreshAccounts:(void(^)())successBlock
{
    self.refreshedAccounts = YES;
    NSMutableArray *userIDs = NSMutableArray.new;
    for (JFIAccount *account in self.accounts) {
        [userIDs addObject:account.userID];
    }
    if ([userIDs count] > 0) {
        STTwitterAPI *twitter = [self getTwitter];
        [twitter getUsersLookupForScreenName:nil
                                    orUserID:[userIDs componentsJoinedByString:@","]
                             includeEntities:nil
                                successBlock:^(NSArray *users) {
                                    NSLog(@"[%@] %s success %i accounts", NSStringFromClass([self class]), sel_getName(_cmd), [users count]);
                                    NSMutableArray *newAccounts = NSMutableArray.new;
                                    for (NSDictionary *user in users) {
                                        JFIAccount *account = [self findAccount:user[@"id_str"]];
                                        if (account) {
                                            NSDictionary *directory = @{JFIAccountUserIDKey          : user[@"id_str"],
                                                                        JFIAccountScreenNameKey      : user[@"screen_name"],
                                                                        JFIAccountDisplayNameKey     : user[@"name"],
                                                                        JFIAccountProfileImageURLKey : user[@"profile_image_url"],
                                                                        JFIAccountOAuthTokenKey      : account.oAuthToken,
                                                                        JFIAccountOAuthTokenSecretKey: account.oAuthTokenSecret};
                                            
                                            JFIAccount *newAccount = [[JFIAccount alloc] initWithDictionary:directory];
                                            
                                            [SSKeychain setPassword:[newAccount jsonStringRepresentation]
                                                         forService:JFIAccessTokenService
                                                            account:newAccount.screenName
                                                              error:nil];
                                            
                                            [newAccounts addObject:newAccount];
                                        }
                                    }
                                    
                                    self.accounts = newAccounts;
                                    
                                    successBlock();
                                }
                                  errorBlock:^(NSError *error) {
                                      NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), error);
                                      self.refreshedAccounts = NO;
                                  }];
    }
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

- (JFIAccount *)getAccount
{
    return [self.accounts objectAtIndex:self.currentAccountIndex];
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
    [application setIdleTimerDisabled:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setIdleTimerDisabled:YES];
    
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
    [self stopStreaming];
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


#pragma mark - NSNotification

- (void)setTheme
{
    [[UIApplication sharedApplication] setStatusBarStyle:[JFITheme sharedTheme].statusBarStyle];
}

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
                                                  
                                                  if ([response valueForKey:@"event"]) {
                                                      
                                                      // ふぁぼ・あんふぁぼ・フォロー・
                                                      NSLog(@"[JFIAppDelegate] event:%@", [response valueForKey:@"event"]);
                                                      JFIEntity *entity = [[JFIEntity alloc] initWithEvent:response];
                                                      JFIAccount *account = [self getAccount];
                                                      if ([account.userID isEqualToString:[response valueForKeyPath:@"source.id_str"]]) {
                                                          if (entity.type == EntityTypeFavorite) {
                                                              [[JFIActionStatus sharedActionStatus] setFavorite:entity.statusID];
                                                          } else if (entity.type == EntityTypeUnFavorite) {
                                                              [[JFIActionStatus sharedActionStatus] removeFavorite:entity.statusID];
                                                          }
                                                          return;
                                                      }
                                                      
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveEventNotification
                                                                                                          object:self
                                                                                                        userInfo:@{@"entity": entity}];
                                                      
                                                  } else if ([response valueForKeyPath:@"delete.status"]) {
                                                      
                                                      // ツイ消し
                                                      NSString *statusID = [response valueForKeyPath:@"delete.status.id_str"];
                                                      NSLog(@"[%@] %s destroyStatus statusID:%@", NSStringFromClass([self class]), sel_getName(_cmd), statusID);
                                                      JFIActionStatus *actionStatus = [JFIActionStatus sharedActionStatus];
                                                      for (NSString *originalStatusID in [actionStatus getRetweetOriginalStatusIDs:statusID]) {
                                                          NSLog(@"[%@] %s removeRetweet originalStatusID:%@ referenceStatusID:%@",
                                                                NSStringFromClass([self class]),
                                                                sel_getName(_cmd),
                                                                originalStatusID,
                                                                statusID);
                                                          [actionStatus removeRetweet:originalStatusID];
                                                      }
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIDestroyStatusNotification
                                                                                                          object:[[UIApplication sharedApplication] delegate]
                                                                                                        userInfo:@{@"status_id": statusID}];
                                                      
                                                  } else if ([response valueForKeyPath:@"delete.direct_message"]) {
                                                      
                                                      // DM削除
                                                      NSString *messageID = [response valueForKeyPath:@"delete.direct_message.id_str"];
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIDestroyMessageNotification
                                                                                                          object:[[UIApplication sharedApplication] delegate]
                                                                                                        userInfo:@{@"message_id": messageID}];
                                                      
                                                  } else if ([response valueForKey:@"direct_message"]) {
                                                      
                                                      // DM
                                                      JFIEntity *entity = [[JFIEntity alloc] initWithMessage:[response valueForKey:@"direct_message"]];
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveMessageNotification
                                                                                                          object:self
                                                                                                        userInfo:@{@"entity": entity}];
                                                      
                                                  } else if ([response valueForKey:@"text"]) {
                                                      
                                                      // ツイート・リツイート
                                                      JFIEntity *entity= [[JFIEntity alloc] initWithStatus:response];
                                                      if (entity.referenceStatusID != nil) {
                                                          JFIAccount *account = [self getAccount];
                                                          if ([account.userID isEqualToString:entity.actionedUserID]) {
                                                              [twitter getStatusesShowID:entity.statusID
                                                                                trimUser:0
                                                                        includeMyRetweet:0
                                                                         includeEntities:0
                                                                            successBlock:^(id response) {
                                                                                NSString *originalStatusID;
                                                                                if ([response valueForKey:@"retweeted_status"]) {
                                                                                    originalStatusID = [response valueForKeyPath:@"retweeted_status.id_str"];
                                                                                } else {
                                                                                    originalStatusID = [response valueForKey:@"id_str"];
                                                                                }
                                                                                NSLog(@"[%@] %s setRetweet originalStatusID:%@ referenceStatusID:%@",
                                                                                      NSStringFromClass([self class]),
                                                                                      sel_getName(_cmd),
                                                                                      entity.statusID,
                                                                                      entity.referenceStatusID);
                                                                                [[JFIActionStatus sharedActionStatus] setRetweetID:originalStatusID
                                                                                                                          statusID:entity.referenceStatusID];
                                                                            }
                                                                              errorBlock:^(NSError *error) {
                                                                                  NSLog(@"[%@] %s error %@",
                                                                                        NSStringFromClass([self class]),
                                                                                        sel_getName(_cmd),
                                                                                        [error description]);
                                                                              }];
                                                          }
                                                      }
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIReceiveStatusNotification
                                                                                                          object:self
                                                                                                        userInfo:@{@"entity": entity}];
                                                      
                                                  }
                                                  
                                              } stallWarningBlock:nil
                                                 errorBlock:^(NSError *error) {
                                                     
                                                     // 自分で止めた時 ... Connection was cancelled.
                                                     // 機内モード ... The network connection was lost.
                                                     // ネットワークエラー ... The network connection was lost.
                                                     // 接続制限(420) ... Exceeded connection limit for user
                                                     NSLog(@"[JFIAppDelegate] disconnect streaming status code:%li error code:%li description:%@",
                                                           (long)self.streamingRequest.responseStatus,
                                                           (long)[error code],
                                                           [error localizedDescription]);
                                                     if (self.streamingRequest.responseStatus == 420) {
                                                         self.streamingMode = NO;
                                                         NSLog(@"[JFIAppDelegate] streamingMode:off");
                                                         [[[UIAlertView alloc]
                                                           initWithTitle:@"error"
                                                           message:NSLocalizedString(@"streaming_rate_limited", nil)
                                                           delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:@"OK", nil
                                                           ] show];
                                                     }
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
    [self performSelector:@selector(startStreaming) withObject:nil afterDelay:10.f];
}

@end
