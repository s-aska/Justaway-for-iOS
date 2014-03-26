#import "JFISecret.h"
#import "JFIAccount.h"
#import <STTwitter.h>

NSString const* JFI_KeyOAuthToken = @"oauthToken";
NSString const* JFI_KeyOAuthTokenSecret = @"oauthTokenSecret";
NSString const* JFI_KeyUserID = @"userID";
NSString const* JFI_KeyScreenName = @"screenName";
NSString const* JFI_KeyProfileImageUrl = @"profileImageUrl";
NSString const* JFI_KeyConsumerKey = @"consumer_key";
NSString const* JFI_KeyConsumerSecret = @"consumer_secret";

@interface JFIAccount ()

@property (nonatomic, copy, readwrite) NSString *oAuthToken;
@property (nonatomic, copy, readwrite) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, copy, readwrite) NSString *screenName;
@property (nonatomic, copy, readwrite) NSString *profileImageUrl;

@end

@implementation JFIAccount

#pragma mark Initializer

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
        self.oAuthToken = dictionary[JFI_KeyOAuthToken];
        self.oAuthTokenSecret = dictionary[JFI_KeyOAuthTokenSecret];
        self.userID = dictionary[JFI_KeyUserID];
        self.screenName = dictionary[JFI_KeyScreenName];
        self.profileImageUrl = dictionary[JFI_KeyProfileImageUrl];
    }
    return self;
}

- (instancetype)initWithJsonString:(NSString *)jsonString
{
    // NSString => NSData
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // NSData => NSDictionary
    NSDictionary *accountDictionary = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingAllowFragments
                                                                        error:nil];
    return [self initWithDictionary:accountDictionary];
}

#pragma mark - NSCopying Methods

- (id)copyWithZone:(NSZone *)zone
{
    JFIAccount *account = [[[self class] allocWithZone:zone] init];
    
    [account setOAuthToken:self.oAuthToken];
    [account setOAuthTokenSecret:self.oAuthTokenSecret];
    [account setUserID:self.userID];
    [account setScreenName:self.screenName];
    [account setProfileImageUrl:self.profileImageUrl];
    
    return account;
}

#pragma mark - Representation Methods

- (NSDictionary *)dictionaryRepresentation
{
    return @{JFI_KeyOAuthToken : self.oAuthToken,
             JFI_KeyOAuthTokenSecret : self.oAuthTokenSecret,
             JFI_KeyUserID : self.userID,
             JFI_KeyScreenName : self.screenName,
             JFI_KeyProfileImageUrl : self.profileImageUrl};
}

- (NSString *)jsonStringRepresentation
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation]
                                                       options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}
#pragma mark - description

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@",[self dictionaryRepresentation]];
}

#pragma mark - Login Methods

+ (void)loginUsingIOSAccountWithSuccessBlock:(void(^)(JFIAccount *account))successBlock errorBlock:(void(^)(NSError *error))errorBlock
{
    
    // STTwitterAPIのインスタンスをセット
    STTwitterAPI *loginTwitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                                      consumerKey:JFI_ConsumerKey
                                                                   consumerSecret:JFI_ConsumerSecret];
    
    [loginTwitterAPI postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithFirstAccount];
        
        [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
            void(^accessTokenSuccessBlock)(NSString *, NSString *, NSString *, NSString *) =
            ^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
                [loginTwitterAPI getUsersShowForUserID:userID
                                          orScreenName:nil
                                       includeEntities:nil
                                          successBlock:^(NSDictionary *user) {
                                              JFIAccount *account = [JFIAccount new];
                                              account.oAuthToken = oAuthToken;
                                              account.oAuthTokenSecret = oAuthTokenSecret;
                                              account.userID = userID;
                                              account.screenName = screenName;
                                              account.profileImageUrl = [user valueForKey:@"profile_image_url"];
                                              successBlock(account);
                                          }
                                            errorBlock:errorBlock];
            };
            [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                successBlock:accessTokenSuccessBlock
                                                                  errorBlock:errorBlock];
        } errorBlock:errorBlock];
    } errorBlock:errorBlock];
    
}

@end
