#import "JFIMessageCell.h"
#import "NSDate+Justaway.h"

@implementation JFIMessageCell

+ (NSDictionary *)statusAttribute
{
    return @{ NSForegroundColorAttributeName : [UIColor darkGrayColor],
              NSFontAttributeName : [UIFont systemFontOfSize:12] };
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// セルにステータスを反映する奴
- (void)setLabelTexts:(NSDictionary *)message
{
    // 表示名
    self.displayNameLabel.text = [message valueForKeyPath:@"sender.name"];
    
    // screen_name
    self.screenNameLabel.text = [@"@" stringByAppendingString:[message valueForKeyPath:@"sender.screen_name"]];
    
    // ツイート
    self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:[message valueForKey:@"text"]
                                                                      attributes:JFIMessageCell.statusAttribute];
    
    // 投稿日時
    NSDate *createdAt = [NSDate dateWithTwitterDate:[message valueForKey:@"created_at"]];
    self.createdAtRelativeLabel.text = [createdAt relativeDescription];
    self.createdAtLabel.text = [createdAt absoluteDescription];
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

@end
