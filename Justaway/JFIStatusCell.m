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
- (void)setLabelTexts:(NSDictionary *)status
{
    NSLog(@"-- setLabelTexts ---------------");
    NSLog(@"-- setLabelTexts name:%@", [status valueForKeyPath:@"user.name"]);
    self.displayNameLabel.text = [status valueForKeyPath:@"user.name"];
    self.screenNameLabel.text = [@"@" stringByAppendingString:[status valueForKeyPath:@"user.screen_name"]];
    self.statusLabel.attributedText = [[NSAttributedString alloc] initWithString:[status valueForKey:@"text"]
                                                                      attributes:JFIStatusCell.statusAttribute];

    // NsDate => NSString変換用のフォーマッタを作成

//    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]]; // Localeの指定
//    [df setDateFormat:];
    
    // 日付(NSDate) => 文字列(NSString)に変換
//    NSDate *now = [NSDate date];
//    NSString *strNow = [df stringFromDate:now];
    
    
    
    
    
    NSString *source = [status valueForKey:@"source"];
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"rel=\"nofollow\">(.+)</a>" options:0 error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
    } else {
        NSTextCheckingResult *match = [regexp firstMatchInString:source options:0 range:NSMakeRange(0, source.length)];
        if (match.numberOfRanges > 0) {
            self.sourceLabel.text = [source substringWithRange:[match rangeAtIndex:1]];
        } else {
            self.sourceLabel.text = source;
        }
    }

    //
    NSDateFormatter *formatterFromString = NSDateFormatter.new;
    formatterFromString.dateFormat = @"E MMM dd HH:mm:ss z yyyy";
    NSDate *created_at = [formatterFromString dateFromString:[status valueForKey:@"created_at"]];

    NSDateFormatter *formatterToString = NSDateFormatter.new;
    formatterToString.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    formatterToString.dateFormat = @"yyyy/MM/dd HH:mm:ss";

    self.createdAtRelativeLabel.text = [self getRelativeTime:created_at];
    self.createdAtLabel.text = [formatterToString stringFromDate:created_at];
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

- (NSString *)getRelativeTime:(NSDate *)date
{
    float diff = [[NSDate date] timeIntervalSinceDate:date];
    if (diff < 1) {
        return @"now";
    } else if (diff < 60) {
        return [NSString stringWithFormat:@"%.0fs", diff];
    } else if (diff < 3600) {
        return [NSString stringWithFormat:@"%.0fm", (diff / 60)];
    } else if (diff < 86400) {
        return [NSString stringWithFormat:@"%.0fh", (diff / 3600)];
    } else {
        return [NSString stringWithFormat:@"%.0fd", (diff / 86400)];
    }
}

@end
