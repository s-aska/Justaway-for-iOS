#import "JFIConstants.h"
#import "JFITheme.h"
#import "JFITwitter.h"
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
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:nil];
    
    // フォントサイズ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setFontSize)
                                                 name:JFISetFontSizeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finalizeFontSize)
                                                 name:JFIFinalizeFontSizeNotification
                                               object:nil];
    
    [self setFontSize];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    JFITheme *theme = [JFITheme sharedTheme];
    if (selected) {
        self.backgroundColor = theme.mainHighlightBackgroundColor;
    } else {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.backgroundColor = theme.mainBackgroundColor; }
                         completion:^(BOOL finished){}
         ];
    }
}

// セルにステータスを反映する奴
- (void)setLabelTexts:(JFIEntity *)entity
{
    self.entity = entity;
    
    [self setTheme];
    
    // 表示名
    self.displayNameLabel.text = entity.displayName;
    
    // screen_name
    self.screenNameLabel.text = [@"@" stringByAppendingString:entity.screenName];
    
    // 鍵アイコン
    self.protectedButton.hidden = entity.isProtected ? NO : YES;
    
    // ツイート
    self.statusLabel.text = entity.text;
    
    // 投稿日時
    self.createdAtRelativeLabel.text = [entity.createdAt relativeDescription];
    self.createdAtLabel.text = [entity.createdAt absoluteDescription];
    
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
    
    // RT数
    if ([entity.retweetCount intValue] > 0) {
        self.retweetCountLabel.text = [entity.retweetCount stringValue];
    } else {
        self.retweetCountLabel.text = @"";
    }
    
    // ふぁぼ数
    if ([entity.favoriteCount intValue] > 0) {
        self.favoriteCountLabel.text = [entity.favoriteCount stringValue];
    } else {
        self.favoriteCountLabel.text = @"";
    }
    
    for (UIView* subview in self.imagesView.subviews) {
        [subview removeFromSuperview];
    }
    
    // RT
    if (entity.actionedUserID != nil) {
        NSString *eventName = @"";
        switch (self.entity.type) {
            case EntityTypeFavorite:
                eventName = @"fav";
                break;
                
            case EntityTypeUnFavorite:
                eventName = @"unfav";
                break;
                
            case EntityTypeStatus:
                eventName = @"RT";
                break;
                
            default:
                break;
        }
        self.actionedLabel.text = [NSString stringWithFormat:@"%@ by %@ (@%@)",
                                   eventName,
                                   self.entity.actionedDisplayName,
                                   self.entity.actionedScreenName];
        self.actionedView.hidden = NO;
        self.createdAtLabelHeightConstraint.constant = 21.f;
    } else {
        self.actionedView.hidden = YES;
        self.createdAtLabelHeightConstraint.constant = 5.f;
    }
    
    if ([entity.media count] > 0) {
        self.imagesView.frame = CGRectMake(self.imagesView.frame.origin.x,
                                           self.imagesView.frame.origin.y,
                                           75.f,
                                           [entity.media count] * 80.f);
    }
    
    [self setButtonColor:NO];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    int alpha = delegate.resizing ? 0 : 1;
    self.imagesView.alpha = alpha;
    self.replyButton.alpha = alpha;
    self.retweetCountLabel.alpha = alpha;
    self.retweetButton.alpha = alpha;
    self.favoriteCountLabel.alpha = alpha;
    self.favoriteButton.alpha = alpha;
    self.actionedView.alpha = alpha;
    self.createdAtLabel.alpha = alpha;
    self.sourceLabel.alpha = alpha;
}

- (void)setButtonColor:(BOOL)animated
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [self.favoriteButton setActive:[sharedActionStatus isFavorite:self.entity.statusID] animated:animated];
    if (self.entity.isProtected) {
        [self.retweetButton setEnabled:NO];
        [self.retweetButton setActive:NO animated:NO];
    } else {
        [self.retweetButton setEnabled:YES];
        [self.retweetButton setActive:[sharedActionStatus isRetweetEntity:self.entity] animated:animated];
    }
}

- (void)setTheme
{
    JFITheme *theme = [JFITheme sharedTheme];
    if ([self.themeName isEqualToString:theme.name]) {
        return;
    }
    self.themeName = theme.name;
    [self setBackgroundColor:theme.mainBackgroundColor];
    [self.displayNameLabel setTextColor:theme.displayNameTextColor];
    [self.screenNameLabel setTextColor:theme.screenNameTextColor];
    [self.createdAtRelativeLabel setTextColor:theme.relativeDateTextColor];
    [self.createdAtLabel setTextColor:theme.absoluteDateTextColor];
    [self.sourceLabel setTextColor:theme.clientNameTextColor];
    [self.statusLabel setTextColor:theme.bodyTextColor];
}

- (void)setFontSize
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [self setFontSize:delegate.fontSize];
}

- (void)setFontSize:(float)size
{
    float fontSize = 12 + size;
    if (self.statusLabel.font.pointSize != fontSize) {
        self.statusLabel.font = [UIFont systemFontOfSize:fontSize];
        if (!self.resizing) {
            self.resizing = YES;
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.imagesView.alpha = 0;
                                 self.replyButton.alpha = 0;
                                 self.retweetCountLabel.alpha = 0;
                                 self.retweetButton.alpha = 0;
                                 self.favoriteCountLabel.alpha = 0;
                                 self.favoriteButton.alpha = 0;
                                 self.actionedView.alpha = 0;
                                 self.createdAtLabel.alpha = 0;
                                 self.sourceLabel.alpha = 0;
                             }
                             completion:^(BOOL finished){}
             ];
        }
    }
}


- (void)finalizeFontSize
{
    self.resizing = NO;
    self.imagesView.alpha = 0;
    self.replyButton.alpha = 0;
    self.retweetCountLabel.alpha = 0;
    self.retweetButton.alpha = 0;
    self.favoriteCountLabel.alpha = 0;
    self.favoriteButton.alpha = 0;
    self.actionedView.alpha = 0;
    self.createdAtLabel.alpha = 0;
    self.sourceLabel.alpha = 0;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.imagesView.alpha = 1;
                         self.replyButton.alpha = 1;
                         self.retweetCountLabel.alpha = 1;
                         self.retweetButton.alpha = 1;
                         self.favoriteCountLabel.alpha = 1;
                         self.favoriteButton.alpha = 1;
                         self.actionedView.alpha = 1;
                         self.createdAtLabel.alpha = 1;
                         self.sourceLabel.alpha = 1;
                     }
                     completion:^(BOOL finished){}
     ];
}

- (void)loadImages
{
    JFIEntity *entity = self.entity;
    
    [self loadImage:self.iconImageView imageURL:entity.profileImageBiggerURL processType:ImageProcessTypeIcon];
    
    if (self.entity.actionedProfileImageURL != nil) {
        [self loadImage:self.actionedIconImageView imageURL:entity.actionedProfileImageURL processType:ImageProcessTypeIcon];
    }
    
    if ([entity.media count] > 0) {
        NSInteger tag = 0;
        for (NSDictionary *media in entity.media) {
            NSURL *url = [[NSURL alloc] initWithString:[[media valueForKey:@"media_url"] stringByAppendingString:@":thumb"]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, tag * 80.f + 5.f, 240.f, 75.f)];
            imageView.tag = tag;
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageAction:)];
            tapGesture.numberOfTapsRequired = 1;
            [imageView addGestureRecognizer:tapGesture];
            [self.imagesView addSubview:imageView];
            [self loadImage:imageView imageURL:url processType:ImageProcessTypeThumbnail];
            tag++;
        }
        self.imagesView.frame = CGRectMake(self.imagesView.frame.origin.x,
                                           self.imagesView.frame.origin.y,
                                           75.f,
                                           [entity.media count] * 80.f);
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
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    if ([sharedActionStatus isFavorite:self.entity.statusID]) {
        [JFITwitter destroyFavorite:twitter statusID:self.entity.statusID];
    } else {
        [JFITwitter createFavorite:twitter statusID:self.entity.statusID];
    }
}

- (void)imageAction:(id)sender
{
    UIImageView *imageView = (UIImageView *)[sender view];
    NSInteger tag = imageView.tag;
    NSDictionary *media = self.entity.media[tag];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIOpenImageNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"media": media}];
}

@end
