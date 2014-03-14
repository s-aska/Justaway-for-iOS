#import "NSDate+Justaway.h"

@implementation NSDate (Justaway)

+ (instancetype)dateWithTwitterDate:(NSString *)string
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = NSDateFormatter.new;
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
    });
    
    return [formatter dateFromString:string];
}

- (NSString *)absoluteDescription
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = NSDateFormatter.new;
        formatter.locale = [NSLocale currentLocale];
        formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        formatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    });
    
    return [formatter stringFromDate:self];
}

- (NSString *)relativeDescription
{
    NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:self];
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
