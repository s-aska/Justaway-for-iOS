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

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        self.backgroundColor = [UIColor darkGrayColor];
    } else {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.backgroundColor = [UIColor blackColor]; }
                         completion:^(BOOL finished){}
         ];
    }
}

// セルにステータスを反映する奴
- (void)setLabelTexts:(JFIEntity *)entity
{
    self.entity = entity;
//    JFIEntityCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    // 表示名
    self.displayNameLabel.text = entity.displayName;
    
    // screen_name
    self.screenNameLabel.text = [@"@" stringByAppendingString:entity.screenName];
    
    // ツイート
    self.statusLabel.text = entity.text;
    
    // 投稿日時
    NSDate *createdAt = [NSDate dateWithTwitterDate:entity.createdAt];
    self.createdAtRelativeLabel.text = [createdAt relativeDescription];
    self.createdAtLabel.text = [createdAt absoluteDescription];
    
    if (entity.type == EntityTypeMessage) {
        self.retweetCountLabel.hidden = YES;
        self.retweetButton.hidden = YES;
        self.favoriteCountLabel.hidden = YES;
        self.favoriteButton.hidden = YES;
        self.actionedView.hidden = YES;
        self.createdAtLabelHeightConstraint.constant = 5.f;
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
    
    for (UIView* subview in self.imagesView.subviews) {
        [subview removeFromSuperview];
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
    JFIEntity *entity = self.entity;
    
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    JFITheme *theme = [JFITheme sharedTheme];
    
    [theme setColorForFavoriteButton:self.favoriteButton active:[sharedActionStatus isFavorite:entity.statusID]];
    [theme setColorForRetweetButton:self.retweetButton active:[sharedActionStatus isRetweet:entity.statusID]];
    
    [self loadImage:self.iconImageView imageURL:entity.profileImageBiggerURL processType:ImageProcessTypeIcon];
    
    if (self.entity.actionedProfileImageURL != nil) {
        [self loadImage:self.actionedIconImageView imageURL:entity.actionedProfileImageURL processType:ImageProcessTypeIcon];
    }
    
    if ([entity.media count] > 0) {
        for (NSDictionary *media in entity.media) {
            NSURL *url = [[NSURL alloc] initWithString:[[media valueForKey:@"media_url"] stringByAppendingString:@":thumb"]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75.f, 75.f)];
            [self.imagesView addSubview:imageView];
            [self loadImage:imageView imageURL:url processType:ImageProcessTypeThumbnail];
        }
        self.imagesView.frame = CGRectMake(self.imagesView.frame.origin.x,
                                           self.imagesView.frame.origin.y,
                                           75.f,
                                           [entity.media count] * 75 + 5);
    }
}

- (void)loadImage:(UIImageView *)imageView imageURL:(NSURL *)imageURL processType:(ImageProcessType)processType
{
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:imageURL];
    if (image) {
        imageView.image = image;
    } else {
        imageView.image = nil;
        NSString *statusID = self.entity.statusID;
        [JFIHTTPImageOperation loadURL:imageURL
                           processType:processType
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

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    
}

- (IBAction)replyAction:(id)sender
{
    NSDictionary *userInfo;
    if (self.entity.type == EntityTypeMessage) {
        userInfo = @{@"text": [NSString stringWithFormat:@"D %@ ", self.entity.screenName],
                     @"in_reply_to_status_id": @""};
    } else {
        userInfo = @{@"text": [NSString stringWithFormat:@"@%@ ", self.entity.screenName],
                     @"in_reply_to_status_id": self.entity.statusID};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:userInfo];
}

- (IBAction)retweetAction:(id)sender
{
    [[[JFIRetweetActionSheet alloc] initWithEntity:self.entity] showInView:self.contentView];
}

- (IBAction)favoriteAction:(id)sender
{
    [self.favoriteButton setTitleColor:[JFITheme orangeLight] forState:UIControlStateNormal];
    
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
