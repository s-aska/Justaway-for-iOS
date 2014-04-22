#import "JFITweet.h"

@implementation JFITweet

- (instancetype)initWithStatus:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.userID = dictionary[@""];
        self.screenName = dictionary[@""];
        self.displayName = dictionary[@""];
        self.profileImageURL = dictionary[@""];
//        @"id_str": [dictionaly valueForKey:@"id_str"],
//        @"user.name": [dictionaly valueForKeyPath:@"sender.name"],
//        @"user.screen_name": [dictionaly valueForKeyPath:@"sender.screen_name"],
//        @"text": [dictionaly valueForKey:@"text"],
//        @"source": @"",
//        @"created_at": [dictionaly valueForKey:@"created_at"],
//        @"user.profile_image_url": [dictionaly valueForKeyPath:@"sender.profile_image_url"],
//        @"retweet_count": @0,
//        @"favorite_count": @0,
//        @"is_message": @1};
    }
    return self;
}

@end
