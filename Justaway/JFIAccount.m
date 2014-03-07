//
//  JFIAccount.m
//  Justaway
//
//  Created by 木村圭佑 on 2014/03/07.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JFIAccount.h"

#import <STTwitter.h>

NSString const* JFI_KeyOAuthToken = @"oauthToken";
NSString const* JFI_KeyOAuthTokenSecret = @"oauthTokenSecret";
NSString const* JFI_KeyUserID = @"userID";
NSString const* JFI_KeyScreenName = @"screenName";
NSString const* JFI_KeyConsumerKey = @"consumer_key";
NSString const* JFI_KeyConsumerSecret = @"consumer_secret";

@interface JFIAccount ()

@property (nonatomic, copy, readwrite) NSString *oAuthToken;
@property (nonatomic, copy, readwrite) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, copy, readwrite) NSString *screenName;

@end

@implementation JFIAccount

#pragma mark Initializer

+ (instancetype)newWithDictionary:(NSDictionary *)dictionary
{
    return [[JFIAccount alloc] initWithDictionary:dictionary];
}

+ (instancetype)newWithJsonString:(NSString *)jsonString
{
    return [[JFIAccount alloc] initWithJsonString:jsonString];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
        self.oAuthToken = dictionary[JFI_KeyOAuthToken];
        self.oAuthTokenSecret = dictionary[JFI_KeyOAuthTokenSecret];
        self.userID = dictionary[JFI_KeyUserID];
        self.screenName = dictionary[JFI_KeyScreenName];
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

#pragma mark -
#pragma mark NSCopying Methods
- (id)copyWithZone:(NSZone *)zone
{
    JFIAccount *account = [[[self class] allocWithZone:zone] init];
    
    [account setOAuthToken:self.oAuthToken];
    [account setOAuthTokenSecret:self.oAuthTokenSecret];
    [account setUserID:self.userID];
    [account setScreenName:self.screenName];
    
    return account;
}

#pragma mark -
#pragma mark Representation Methods
- (NSDictionary *)dictionaryRepresentation
{
    return @{JFI_KeyOAuthToken : self.oAuthToken,
             JFI_KeyOAuthTokenSecret : self.oAuthTokenSecret,
             JFI_KeyUserID : self.userID,
             JFI_KeyScreenName : self.screenName};
}

- (NSString *)jsonStringRepresentation
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation]
                                                       options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

}
#pragma mark -
#pragma mark description
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@",[self dictionaryRepresentation]];
}

#pragma mark -
#pragma mark Login Methods

+ (void)loginUsingIOSAccountWithSuccessBlock:(JFILoginSuccessBlock)successBlock errorBlock:(JFILoginErrorBlock)errorBlock
{
    
    NSDictionary *secret = [self secretFromPlist];
    
    // STTwitterAPIのインスタンスをセット
    STTwitterAPI *loginTwitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                                      consumerKey:secret[JFI_KeyConsumerKey]
                                                                   consumerSecret:secret[JFI_KeyConsumerSecret]];
    
    [loginTwitterAPI postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithFirstAccount];
        
        [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
            void(^accessTokenSuccessBlock)(NSString *, NSString *, NSString *, NSString *) =
            ^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
                JFIAccount *account = [JFIAccount new];
                account.oAuthToken = oAuthToken;
                account.oAuthTokenSecret = oAuthTokenSecret;
                account.userID = userID;
                account.screenName = screenName;
                
                successBlock(account);
            };
            [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                successBlock:accessTokenSuccessBlock
                                                                  errorBlock:errorBlock];
        } errorBlock:errorBlock];
    } errorBlock:errorBlock];
    
}

+ (NSDictionary *)secretFromPlist
{
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* path = [bundle pathForResource:@"secret" ofType:@"plist"];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

@end
