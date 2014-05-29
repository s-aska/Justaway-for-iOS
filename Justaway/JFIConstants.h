
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

extern NSString *const JFISelectAccessTokenNotification;
extern NSString *const JFIReceiveAccessTokenNotification;
extern NSString *const JFIReceiveStatusNotification;
extern NSString *const JFIStreamingConnectionNotification;
extern NSString *const JFIEditorNotification;
extern NSString *const JFIOpenStatusNotification;
extern NSString *const JFICloseStatusNotification;

#pragma mark - keychain const

extern NSString *const JFIAccessTokenService;

#pragma mark - Regexp

extern NSString *const JFIURLPattern;

#pragma mark - ENUM

typedef NS_ENUM(NSInteger, ImageProcessType) {
    ImageProcessTypeIcon,
    ImageProcessTypeThumbnail,
};

typedef NS_ENUM(NSInteger, StreamingStatus) {
    StreamingConnecting,
    StreamingConnected,
    StreamingDisconnecting,
    StreamingDisconnected,
};

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
