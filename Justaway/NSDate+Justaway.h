#import <Foundation/Foundation.h>

@interface NSDate (Justaway)

+ (instancetype)dateWithTwitterDate:(NSString *)string;
- (NSString *)absoluteDescription;
- (NSString *)relativeDescription;

@end
