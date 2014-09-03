#import <UIKit/UIKit.h>

@interface JFIProfileViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *profileView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *displayName;
@property (nonatomic, weak) IBOutlet UILabel *scrennName;
@property (nonatomic, weak) IBOutlet UILabel *followedBy;
@property (nonatomic, weak) IBOutlet UIButton *followButton;
@property (nonatomic, weak) IBOutlet UIView *tabView;
@property (nonatomic, weak) IBOutlet UIView *tabTweetsView;
@property (nonatomic, weak) IBOutlet UIView *tabFollowingView;
@property (nonatomic, weak) IBOutlet UIView *tabFollowersView;
@property (nonatomic, weak) IBOutlet UIView *tabListsView;
@property (nonatomic, weak) IBOutlet UIView *tabFavoritesView;
@property (nonatomic, weak) IBOutlet UILabel *tweetsLabel;
@property (nonatomic, weak) IBOutlet UILabel *followingLabel;
@property (nonatomic, weak) IBOutlet UILabel *followersLabel;
@property (nonatomic, weak) IBOutlet UILabel *listsLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoritesLabel;

@property (nonatomic) NSString *userID;

- (IBAction)closeAction:(id)sender;

@end
