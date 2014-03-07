//
//  JFIAccount.h
//  Justaway
//
//  Created by 木村圭佑 on 2014/03/07.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JFIAccount;

typedef void(^JFILoginSuccessBlock)(JFIAccount *account);
typedef void(^JFILoginErrorBlock)(NSError *error);

@interface JFIAccount : NSObject<NSCopying>

@property (nonatomic, copy, readonly) NSString *oAuthToken;
@property (nonatomic, copy, readonly) NSString *oAuthTokenSecret;
@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy, readonly) NSString *screenName;

+ (instancetype)newWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)newWithJsonString:(NSString *)jsonString;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithJsonString:(NSString *)jsonString;

- (NSDictionary *)dictionaryRepresentation;
- (NSString *)jsonStringRepresentation;

+ (void)loginUsingIOSAccountWithSuccessBlock:(JFILoginSuccessBlock)successBlock
                                  errorBlock:(JFILoginErrorBlock)errorBlock;

@end
