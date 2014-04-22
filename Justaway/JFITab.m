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
    NSString *nibName = NSStringFromClass([JFITabViewController class]);
    switch (self.tabType) {
        case TabTypeHome:
            return [[JFIHomeViewController alloc] initWithNibName:nibName
                                                           bundle:nil
                                                          tabType:self.tabType];
            break;
        case TabTypeNotifications:
            return [[JFINotificationsViewController alloc] initWithNibName:nibName
                                                                    bundle:nil
                                                                   tabType:self.tabType];
            break;
        case TabTypeMessages:
            return [[JFIMessagesViewController alloc] initWithNibName:nibName
                                                               bundle:nil
                                                              tabType:self.tabType];
            break;
            
        default:
            break;
    }
    return nil;
}

@end
