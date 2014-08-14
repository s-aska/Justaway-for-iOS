// http://qiita.com/eka2513/items/00c77622bb7b0c24e7df by eka2513

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)colorWithHex:(NSString *)colorCode
{
    return [UIColor colorWithHex:colorCode alpha:1.0];
}

+ (UIColor *)colorWithHex:(NSString *)colorCode alpha:(CGFloat)alpha
{
    unsigned int color;
    [[NSScanner scannerWithString:colorCode] scanHexInt:&color];
    if (!color) {
        return nil;
    }
    CGFloat red = ((color & 0xFF0000) >> 16) / 255.0f;
    CGFloat green = ((color & 0x00FF00) >> 8) / 255.0f;
    CGFloat blue = (color & 0x0000FF) / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
