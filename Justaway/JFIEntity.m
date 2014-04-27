#import "JFIEntity.h"

@implementation JFIEntity

- (instancetype)initWithStatus:(NSDictionary *)status
{
    self = [super init];
    if (self) {
        self.type = EntityTypeStatus;
        self.statusID = [status valueForKey:@"id_str"];
        self.userID = [status valueForKeyPath:@"user.id_str"];
        self.screenName = [status valueForKeyPath:@"user.screen_name"];
        self.displayName = [status valueForKeyPath:@"user.name"];
        self.profileImageURL = [[NSURL alloc] initWithString:[status valueForKeyPath:@"user.profile_image_url"]];
        self.text = [status valueForKey:@"text"];
        self.createdAt = [status valueForKey:@"created_at"];
        self.clientName = [self getClientName:[status valueForKey:@"source"]];
        self.retweetCount = [status valueForKey:@"retweet_count"];
        self.favoriteCount = [status valueForKey:@"favorite_count"];
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
    }
    return self;
}

- (NSString *)getClientName:(NSString *)source
{
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"rel=\"nofollow\">(.+)</a>" options:0 error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
    } else {
        NSTextCheckingResult *match = [regexp firstMatchInString:source options:0 range:NSMakeRange(0, source.length)];
        if (match.numberOfRanges > 0) {
            return [source substringWithRange:[match rangeAtIndex:1]];
        }
    }
    return source;
}

- (NSString *)statusURL
{
    return [NSString stringWithFormat:@" https://twitter.com/%@/status/%@", self.screenName, self.statusID];
}

@end
