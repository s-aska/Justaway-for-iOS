#import <Foundation/Foundation.h>

@interface JFIActionStatus : NSObject

+ (JFIActionStatus *)sharedActionStatus;

- (BOOL)isFavorite:(NSString *)key;
- (void)setFavorite:(NSString *)key;
- (void)removeFavorite:(NSString *)key;
- (BOOL)isRetweet:(NSString *)key;
- (NSString *)getRetweetID:(NSString *)key;
- (void)setRetweet:(NSString *)key;
- (void)setRetweetID:(NSString *)key statusID:(NSString *)statusID;
- (void)removeRetweet:(NSString *)key;

@end
