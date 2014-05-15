#import "JFIConstants.h"
#import "JFITheme.h"
#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIRetweetActionSheet.h"
#import "JFIEntityCell.h"
#import "JFIHTTPImageOperation.h"
#import "NSDate+Justaway.h"
#import <ISMemoryCache/ISMemoryCache.h>

@implementation JFIEntityCell

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
- (void)setLabelTexts:(JFIEntity *)entity
{
    self.entity = entity;
    
    // 表示名
    self.displayNameLabel.text = entity.displayName;
    
    // screen_name
    self.screenNameLabel.text = [@"@" stringByAppendingString:entity.screenName];
    
    // ツイート
    self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:entity.text
                                                                      attributes:JFIEntityCell.statusAttribute];
    
    // 投稿日時
    NSDate *createdAt = [NSDate dateWithTwitterDate:entity.createdAt];
    self.createdAtRelativeLabel.text = [createdAt relativeDescription];
    self.createdAtLabel.text = [createdAt absoluteDescription];
    
    if (entity.type == EntityTypeMessage) {
        self.retweetCountLabel.hidden = YES;
        self.retweetButton.hidden = YES;
        self.favoriteCountLabel.hidden = YES;
        self.favoriteButton.hidden = YES;
        return;
    }
    
    // via名
    self.sourceLabel.text = entity.clientName;
    
    // RT状態
    [self.replyButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.retweetButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    // RT数
    if (entity.retweetCount > 0) {
        self.retweetCountLabel.text = [entity.retweetCount stringValue];
    } else {
        self.retweetCountLabel.text = @"";
    }
    
    // ふぁぼ状態
    [self.favoriteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    // ふぁぼ数
    if (entity.favoriteCount > 0) {
        self.favoriteCountLabel.text = [entity.favoriteCount stringValue];
    } else {
        self.favoriteCountLabel.text = @"";
    }
    
    // RT
    if (entity.actionedUserID != nil) {
        self.actionedLabel.text = [NSString stringWithFormat:@"RT by %@ (@%@)", self.entity.actionedDisplayName, self.entity.actionedScreenName];
        self.actionedView.hidden = NO;
        self.createdAtLabelHeightConstraint.constant = 21.f;
    } else {
        self.actionedView.hidden = YES;
        self.createdAtLabelHeightConstraint.constant = 5.f;
    }
}

- (void)loadImages:(BOOL)scrolling
{
    JFIEntity *tweet = self.entity;
    
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    JFITheme *theme = [JFITheme sharedTheme];
    
    [theme setColorForFavoriteButton:self.favoriteButton active:[sharedActionStatus isFavorite:tweet.statusID]];
    [theme setColorForRetweetButton:self.retweetButton active:[sharedActionStatus isRetweet:tweet.statusID]];
    
    [self loadImage:self.iconImageView imageURL:tweet.profileImageURL];
    
    if (self.entity.actionedProfileImageURL != nil) {
        [self loadImage:self.actionedIconImageView imageURL:tweet.actionedProfileImageURL];
    }
}

- (void)loadImage:(UIImageView *)imageView imageURL:(NSURL *)imageURL
{
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:imageURL];
    if (image) {
        imageView.image = image;
    } else {
        imageView.image = nil;
        NSString *statusID = self.entity.statusID;
        [JFIHTTPImageOperation loadURL:imageURL
                               handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                                   // 読み込みから表示までの間にスクロールなどによって表示内容が変わっている場合スキップ
                                   if (self.entity.statusID != statusID) {
                                       return;
                                   }
                                   // 読み込み済の場合スキップ（瞬き防止）
                                   if (imageView.image != nil) {
                                       return;
                                   }
                                   // ネットワークからの読み込み時のみフェードイン
                                   if (response) {
                                       imageView.alpha = 0;
                                       imageView.image = image;
                                       [UIView animateWithDuration:0.2
                                                             delay:0
                                                           options:UIViewAnimationOptionCurveEaseIn
                                                        animations:^{ imageView.alpha = 1; }
                                                        completion:^(BOOL finished){}
                                        ];
                                   } else {
                                       imageView.image = image;
                                   }
                               }];
    }
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

- (IBAction)replyAction:(id)sender
{
    NSString *text = [NSString stringWithFormat:@"@%@ ", self.entity.screenName];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"in_reply_to_status_id": self.entity.statusID}];
}

- (IBAction)retweetAction:(id)sender
{
    [[[JFIRetweetActionSheet alloc] initWithEntity:self.entity] showInView:self.contentView];
}

- (IBAction)favoriteAction:(id)sender
{
    [self.favoriteButton setTitleColor:[JFITheme orangeDark] forState:UIControlStateNormal];
    
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
                        [self.favoriteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    }];
}

@end
