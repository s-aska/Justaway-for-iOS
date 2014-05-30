
#pragma mark - JFIAccountKeys

NSString *const JFIAccountOAuthTokenKey       = @"oauthToken";
NSString *const JFIAccountOAuthTokenSecretKey = @"oauthTokenSecret";
NSString *const JFIAccountUserIDKey           = @"userID";
NSString *const JFIAccountScreenNameKey       = @"screenName";
NSString *const JFIAccountDisplayNameKey      = @"displayName";
NSString *const JFIAccountProfileImageURLKey  = @"profileImageUrl";

#pragma mark - UITableView const

NSString *const JFICellID          = @"JFICellID";
NSString *const JFICellForHeightID = @"JFICellForHeightID";

#pragma mark - notification const

NSString *const JFISelectAccessTokenNotification   = @"JFISelectAccessTokenNotification";
NSString *const JFIReceiveAccessTokenNotification  = @"JFIReceiveAccessTokenNotification";
NSString *const JFIReceiveStatusNotification       = @"JFIReceiveStatusNotification";
NSString *const JFIStreamingConnectionNotification = @"JFIStreamingConnectionNotification";
NSString *const JFIEditorNotification              = @"JFIEditorNotification";
NSString *const JFIOpenStatusNotification          = @"JFIOpenStatusNotification";
NSString *const JFICloseStatusNotification         = @"JFICloseStatusNotification";
NSString *const JFIActionStatusNotification        = @"JFIActionStatusNotification";

#pragma mark - keychain const

NSString *const JFIAccessTokenService = @"JustawayService";

#pragma mark - Regexp

NSString *const JFIURLPattern = @"(?:http://|https://)[\\w/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+";
