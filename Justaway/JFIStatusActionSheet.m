#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIStatusActionSheet.h"

@implementation JFIStatusActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        [self addButtonWithTitle:@"公式RT" action:@selector(retweet)];
        [self addButtonWithTitle:@"ふぁぼ" action:@selector(favorite)];
        [self addButtonWithTitle:@"ふぁぼ＆公式RT" action:@selector(favoriteRetweet)];
        [self addButtonWithTitle:@"引用" action:@selector(quote)];
        [self addButtonWithTitle:@"リプ" action:@selector(reply)];
        for (NSDictionary *url in entity.urls) {
            [self addButtonWithTitle:[url objectForKey:@"display_url"]
                              action:@selector(openURL:)
                              object:[[NSURL alloc] initWithString:[url objectForKey:@"expanded_url"]]];
        }
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
        NSLog(@"cancelButtonIndex:%i", self.cancelButtonIndex);
    }
    return self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFICloseStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)favoriteRetweet
{
    [self favorite];
    [self retweet];
}

- (void)retweet
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    // [self.retweetButton setTitleColor:[JFITheme greenDark] forState:UIControlStateNormal];
    [twitter postStatusRetweetWithID:self.entity.statusID
                        successBlock:^(NSDictionary *status){
                        }
                          errorBlock:^(NSError *error){
                              // TODO: エラーコードを見て重複以外がエラーだったら色を戻す
                          }];
}

- (void)quote
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": self.entity.statusURL,
                                                                 @"range_location": @0,
                                                                 @"range_length": @0}];
}

- (void)favorite
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus setFavorite:self.entity.statusID];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter postFavoriteState:YES
                   forStatusID:self.entity.statusID
                  successBlock:^(NSDictionary *status){
                      
                  }
                    errorBlock:^(NSError *error){
                        // TODO: エラーコードを見て重複以外がエラーだったら色を戻す
                        [sharedActionStatus removeFavorite:self.entity.statusID];
                        /*
                        [self.favoriteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                         */
                    }];
}

- (void)reply
{
    NSString *text = [NSString stringWithFormat:@"@%@ ", self.entity.screenName];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"in_reply_to_status_id": self.entity.statusID}];
}

- (void)openURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

@end
