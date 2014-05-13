#import "JFITab.h"
#import "JFIHomeViewController.h"
#import "JFINotificationsViewController.h"
#import "JFIMessagesViewController.h"

@implementation JFITab

- (JFITab *)initWithType:(TabType)tabType
{
    self = [super init];
    if (self) {
        self.tabType = tabType;
    }
    return self;
}

- (JFITabViewController *)loadViewConroller
{
    switch (self.tabType) {
        case TabTypeHome:
            return [[JFIHomeViewController alloc] initWithType:self.tabType];
            break;
        case TabTypeNotifications:
            return [[JFINotificationsViewController alloc] initWithType:self.tabType];
            break;
        case TabTypeMessages:
            return [[JFIMessagesViewController alloc] initWithType:self.tabType];
            break;
            
        default:
            break;
    }
    return nil;
}

@end
