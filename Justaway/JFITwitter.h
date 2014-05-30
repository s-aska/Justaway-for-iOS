#import <Foundation/Foundation.h>
#import "STTwitterAPI.h"

@interface JFITwitter : NSObject

+ (void)createFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)createRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyStatus:(STTwitterAPI *)twitter statusID:(NSString *)statusID;

@end
