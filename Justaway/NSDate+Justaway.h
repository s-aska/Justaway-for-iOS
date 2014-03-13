#import <Foundation/Foundation.h>

@interface NSDate (Justaway)

+ (instancetype)dateWithString:(NSString *)string;
- (NSString *)absoluteDescription;
- (NSString *)relativeDescription;

@end
