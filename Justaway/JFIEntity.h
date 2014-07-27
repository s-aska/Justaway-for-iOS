#import <Foundation/Foundation.h>
#import "JFIConstants.h"

@interface JFIEntity : NSObject

@property (nonatomic) EntityType type;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *screenName;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSURL *profileImageURL;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *createdAt;
@property (nonatomic) NSString *clientName;
@property (nonatomic) NSNumber *retweetCount;
@property (nonatomic) NSNumber *favoriteCount;
@property (nonatomic) NSArray *urls;
@property (nonatomic) NSArray *userMentions;
@property (nonatomic) NSArray *hashtags;
@property (nonatomic) NSArray *media;
@property (nonatomic) NSString *actionedUserID;
@property (nonatomic) NSString *actionedScreenName;
@property (nonatomic) NSString *actionedDisplayName;
@property (nonatomic) NSURL *actionedProfileImageURL;
@property (nonatomic) NSString *referenceStatusID;

// Status only
@property (nonatomic) NSString *statusID;

// Message only
@property (nonatomic) NSString *messageID;

// Cell
@property (nonatomic) NSNumber *height;
@property (nonatomic) float fontSize;


- (instancetype)initDummy;
- (instancetype)initWithStatus:(NSDictionary *)status;
- (instancetype)initWithMessage:(NSDictionary *)message;
- (instancetype)initWithEvent:(NSDictionary *)event;

- (NSString *)statusURL;
- (NSURL *)profileImageBiggerURL;

@end
