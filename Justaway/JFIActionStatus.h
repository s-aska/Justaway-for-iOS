#import <Foundation/Foundation.h>

@interface JFIActionStatus : NSObject

+ (JFIActionStatus *)sharedActionStatus;

- (BOOL)isFavorite:(NSString *)key;
- (void)setFavorite:(NSString *)key;
- (void)removeFavorite:(NSString *)key;
- (BOOL)isRetweet:(NSString *)key;
- (NSString *)getRetweetId:(NSString *)key;
- (void)setRetweet:(NSString *)key;
- (void)setRetweetId:(NSString *)key statusId:(NSString *)statusId;
- (void)removeRetweet:(NSString *)key;

@end
