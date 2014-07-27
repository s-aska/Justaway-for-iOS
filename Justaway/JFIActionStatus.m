#import "JFIActionStatus.h"
#import "JFIConstants.h"

@interface JFIActionStatus ()

@property (nonatomic) NSMutableDictionary *favoriteDictionary;
@property (nonatomic) NSMutableDictionary *retweetDictionary;

@end

@implementation JFIActionStatus

+ (JFIActionStatus *)sharedActionStatus
{
    static JFIActionStatus *actionStatus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        actionStatus = [[JFIActionStatus alloc] init];
    });
    
    return actionStatus;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.favoriteDictionary = [NSMutableDictionary dictionary];
        self.retweetDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isFavorite:(NSString *)originalStatusID
{
    return [self.favoriteDictionary objectForKey:originalStatusID] != nil ? YES : NO;
}

- (void)setFavorite:(NSString *)originalStatusID
{
    [self.favoriteDictionary setObject:@(1) forKey:originalStatusID];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIActionStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)removeFavorite:(NSString *)originalStatusID
{
    [self.favoriteDictionary removeObjectForKey:originalStatusID];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIActionStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (BOOL)isRetweet:(NSString *)originalStatusID
{
    return [self.retweetDictionary objectForKey:originalStatusID] != nil ? YES : NO;
}

- (BOOL)isRetweetEntity:(JFIEntity *)entity
{
    // 直接RT
    if ([self isRetweet:entity.statusID]) {
        return YES;
    }
    // RTをRT
    if (entity.referenceStatusID != nil && [self isRetweet:entity.referenceStatusID]) {
        return YES;
    }
    return NO;
}

- (NSString *)getRetweetID:(NSString *)originalStatusID
{
    return [self.retweetDictionary objectForKey:originalStatusID];
}

- (NSArray *)getRetweetOriginalStatusIDs:(NSString *)referenceStatusID
{
    return [self.retweetDictionary allKeysForObject:referenceStatusID];
}

- (void)setRetweet:(NSString *)originalStatusID
{
    [self.retweetDictionary setObject:@"" forKey:originalStatusID];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIActionStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)setRetweetID:(NSString *)originalStatusID statusID:(NSString *)referenceStatusID
{
    [self.retweetDictionary setObject:referenceStatusID forKey:originalStatusID];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIActionStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)removeRetweet:(NSString *)originalStatusID
{
    if ([self.retweetDictionary objectForKey:originalStatusID] == nil) {
        return;
    }
    [self.retweetDictionary removeObjectForKey:originalStatusID];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIActionStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

@end
