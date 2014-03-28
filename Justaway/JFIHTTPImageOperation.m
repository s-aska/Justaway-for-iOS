#import "JFIHTTPImageOperation.h"
#import <ISMemoryCache/ISMemoryCache.h>
#import <ISDiskCache/ISDiskCache.h>

@interface JFIHTTPImageOperation ()

@property (nonatomic) NSData *data;
@property (nonatomic) NSHTTPURLResponse *response;

@end

@implementation JFIHTTPImageOperation

+ (void)loadURL:(NSURL *)URL handler:(void (^)(NSHTTPURLResponse *, UIImage *, NSError *))handler
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    JFIHTTPImageOperation *operation = [[JFIHTTPImageOperation alloc] initWithRequest:request
                                                                              handler:handler];
    operation.queuePriority = 0;
    [[ISHTTPOperationQueue defaultQueue] addOperation:operation];
}

- (NSURL *)cacheKey
{
    return self.request.URL;
}

- (void)main
{
    @autoreleasepool {
        ISMemoryCache *memoryCache = [ISMemoryCache sharedCache];
        UIImage *cachedImage = [memoryCache objectForKey:self.cacheKey];
        
        if (cachedImage) {
            [memoryCache setObject:cachedImage forKey:self.cacheKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.handler) {
                    self.handler(nil, cachedImage, nil);
                }
            });
            [self completeOperation];
            
            return;
        }
    }
    [super main];
}

- (id)processData:(NSData *)data
{
    UIImage *image = [UIImage imageWithData:data];
    
    ISMemoryCache *memoryCache = [ISMemoryCache sharedCache];
    ISDiskCache *diskCache = [ISDiskCache sharedCache];
    
    [memoryCache setObject:image forKey:self.cacheKey];
    [diskCache setObject:image forKey:self.cacheKey];
    
    return image;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id object = [self processData:self.data];
    if (object && self.handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.handler(self.response, object, nil);
        });
    }
    
    [self completeOperation];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self completeOperation];
}

@end
