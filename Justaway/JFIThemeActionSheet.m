#import "JFIThemeActionSheet.h"
#import "JFIConstants.h"
#import "JFITheme.h"

@implementation JFIThemeActionSheet

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addButtonWithTitle:@"Dark" action:@selector(dark)];
        [self addButtonWithTitle:@"Light" action:@selector(light)];
        [self addButtonWithTitle:@"Solarized Dark" action:@selector(solarizedDark)];
        [self addButtonWithTitle:@"Solarized Light" action:@selector(solarizedLight)];
        [self addButtonWithTitle:@"Monokai" action:@selector(monokai)];
        self.cancelButtonIndex = [self addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
    }
    return self;
}

- (void)dark
{
    [[JFITheme sharedTheme] setDarkTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)light
{
    [[JFITheme sharedTheme] setLightTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)monokai
{
    [[JFITheme sharedTheme] setMonokaiTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)solarizedDark
{
    [[JFITheme sharedTheme] setSolarizedDarkTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)solarizedLight
{
    [[JFITheme sharedTheme] setSolarizedLightTheme];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

@end
