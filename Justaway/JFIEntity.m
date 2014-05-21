#import "JFIEntity.h"

@implementation JFIEntity

- (instancetype)initDummy
{
    self = [super init];
    if (self) {
        self.type = EntityTypeStatus;
        self.statusID = @"1";
        self.userID = @"1";
        self.screenName = @"su_aska";
        self.displayName = @"Shinichiro Aska";
        self.profileImageURL = [[NSURL alloc] initWithString:@""];
        self.text = @"今日は鯖味噌の日。\n今日は鯖味噌の日。\n今日は鯖味噌の日。";
        self.createdAt = @"Wed Jun 06 20:07:10 +0000 2012";
        self.clientName = @"web";
        self.retweetCount = @10000;
        self.favoriteCount = @20000;
        self.urls = NSArray.new;
        self.userMentions = NSArray.new;
        self.hashtags = NSArray.new;
        self.media = NSArray.new;
    }
    return self;
}

- (instancetype)initWithStatus:(NSDictionary *)status
{
    self = [super init];
    if (self) {
        self.type = EntityTypeStatus;
        NSDictionary *source;
        if ([status valueForKey:@"retweeted_status"] == nil) {
            source = status;
        } else {
            source = [status valueForKey:@"retweeted_status"];
            self.actionedUserID = [status valueForKeyPath:@"user.id_str"];
            self.actionedScreenName = [status valueForKeyPath:@"user.screen_name"];
            self.actionedDisplayName = [status valueForKeyPath:@"user.name"];
            self.actionedProfileImageURL = [[NSURL alloc] initWithString:[status valueForKeyPath:@"user.profile_image_url"]];
        }
        self.statusID = [source valueForKey:@"id_str"];
        self.userID = [source valueForKeyPath:@"user.id_str"];
        self.screenName = [source valueForKeyPath:@"user.screen_name"];
        self.displayName = [source valueForKeyPath:@"user.name"];
        self.profileImageURL = [[NSURL alloc] initWithString:[source valueForKeyPath:@"user.profile_image_url"]];
        self.text = [source valueForKey:@"text"];
        self.createdAt = [source valueForKey:@"created_at"];
        self.clientName = [self getClientName:[source valueForKey:@"source"]];
        self.retweetCount = [source valueForKey:@"retweet_count"];
        self.favoriteCount = [source valueForKey:@"favorite_count"];
        self.urls = [source valueForKeyPath:@"entities.urls"];
        self.userMentions = [source valueForKeyPath:@"entities.user_mentions"];
        self.hashtags = [source valueForKeyPath:@"entities.hashtags"];
        self.media = [source valueForKeyPath:@"entities.media"];
    }
    return self;
}

- (instancetype)initWithMessage:(NSDictionary *)message
{
    self = [super init];
    if (self) {
        self.type = EntityTypeMessage;
        self.messageID = [message valueForKey:@"id_str"];
        self.userID = [message valueForKeyPath:@"sender.id_str"];
        self.screenName = [message valueForKeyPath:@"sender.screen_name"];
        self.displayName = [message valueForKeyPath:@"sender.name"];
        self.profileImageURL = [[NSURL alloc] initWithString:[message valueForKeyPath:@"sender.profile_image_url"]];
        self.text = [message valueForKey:@"text"];
        self.createdAt = [message valueForKey:@"created_at"];
        self.urls = [message valueForKeyPath:@"entities.urls"];
        self.userMentions = [message valueForKeyPath:@"entities.user_mentions"];
        self.hashtags = [message valueForKeyPath:@"entities.hashtags"];
        self.media = [message valueForKeyPath:@"entities.media"];
    }
    return self;
}

- (NSString *)getClientName:(NSString *)source
{
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"rel=\"nofollow\">(.+)</a>" options:0 error:nil];
    NSTextCheckingResult *match = [regexp firstMatchInString:source options:0 range:NSMakeRange(0, source.length)];
    if (match.numberOfRanges > 0) {
        return [source substringWithRange:[match rangeAtIndex:1]];
    }
    return source;
}

- (NSString *)statusURL
{
    return [NSString stringWithFormat:@" https://twitter.com/%@/status/%@", self.screenName, self.statusID];
}

@end
