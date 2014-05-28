#import "JFIConstants.h"
#import "ISHTTPOperation.h"

@interface JFIHTTPImageOperation : ISHTTPOperation

@property (nonatomic, readonly) NSURL *cacheKey;

+ (void)loadURL:(NSURL *)URL processType:(ImageProcessType)processType handler:(void (^)(NSHTTPURLResponse *response, UIImage *image, NSError *error))handler;

@end
