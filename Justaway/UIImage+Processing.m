#import "UIImage+Processing.h"

@implementation UIImage (Processing)

- (UIImage *)clippedImageWithRect:(CGRect)rect
{
    rect = CGRectMake(rect.origin.x * self.scale,
                      rect.origin.y * self.scale,
                      rect.size.width * self.scale,
                      rect.size.height * self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef
                                         scale:self.scale
                                   orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return image;
}

- (UIImage *)resizedImageForSize:(CGSize)size
{
    // aspect fill
    UIImage *image;
    
    BOOL fitsToWidth = self.size.width / self.size.height < size.width / size.height;
    CGFloat ratio = fitsToWidth ? size.width / self.size.width : size.height / self.size.height;
    CGSize scaledSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, [UIScreen mainScreen].scale);
    [self drawInRect:CGRectMake(0.f, 0.f, scaledSize.width, scaledSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect clippingRect;
    if (fitsToWidth) {
        clippingRect = CGRectMake(0.f, (scaledSize.height - size.height) / 2.f, size.width, size.height);
    } else {
        clippingRect = CGRectMake((scaledSize.width - size.width) / 2.f, 0.f, size.width, size.height);
    }
    return [image clippedImageWithRect:clippingRect];
}

- (UIImage *)resizedImageForSize:(CGSize)size cornerRadius:(CGFloat)radius
{
    UIImage *resizedImage = [self resizedImageForSize:size];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.f);
    
    CGRect rect = CGRectMake(0.f, 0.f, size.width, size.height);
    UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight;
    CGSize radii = CGSizeMake(radius, radius);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:corners
                                                     cornerRadii:radii];
    [path addClip];
    
    [resizedImage drawInRect:rect];
    
    UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbnailImage;
}

@end
