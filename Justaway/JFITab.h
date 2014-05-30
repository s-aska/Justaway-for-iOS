#import <Foundation/Foundation.h>
#import "JFITabViewController.h"

@interface JFITab : NSObject

@property (nonatomic) TabType tabType;
@property (nonatomic) NSDictionary *options;

- (JFITab *)initWithType:(TabType)tabType;
- (JFITabViewController *)loadViewConroller;
- (NSString *)title;

@end
