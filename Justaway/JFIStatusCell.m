#import "JFIConstants.h"
#import "JFITheme.h"
#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIStatusCell.h"
#import "JFIHTTPImageOperation.h"
#import "NSDate+Justaway.h"
#import <ISMemoryCache/ISMemoryCache.h>

@implementation JFIStatusCell

typedef NS_ENUM(char, Type) {
    ButtonIndexRetweet = 0,
    ButtonIndexQuote   = 1,
};

// ステータス（ツイートメッセージ）のスタイル
// 一時的にここで定義しているが後で移動する
+ (NSDictionary *)statusAttribute
{
    return @{ NSForegroundColorAttributeName : [UIColor darkGrayColor],
              NSFontAttributeName : [UIFont systemFontOfSize:12] };
}

// 自動生成されたやつ
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

// 自動生成されたやつ
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// セルにステータスを反映する奴
- (void)setLabelTexts:(NSDictionary *)status
{
    self.status = status;
    
    // 表示名
    self.displayNameLabel.text = [status valueForKeyPath:@"user.name"];
    
    // screen_name
    self.screenNameLabel.text = [@"@" stringByAppendingString:[status valueForKeyPath:@"user.screen_name"]];
    
    // ツイート
    self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:[status valueForKey:@"text"]
                                                                      attributes:JFIStatusCell.statusAttribute];
    
    // via名
    self.sourceLabel.text = [self getClientNameFromSource:[status valueForKey:@"source"]];
    
    // 投稿日時
    NSDate *createdAt = [NSDate dateWithTwitterDate:[status valueForKey:@"created_at"]];
    self.createdAtRelativeLabel.text = [createdAt relativeDescription];
    self.createdAtLabel.text = [createdAt absoluteDescription];
    
    if ([status valueForKey:@"is_message"] != nil) {
        self.retweetCountLabel.hidden = YES;
        self.retweetButton.hidden = YES;
        self.favoriteCountLabel.hidden = YES;
        self.favoriteButton.hidden = YES;
        return;
    }
    
    // RT状態
    [self.replyButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.retweetButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    // RT数
    if ([status valueForKey:@"retweet_count"] > 0) {
        self.retweetCountLabel.text = [[status valueForKey:@"retweet_count"] stringValue];
    } else {
        self.retweetCountLabel.text = @"";
    }
    
    // ふぁぼ状態
    [self.favoriteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    // ふぁぼ数
    if ([status valueForKey:@"favorite_count"] > 0) {
        self.favoriteCountLabel.text = [[status valueForKey:@"favorite_count"] stringValue];
    } else {
        self.favoriteCountLabel.text = @"";
    }
}

- (void)loadImages:(BOOL)scrolling
{
    NSDictionary *status = self.status;
    
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    JFITheme *theme = [JFITheme sharedTheme];
    
    NSString *statusId = [status objectForKey:@"id_str"];
    [theme setColorForFavoriteButton:self.favoriteButton active:[sharedActionStatus isFavorite:statusId]];
    [theme setColorForRetweetButton:self.retweetButton active:[sharedActionStatus isRetweet:statusId]];
    
    NSURL *url = [NSURL URLWithString:[status valueForKeyPath:@"user.profile_image_url"]];
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:url];
    if (image) {
        self.iconImageView.image = image;
        return;
    }
    
    self.iconImageView.image = nil;
    
    [JFIHTTPImageOperation loadURL:url
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               // 読み込みから表示までの間にスクロールなどによって表示内容が変わっている場合スキップ
                               if (self.status != status) {
                                   return;
                               }
                               // 読み込み済の場合スキップ（瞬き防止）
                               if (self.iconImageView.image != nil) {
                                   return;
                               }
                               // ネットワークからの読み込み時のみフェードイン
                               if (response) {
                                   self.iconImageView.alpha = 0;
                                   self.iconImageView.image = image;
                                   [UIView animateWithDuration:0.2
                                                         delay:0
                                                       options:UIViewAnimationOptionCurveEaseIn
                                                    animations:^{ self.iconImageView.alpha = 1; }
                                                    completion:^(BOOL finished){}
                                    ];
                               } else {
                                   self.iconImageView.image = image;
                               }
                           }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize statusSize = [self.statusLabel.attributedText boundingRectWithSize:CGSizeMake(self.statusLabel.frame.size.width, MAXFLOAT)
                                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                                      context:nil].size;
    
    self.statusLabel.frame = CGRectMake(self.statusLabel.frame.origin.x,
                                        self.statusLabel.frame.origin.y,
                                        self.statusLabel.frame.size.width,
                                        statusSize.height);
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSString *)getClientNameFromSource:(NSString *)source
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

- (IBAction)replyAction:(id)sender
{
    NSString *text = [NSString stringWithFormat:@"@%@ ", [self.status valueForKeyPath:@"user.screen_name"]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"in_reply_to_status_id": [self.status valueForKey:@"id_str"]}];
}

- (IBAction)retweetAction:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"公式RT"];
    [actionSheet addButtonWithTitle:@"引用"];
    [actionSheet addButtonWithTitle:@"キャンセル"];
    actionSheet.delegate = self;
    actionSheet.tag = 1;
    actionSheet.cancelButtonIndex = 2;
    [actionSheet showInView:self.contentView];
}

- (IBAction)favoriteAction:(id)sender
{
    
    NSString *statusId = [self.status objectForKey:@"id_str"];
    
    [self.favoriteButton setTitleColor:[JFITheme orangeDark] forState:UIControlStateNormal];
    
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus setFavorite:statusId];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter postFavoriteState:YES
                   forStatusID:statusId
                  successBlock:^(NSDictionary *status){
                      
                  }
                    errorBlock:^(NSError *error){
                        // TODO: エラーコードを見て重複以外がエラーだったら色を戻す
                        [sharedActionStatus removeFavorite:statusId];
                        [self.favoriteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //    NSLog(@"clickedButtonAtIndex tag:%i buttonIndex:%i %@", actionSheet.tag, buttonIndex, [self.status valueForKey:@"text"]);
    switch (buttonIndex) {
        case ButtonIndexRetweet:
        {
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [self.retweetButton setTitleColor:[JFITheme greenDark] forState:UIControlStateNormal];
            [twitter postStatusRetweetWithID:[self.status valueForKey:@"id_str"]
                                successBlock:^(NSDictionary *status){
                                }
                                  errorBlock:^(NSError *error){
                                      // TODO: エラーコードを見て重複以外がエラーだったら色を戻す
                                  }];
            break;
        }
        case ButtonIndexQuote:
        {
            NSString *text = [NSString stringWithFormat:@" https://twitter.com/%@/status/%@",
                              [self.status valueForKeyPath:@"user.screen_name"],
                              [self.status valueForKey:@"id_str"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:@{@"text": text,
                                                                         @"range_location": @0,
                                                                         @"range_length": @0}];
            break;
        }
        default:
            break;
    }
}

@end
