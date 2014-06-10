#import <Foundation/Foundation.h>
#import "STTwitterAPI.h"
#import "JFIEntity.h"

@interface JFITwitter : NSObject

+ (void)createFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)createRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)destroyStatus:(STTwitterAPI *)twitter statusID:(NSString *)statusID;
+ (void)quote:(JFIEntity *)entity;
+ (void)reply:(JFIEntity *)entity;

@end
