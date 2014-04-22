#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TweetType) {
    TweetTypeStatus,
    TweetTypeFavorite,
    TweetTypeMessage,
};

@interface JFITweet : NSObject

@property (nonatomic) NSString *statusID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *screenName;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *profileImageURL;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *createdAt;
@property (nonatomic) NSString *source;

@end
