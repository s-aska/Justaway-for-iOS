#import "JFIStatusCell.h"
#import "NSDateFormatter+STTwitter.h"

static NSDateFormatter *absoluteFormatter = nil;

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
    
    // via名
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
    
    // 投稿日時
    NSDate *created_at = [NSDateFormatter.stTwitterDateFormatter dateFromString:[status valueForKey:@"created_at"]];
    self.createdAtRelativeLabel.text = [self getRelativeFromDate:created_at];
    self.createdAtLabel.text = [self getAbsoluteFromDate:created_at];
}

- (void) layoutSubviews
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

- (NSString *)getAbsoluteFromDate:(NSDate *)date
{
    if (absoluteFormatter == nil) {
        absoluteFormatter = NSDateFormatter.new;
        absoluteFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
        absoluteFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    }
    return [absoluteFormatter stringFromDate:date];
}

- (NSString *)getRelativeFromDate:(NSDate *)date
{
    NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:date];
    if (diff < 1) {
        return @"now";
    } else if (diff < 60) {
        return [NSString stringWithFormat:@"%ds", (int) diff];
    } else if (diff < 3600) {
        return [NSString stringWithFormat:@"%dm", (int) (diff / 60)];
    } else if (diff < 86400) {
        return [NSString stringWithFormat:@"%dh", (int) (diff / 3600)];
    } else {
        return [NSString stringWithFormat:@"%dd", (int) (diff / 86400)];
    }
}

@end
