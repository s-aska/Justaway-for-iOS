#import <UIKit/UIKit.h>

@interface UIImage (Processing)

- (UIImage *)resizedImageForSize:(CGSize)size;
- (UIImage *)resizedImageForSize:(CGSize)size cornerRadius:(CGFloat)radius;

@end
