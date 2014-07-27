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
        self.profileImageURL = [NSURL URLWithString:@"https://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"];
        self.text = @"Please touch user icon.";
        self.createdAt = @"Wed Jun 06 20:07:10 +0000 2012";
        self.clientName = @"web";
        self.retweetCount = @10000;
        self.favoriteCount = @20000;
        self.urls = NSArray.new;
        self.userMentions = NSArray.new;
        self.hashtags = NSArray.new;
        self.media = @[@{
                           @"display_url": @"pic.twitter.com/rJC5Pxsu",
                           @"expanded_url": @"http://twitter.com/yunorno/status/114080493036773378/photo/1",
                           @"id": @114080493040967680,
                           @"id_str": @"114080493040967680",
                           @"media_url": @"http://pbs.twimg.com/media/BoXV1KSIgAAHJpZ.png",
                           @"media_url_https": @"https://pbs.twimg.com/media/BoXV1KSIgAAHJpZ.png",
                           @"type": @"photo",
                           @"url": @"http://t.co/rJC5Pxsu",
                           @"sizes": @{
                                   @"large": @{
                                           @"h": @392,
                                           @"resize": @"fit",
                                           @"w": @596
                                           }
                                   }
                           },@{
                           @"display_url": @"pic.twitter.com/rJC5Pxsu",
                           @"expanded_url": @"http://twitter.com/yunorno/status/114080493036773378/photo/1",
                           @"id": @114080493040967680,
                           @"id_str": @"114080493040967680",
                           @"media_url": @"http://pbs.twimg.com/media/BoXV1KSIgAAHJpZ.png",
                           @"media_url_https": @"https://pbs.twimg.com/media/BoXV1KSIgAAHJpZ.png",
                           @"type": @"photo",
                           @"url": @"http://t.co/rJC5Pxsu",
                           @"sizes": @{
                                   @"large": @{
                                           @"h": @392,
                                           @"resize": @"fit",
                                           @"w": @596
                                           }
                                   }
                           }];
    }
    return self;
}

- (instancetype)initWithStatus:(NSDictionary *)status
{
    self = [super init];
    if (self) {
        self.type = EntityTypeStatus;
        if ([status valueForKey:@"retweeted_status"]) {
            [self setUser:[status valueForKeyPath:@"retweeted_status.user"]];
            [self setStatus:[status valueForKey:@"retweeted_status"]];
            [self setActionedUser:[status valueForKey:@"user"]];
            self.referenceStatusID = [status valueForKey:@"id_str"];
        } else {
            [self setUser:[status valueForKey:@"user"]];
            [self setStatus:status];
        }
        
    }
    return self;
}

- (instancetype)initWithEvent:(NSDictionary *)event
{
    self = [super init];
    if (self) {
        if ([[event valueForKey:@"event"] isEqualToString:@"favorite"]) {
            self.type = EntityTypeFavorite;
            [self setUser:[event valueForKeyPath:@"target_object.user"]];
            [self setStatus:[event valueForKey:@"target_object"]];
            [self setActionedUser:[event valueForKey:@"source"]];
        } else if ([[event valueForKey:@"event"] isEqualToString:@"unfavorite"]) {
            self.type = EntityTypeUnFavorite;
            [self setUser:[event valueForKeyPath:@"target_object.user"]];
            [self setStatus:[event valueForKey:@"target_object"]];
            [self setActionedUser:[event valueForKey:@"source"]];
        } else if ([[event valueForKey:@"event"] isEqualToString:@"follow"]) {
            self.type = EntityTypeFollow;
            [self setUser:[event valueForKey:@"source"]];
            self.text = [event valueForKeyPath:@"source.description"];
            self.createdAt = [event valueForKey:@"created_at"];
        } else {
            return nil;
        }
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
        self.profileImageURL = [NSURL URLWithString:[message valueForKeyPath:@"sender.profile_image_url"]];
        self.text = [self getText:[message valueForKey:@"text"]];
        self.createdAt = [message valueForKey:@"created_at"];
        self.urls = [message valueForKeyPath:@"entities.urls"];
        self.userMentions = [message valueForKeyPath:@"entities.user_mentions"];
        self.hashtags = [message valueForKeyPath:@"entities.hashtags"];
        if ([message valueForKey:@"extended_entities"] != nil) {
            self.media = [message valueForKeyPath:@"extended_entities.media"];
        } else {
            self.media = [message valueForKeyPath:@"entities.media"];
        }
    }
    return self;
}

- (void)setUser:(NSDictionary *)user
{
    self.userID = [user valueForKeyPath:@"id_str"];
    self.screenName = [user valueForKeyPath:@"screen_name"];
    self.displayName = [user valueForKeyPath:@"name"];
    self.profileImageURL = [NSURL URLWithString:[user valueForKeyPath:@"profile_image_url"]];
}

- (void)setStatus:(NSDictionary *)status
{
    self.statusID = [status valueForKey:@"id_str"];
    self.text = [self getText:[status valueForKey:@"text"]];
    self.createdAt = [status valueForKey:@"created_at"];
    self.clientName = [self getClientName:[status valueForKey:@"source"]];
    self.retweetCount = [status valueForKey:@"retweet_count"];
    self.favoriteCount = [status valueForKey:@"favorite_count"];
    self.urls = [status valueForKeyPath:@"entities.urls"];
    self.userMentions = [status valueForKeyPath:@"entities.user_mentions"];
    self.hashtags = [status valueForKeyPath:@"entities.hashtags"];
    if ([status valueForKey:@"extended_entities"] != nil) {
        self.media = [status valueForKeyPath:@"extended_entities.media"];
    } else {
        self.media = [status valueForKeyPath:@"entities.media"];
    }
}

- (void)setActionedUser:(NSDictionary *)user
{
    self.actionedUserID = [user valueForKeyPath:@"id_str"];
    self.actionedScreenName = [user valueForKeyPath:@"screen_name"];
    self.actionedDisplayName = [user valueForKeyPath:@"name"];
    self.actionedProfileImageURL = [NSURL URLWithString:[user valueForKeyPath:@"profile_image_url"]];
}

- (NSString *)getText:(NSString *)text
{
    text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    text = [text stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    return text;
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
    return [NSString stringWithFormat:@"https://twitter.com/%@/status/%@", self.screenName, self.statusID];
}

- (NSURL *)profileImageBiggerURL
{
    return [NSURL URLWithString:[[self.profileImageURL absoluteString] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"]];
}

@end
