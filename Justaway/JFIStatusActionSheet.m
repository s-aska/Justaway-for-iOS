#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIStatusActionSheet.h"
#import "JFIAccount.h"

@implementation JFIStatusActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        JFIAccount *account = [delegate.accounts objectAtIndex:delegate.currentAccountIndex];
        if ([account.userID isEqualToString:entity.userID]) {
            [self addButtonWithTitle:@"ツイ消し" action:@selector(destroyStatus)];
        }
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
        for (NSDictionary *url in entity.media) {
            [self addButtonWithTitle:[url objectForKey:@"display_url"]
                              action:@selector(openURL:)
                              object:[[NSURL alloc] initWithString:[url objectForKey:@"media_url"]]];
        }
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
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
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus setRetweet:self.entity.statusID];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
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

- (void)destroyStatus
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter postStatusesDestroy:self.entity.statusID
                        trimUser:nil
                    successBlock:^(NSDictionary *status){
                        [[NSNotificationCenter defaultCenter] postNotificationName:JFIDestroyStatusNotification
                                                                            object:delegate
                                                                          userInfo:@{@"status_id": self.entity.statusID}];
                    }
                      errorBlock:^(NSError *error){
                      }];
}

@end
