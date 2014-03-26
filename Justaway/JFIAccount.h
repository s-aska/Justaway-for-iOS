#import <Foundation/Foundation.h>

@class JFIAccount;

@interface JFIAccount : NSObject<NSCopying>

@property (nonatomic, copy, readonly) NSString *oAuthToken;
@property (nonatomic, copy, readonly) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy, readonly) NSString *screenName;
@property (nonatomic, copy, readonly) NSString *profileImageUrl;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithJsonString:(NSString *)jsonString;

- (NSDictionary *)dictionaryRepresentation;
- (NSString *)jsonStringRepresentation;

+ (void)loginUsingIOSAccountWithSuccessBlock:(void(^)(JFIAccount *account))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

@end
