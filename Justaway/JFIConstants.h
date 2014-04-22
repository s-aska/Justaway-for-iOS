
#pragma mark - JFIAccountKeys

extern NSString *const JFIAccountOAuthTokenKey;
extern NSString *const JFIAccountOAuthTokenSecretKey;
extern NSString *const JFIAccountUserIDKey;
extern NSString *const JFIAccountScreenNameKey;
extern NSString *const JFIAccountDisplayNameKey;
extern NSString *const JFIAccountProfileImageURLKey;

#pragma mark - UITableView const

extern NSString *const JFICellID;
extern NSString *const JFICellForHeightID;

#pragma mark - notification const

extern NSString *const JFIReceiveAccessTokenNotification;
extern NSString *const JFIReceiveStatusNotification;
extern NSString *const JFIStreamingConnectNotification;
extern NSString *const JFIStreamingDisconnectNotification;
extern NSString *const JFIEditorNotification;

#pragma mark - keychain const

extern NSString *const JFIAccessTokenService;

typedef NS_ENUM(NSInteger, TabType) {
    TabTypeHome,
    TabTypeNotifications,
    TabTypeMessages,
    TabTypeUserList,
};
