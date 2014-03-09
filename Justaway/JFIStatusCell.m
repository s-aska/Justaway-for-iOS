#import "JFIStatusCell.h"

@implementation JFIStatusCell

// ステータス（ツイートメッセージ）のスタイル
// 一時的にここで定義しているが後で移動する
+ (NSDictionary *)statusAttribute
{
    return @{ NSForegroundColorAttributeName : [UIColor darkGrayColor],
              NSFontAttributeName : [UIFont fontWithName:@"Avenir Next" size:12] };
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
- (void) setLabelTexts:(NSDictionary *)status
{
    NSLog(@"-- setLabelTexts ---------------");
    NSLog(@"-- setLabelTexts name:%@", [status valueForKeyPath:@"user.name"]);
    self.displayNameLabel.text = [status valueForKeyPath:@"user.name"];
    self.screenNameLabel.text = [@"@" stringByAppendingString:[status valueForKeyPath:@"user.screen_name"]];
    self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:[status valueForKey:@"text"]
                                                                      attributes:JFIStatusCell.statusAttribute];
    self.createdAtLabel.text = [status valueForKey:@"created_at"];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    NSLog(@"-- layoutSubviews ---------------");
    NSLog(@"-- layoutSubviews height:%f", self.statusLabel.frame.size.height);
    NSLog(@"-- layoutSubviews width:%f", self.statusLabel.frame.size.width);
    
    CGSize statusSize = [self.statusLabel.attributedText boundingRectWithSize:CGSizeMake(self.statusLabel.frame.size.width, MAXFLOAT)
                                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                                      context:nil].size;
    NSLog(@"-- layoutSubviews newHeight:%f", statusSize.height);
    self.statusLabel.frame = CGRectMake(self.statusLabel.frame.origin.x,
                                        self.statusLabel.frame.origin.y,
                                        self.statusLabel.frame.size.width,
                                        statusSize.height);
}

@end
