#import <Foundation/Foundation.h>
#import "JFIEntity.h"

@interface JFIActionStatus : NSObject

+ (JFIActionStatus *)sharedActionStatus;

- (BOOL)isFavorite:(NSString *)originalStatusID;
- (void)setFavorite:(NSString *)originalStatusID;
- (void)removeFavorite:(NSString *)originalStatusID;
- (BOOL)isRetweet:(NSString *)originalStatusID;
- (BOOL)isRetweetEntity:(JFIEntity *)entity;
- (NSString *)getRetweetID:(NSString *)originalStatusID;
- (NSArray *)getRetweetOriginalStatusIDs:(NSString *)referenceStatusID;
- (void)setRetweet:(NSString *)originalStatusID;
- (void)setRetweetID:(NSString *)originalStatusID statusID:(NSString *)referenceStatusID;
- (void)removeRetweet:(NSString *)originalStatusID;

@end
