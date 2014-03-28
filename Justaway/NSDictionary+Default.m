#import "NSDictionary+Default.h"

@implementation NSDictionary (Default)

- (id)objectForKey:(id)key defaultObject:(id)defaultObject
{
    id object = [self objectForKey:key];
    if (object == nil) {
        return defaultObject;
    } else {
        return object;
    }
}

@end
