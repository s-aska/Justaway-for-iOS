#import "JFISecret.h"
#import "JFIConstants.h"
#import "JFIAccount.h"
#import "NSDictionary+Default.h"
#import <STTwitter.h>

@interface JFIAccount ()

@property (nonatomic, copy, readwrite) NSString *oAuthToken;
@property (nonatomic, copy, readwrite) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, copy, readwrite) NSString *screenName;
@property (nonatomic, copy, readwrite) NSString *displayName;
@property (nonatomic, copy, readwrite) NSString *profileImageURL;
@property (nonatomic, copy, readwrite) NSNumber *priority;

@end

@implementation JFIAccount

#pragma mark - Initializer

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.oAuthToken = dictionary[JFIAccountOAuthTokenKey];
        self.oAuthTokenSecret = dictionary[JFIAccountOAuthTokenSecretKey];
        self.userID = dictionary[JFIAccountUserIDKey];
        self.screenName = dictionary[JFIAccountScreenNameKey];
        self.displayName = [dictionary objectForKey:JFIAccountDisplayNameKey defaultObject:@"-"];
        self.profileImageURL = dictionary[JFIAccountProfileImageURLKey];
        self.priority = [dictionary objectForKey:JFIAccountPriorityKey defaultObject:@(1)];
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
    [account setDisplayName:self.displayName];
    [account setProfileImageURL:self.profileImageURL];
    [account setPriority:self.priority];
    
    return account;
}

#pragma mark - Representation Methods

- (NSDictionary *)dictionaryRepresentation
{
    return @{JFIAccountOAuthTokenKey:       self.oAuthToken,
             JFIAccountOAuthTokenSecretKey: self.oAuthTokenSecret,
             JFIAccountUserIDKey:           self.userID,
             JFIAccountScreenNameKey:       self.screenName,
             JFIAccountDisplayNameKey:      self.displayName,
             JFIAccountProfileImageURLKey:  self.profileImageURL,
             JFIAccountPriorityKey:         self.priority};
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

#pragma mark - 

- (NSURL *)profileImageBiggerURL
{
    return [NSURL URLWithString:[self.profileImageURL stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.png"]];
}

#pragma mark - Login Methods

+ (void)loginUsingIOSAccountWithSuccessBlock:(void(^)(JFIAccount *account))successBlock errorBlock:(void(^)(NSError *error))errorBlock
{
    
    // STTwitterAPIのインスタンスをセット
    STTwitterAPI *loginTwitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                                      consumerKey:JFITwitterConsumerKey
                                                                   consumerSecret:JFITwitterConsumerSecret];
    
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
                                              account.oAuthToken       = oAuthToken;
                                              account.oAuthTokenSecret = oAuthTokenSecret;
                                              account.userID           = userID;
                                              account.screenName       = screenName;
                                              account.displayName      = user[@"name"];
                                              account.profileImageURL  = user[@"profile_image_url"];
                                              account.priority         = @([[NSDate date] timeIntervalSince1970]);
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
