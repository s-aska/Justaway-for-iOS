#import "JFISecret.h"
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
    
    // アカウントリスト初期化
    self.accounts = [@[] mutableCopy];
    
    // KeyChain上のアカウント情報はJSONでシリアライズしているので、これをデシリアライズする
    for (NSDictionary *dictionary in dictionaries) {
        
        // KeyChain => NSString
        NSString *jsonString = [SSKeychain passwordForService:JFIAccessTokenService
                                                      account:[dictionary objectForKey:@"acct"]
                                                        error:nil];
        
        JFIAccount *account = [[JFIAccount alloc] initWithJsonString:jsonString];
        
        // 最後にpush
        [self.accounts addObject:account];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    self.accounts = [[self.accounts sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
}

- (void)saveAccount:(JFIAccount *)account
{
    [SSKeychain setPassword:[account jsonStringRepresentation]
                 forService:JFIAccessTokenService
                    account:account.userID
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

- (void)removeAccount:(NSString *)userID
{
    JFIAccount *targetAccount;
    int index = 0;
    for (JFIAccount *account in self.accounts) {
        if ([account.userID isEqualToString:userID]) {
            targetAccount = account;
            continue;
        }
        index++;
    }
    if (targetAccount == nil) {
        return;
    }
    if (self.currentAccountIndex > 0 && self.currentAccountIndex <= index) {
        self.currentAccountIndex--;
    }
    
    [self.accounts removeObject:targetAccount];
    
    [SSKeychain deletePasswordForService:JFIAccessTokenService account:targetAccount.userID];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIRefreshAccessTokenNotification
                                                        object:self
                                                      userInfo:nil];
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

- (void)refreshAccounts
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
                                    NSMutableArray *accounts = NSMutableArray.new;
                                    int priorty = 0;
                                    for (NSDictionary *user in users) {
                                        JFIAccount *account = [self updateAccount:user[@"id_str"]
                                                                       screenName:user[@"screen_name"]
                                                                             name:user[@"name"]
                                                                  profileImageURL:user[@"profile_image_url"]
                                                                         priority:@(priorty)];
                                        
                                        if (account) {
                                            [accounts addObject:account];
                                            priorty++;
                                        }
                                        
                                        [SSKeychain deletePasswordForService:JFIAccessTokenService account:user[@"screen_name"]]; // TODO: 下位互換
                                    }
                                    
                                    self.accounts = accounts;
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:JFIRefreshAccessTokenNotification
                                                                                        object:self
                                                                                      userInfo:nil];
                                }
                                  errorBlock:^(NSError *error) {
                                      NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), error);
                                      self.refreshedAccounts = NO;
                                  }];
    }
}

- (JFIAccount *)updateAccount:(NSString *)userID
                   screenName:(NSString *)screenName
                         name:(NSString *)name
              profileImageURL:(NSString *)profileImageURL
                     priority:(NSNumber *)priority
{
    JFIAccount *account = [self findAccount:userID];
    if (account) {
        NSDictionary *directory = @{JFIAccountUserIDKey          : userID,
                                    JFIAccountScreenNameKey      : screenName,
                                    JFIAccountDisplayNameKey     : name,
                                    JFIAccountProfileImageURLKey : profileImageURL,
                                    JFIAccountOAuthTokenKey      : account.oAuthToken,
                                    JFIAccountOAuthTokenSecretKey: account.oAuthTokenSecret,
                                    JFIAccountPriorityKey        : priority};
        
        JFIAccount *newAccount = [[JFIAccount alloc] initWithDictionary:directory];
        
        [SSKeychain setPassword:[newAccount jsonStringRepresentation]
                     forService:JFIAccessTokenService
                        account:newAccount.userID
                          error:nil];
        
        return newAccount;
    } else {
        [SSKeychain deletePasswordForService:JFIAccessTokenService account:userID];
        return nil;
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
                                 NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), error);
                             }];
}

- (void)loginUsingIOSAccount
{
    [JFIAccount loginUsingIOSAccountWithSuccessBlock:^(JFIAccount *account) {
        [self saveAccount:account];
    } errorBlock:^(NSError *error) {
        NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), error);
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
        NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), error);
    };
    void(^accessTokenSuccessBlock)(NSString *, NSString *, NSString *, NSString *) =
    ^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        [self.loginTwitter getUsersShowForUserID:userID
                                    orScreenName:nil
                                 includeEntities:nil
                                    successBlock:^(NSDictionary *user) {
                                        NSNumber *priority;
                                        JFIAccount *account = [self findAccount:userID];
                                        if (account) {
                                            priority = account.priority;
                                        } else {
                                            priority = @([[NSDate date] timeIntervalSince1970]);
                                        }
                                        NSDictionary *directory = @{JFIAccountUserIDKey          : userID,
                                                                    JFIAccountScreenNameKey      : screenName,
                                                                    JFIAccountDisplayNameKey     : user[@"name"],
                                                                    JFIAccountProfileImageURLKey : user[@"profile_image_url"],
                                                                    JFIAccountOAuthTokenKey      : oauthToken,
                                                                    JFIAccountOAuthTokenSecretKey: oauthTokenSecret,
                                                                    JFIAccountPriorityKey        : priority};
                                        
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
        NSLog(@"[%@] %s disconnected", NSStringFromClass([self class]), sel_getName(_cmd));
        return;
    }
    NSLog(@"[%@] %s connected", NSStringFromClass([self class]), sel_getName(_cmd));
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
    if (self.streamingStatus == StreamingConnecting ||
        self.streamingStatus == StreamingConnected) {
        NSLog(@"[%@] %s streaming is connected or connecting.", NSStringFromClass([self class]), sel_getName(_cmd));
        return;
    }
    if ([self.accounts count] == 0) {
        return;
    }
    
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    
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
                                                      NSLog(@"[%@] %s connect streaming", NSStringFromClass([self class]), sel_getName(_cmd));
                                                      self.streamingStatus = StreamingConnected;
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:JFIStreamingConnectionNotification
                                                                                                          object:self
                                                                                                        userInfo:nil];
                                                  }
                                                  
                                                  if ([response valueForKey:@"event"]) {
                                                      
                                                      // ふぁぼ・あんふぁぼ・フォロー・
                                                      NSLog(@"[%@] %s event:%@", NSStringFromClass([self class]), sel_getName(_cmd), [response valueForKey:@"event"]);
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
                                                     NSLog(@"[%@] %s disconnect streaming status code:%li error code:%li description:%@",
                                                           NSStringFromClass([self class]),
                                                           sel_getName(_cmd),
                                                           (long)self.streamingRequest.responseStatus,
                                                           (long)[error code],
                                                           [error localizedDescription]);
                                                     if (self.streamingRequest.responseStatus == 420) {
                                                         self.streamingMode = NO;
                                                         NSLog(@"[%@] %s streamingMode:off", NSStringFromClass([self class]), sel_getName(_cmd));
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
        NSLog(@"[%@] %s streaming is disconnected or disconnecting.", NSStringFromClass([self class]), sel_getName(_cmd));
        return;
    }
    
    self.streamingStatus = StreamingDisconnecting;
    [self.streamingRequest cancel];
    
    UIApplication *app = [UIApplication sharedApplication];
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
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
