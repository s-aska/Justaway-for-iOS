#import <UIKit/UIKit.h>
#import "STTwitter.h"
#import "JFIConstants.h"

@interface JFIAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) STTwitterAPI *loginTwitter; // アカウント追加（Twitter認証）専用Twitterインスタンス
@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) StreamingStatus streamingStatus;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) BOOL streamingMode;

- (STTwitterAPI *)getTwitter;
- (STTwitterAPI *)getTwitterByIndex:(NSInteger *)index;
- (void)clearAccounts;
- (void)postTokenRequest;
- (void)loginUsingIOSAccount;
- (BOOL)enableStreaming;
- (void)startStreaming;
- (void)stopStreaming;

@end
