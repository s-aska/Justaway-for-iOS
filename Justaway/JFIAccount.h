#import <Foundation/Foundation.h>

extern NSString const* JFI_KeyOAuthToken;
extern NSString const* JFI_KeyOAuthTokenSecret;
extern NSString const* JFI_KeyUserID;
extern NSString const* JFI_KeyScreenName;
extern NSString const* JFI_KeyDisplayName;
extern NSString const* JFI_KeyProfileImageUrl;
extern NSString const* JFI_KeyConsumerKey;
extern NSString const* JFI_KeyConsumerSecret;

@class JFIAccount;

@interface JFIAccount : NSObject<NSCopying>

@property (nonatomic, copy, readonly) NSString *oAuthToken;
@property (nonatomic, copy, readonly) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy, readonly) NSString *screenName;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *profileImageUrl;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithJsonString:(NSString *)jsonString;

- (NSDictionary *)dictionaryRepresentation;
- (NSString *)jsonStringRepresentation;

+ (void)loginUsingIOSAccountWithSuccessBlock:(void(^)(JFIAccount *account))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

@end
