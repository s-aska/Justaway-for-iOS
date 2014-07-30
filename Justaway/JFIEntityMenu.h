#import <Foundation/Foundation.h>
#import "JFIEntity.h"

@interface JFIEntityMenu : NSObject

+ (void)loadSettings;
+ (void)saveSettings;
+ (void)showMenu:(JFIEntity *)entity;

@end
