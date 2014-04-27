#import <Foundation/Foundation.h>
#import "JFIConstants.h"

@interface JFIEntity : NSObject

@property (nonatomic) EntityType type;
@property (nonatomic) NSString *statusID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *screenName;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSURL *profileImageURL;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *createdAt;
@property (nonatomic) NSString *clientName;
@property (nonatomic) NSNumber *retweetCount;
@property (nonatomic) NSNumber *favoriteCount;
@property (nonatomic) NSNumber *height;

@property (nonatomic) NSString *messageID;


- (instancetype)initWithStatus:(NSDictionary *)status;
- (instancetype)initWithMessage:(NSDictionary *)message;

- (NSString *)statusURL;

@end
