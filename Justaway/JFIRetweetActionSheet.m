#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFIRetweetActionSheet.h"

@implementation JFIRetweetActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        [self addButtonWithTitle:@"公式RT" action:@selector(retweet)];
        [self addButtonWithTitle:@"引用" action:@selector(quote)];
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
    }
    return self;
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

@end
