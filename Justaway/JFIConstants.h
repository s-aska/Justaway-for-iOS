
#pragma mark - JFIAccountKeys

extern NSString *const JFIAccountOAuthTokenKey;
extern NSString *const JFIAccountOAuthTokenSecretKey;
extern NSString *const JFIAccountUserIDKey;
extern NSString *const JFIAccountScreenNameKey;
extern NSString *const JFIAccountDisplayNameKey;
extern NSString *const JFIAccountProfileImageURLKey;

#pragma mark - UITableView

extern NSString *const JFICellID;
extern NSString *const JFICellForHeightID;

#pragma mark - NSNotification

extern NSString *const JFIReceiveAccessTokenNotification;
extern NSString *const JFIReceiveStatusNotification;
extern NSString *const JFIStreamingConnectNotification;
extern NSString *const JFIStreamingDisconnectNotification;
extern NSString *const JFIEditorNotification;
extern NSString *const JFIOpenStatusNotification;

#pragma mark - keychain const

extern NSString *const JFIAccessTokenService;

#pragma mark - Regexp

extern NSString *const JFIURLPattern;

#pragma mark - ENUM

typedef NS_ENUM(NSInteger, TabType) {
    TabTypeHome,
    TabTypeNotifications,
    TabTypeMessages,
    TabTypeUserList,
};

typedef NS_ENUM(NSInteger, EntityType) {
    EntityTypeStatus,
    EntityTypeFavorite,
    EntityTypeMessage,
};
