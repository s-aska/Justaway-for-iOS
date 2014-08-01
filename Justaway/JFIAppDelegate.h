#import <UIKit/UIKit.h>
#import "STTwitter.h"
#import "JFIConstants.h"
#import "JFIAccount.h"

@interface JFIAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) STTwitterAPI *loginTwitter; // アカウント追加（Twitter認証）専用Twitterインスタンス
@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) NSInteger currentAccountIndex;
@property (nonatomic) StreamingStatus streamingStatus;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) BOOL streamingMode;
@property (nonatomic) float fontSize;
@property (nonatomic) BOOL resizing;
@property (nonatomic) BOOL refreshedAccounts;

- (STTwitterAPI *)getTwitter;
- (STTwitterAPI *)getTwitterByIndex:(NSInteger)index;
- (JFIAccount *)getAccount;
- (void)loadAccounts;
- (void)clearAccounts;
- (void)removeAccount:(NSString *)userID;
- (void)refreshAccounts;
- (JFIAccount *)updateAccount:(NSString *)userID
                   screenName:(NSString *)screenName
                         name:(NSString *)name
              profileImageURL:(NSString *)profileImageURL
                     priority:(NSNumber *)priority;
- (void)postTokenRequest;
- (void)loginUsingIOSAccount;
- (BOOL)enableStreaming;
- (void)startStreaming;
- (void)stopStreaming;
- (void)restartStreaming;

@end
