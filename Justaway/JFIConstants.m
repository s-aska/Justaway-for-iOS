
#pragma mark - JFIAccountKeys

NSString *const JFIAccountOAuthTokenKey       = @"oauthToken";
NSString *const JFIAccountOAuthTokenSecretKey = @"oauthTokenSecret";
NSString *const JFIAccountUserIDKey           = @"userID";
NSString *const JFIAccountScreenNameKey       = @"screenName";
NSString *const JFIAccountDisplayNameKey      = @"displayName";
NSString *const JFIAccountProfileImageURLKey  = @"profileImageUrl";
NSString *const JFIAccountPriorityKey         = @"priority";

#pragma mark - JFIEntityMenuKeys

NSString *const JFIEntityMenuIDKey       = @"id";
NSString *const JFIEntityMenuSelectorKey = @"selector";
NSString *const JFIEntityMenuEnableKey   = @"enable";
NSString *const JFIEntityMenuPriorityKey = @"priority";

#pragma mark - UITableView const

NSString *const JFICellID          = @"JFICellID";
NSString *const JFICellForHeightID = @"JFICellForHeightID";

#pragma mark - notification const

NSString *const JFISetThemeNotification            = @"JFISetThemeNotification";
NSString *const JFISetFontSizeNotification         = @"JFISetFontSizeNotification";
NSString *const JFIApplyFontSizeNotification       = @"JFIApplyFontSizeNotification";
NSString *const JFIFinalizeFontSizeNotification    = @"JFIFinalizeFontSizeNotification";
NSString *const JFISelectAccessTokenNotification   = @"JFISelectAccessTokenNotification";
NSString *const JFIReceiveAccessTokenNotification  = @"JFIReceiveAccessTokenNotification";
NSString *const JFIRefreshAccessTokenNotification  = @"JFIRefreshAccessTokenNotification";
NSString *const JFIReceiveStatusNotification       = @"JFIReceiveStatusNotification";
NSString *const JFIReceiveMessageNotification      = @"JFIReceiveMessageNotification";
NSString *const JFIReceiveEventNotification        = @"JFIReceiveEventNotification";
NSString *const JFIStreamingConnectionNotification = @"JFIStreamingConnectionNotification";
NSString *const JFIEditorNotification              = @"JFIEditorNotification";
NSString *const JFICloseStatusNotification         = @"JFICloseStatusNotification";
NSString *const JFIActionStatusNotification        = @"JFIActionStatusNotification";
NSString *const JFIDestroyStatusNotification       = @"JFIDestroyStatusNotification";
NSString *const JFIDestroyMessageNotification      = @"JFIDestroyMessageNotification";
NSString *const JFIOpenImageNotification           = @"JFIOpenImageNotification";

#pragma mark - keychain const

NSString *const JFIAccessTokenService = @"JustawayService";

#pragma mark - Regexp

NSString *const JFIURLPattern = @"(?:http://|https://)[\\w/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+";

#pragma mark - Interval

CGFloat const JFIFinalizeInterval = .1f;
