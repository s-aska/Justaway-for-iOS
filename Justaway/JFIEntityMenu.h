#import <Foundation/Foundation.h>
#import "JFIEntity.h"

@interface JFIEntityMenu : NSObject

+ (NSArray *)loadSettings;
+ (void)saveSettings:(NSArray *)newMenus;
+ (void)showMenu:(JFIEntity *)entity;

@end
