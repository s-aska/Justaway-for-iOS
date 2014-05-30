#import "JFIConstants.h"
#import "JFITwitter.h"
#import "JFIActionStatus.h"

@implementation JFITwitter

+ (void)createFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus setFavorite:statusID];
    [twitter postFavoriteState:YES
                   forStatusID:statusID
                  successBlock:^(NSDictionary *status){
                      
                  }
                    errorBlock:^(NSError *error){
                        // Duplicate
                        if ([error code] != 139) {
                            [sharedActionStatus removeFavorite:statusID];
                        }
                    }];
}

+ (void)destroyFavorite:(STTwitterAPI *)twitter statusID:(NSString *)statusID
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus removeFavorite:statusID];
    [twitter postFavoriteDestroyWithStatusID:statusID
                             includeEntities:nil
                                successBlock:^(NSDictionary *status){
                                }
                                  errorBlock:^(NSError *error){
                                      // Duplicate
                                      if ([error code] != 34) {
                                          [sharedActionStatus setFavorite:statusID];
                                      }
                                  }];
}

+ (void)createRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    [sharedActionStatus setRetweet:statusID];
    [twitter postStatusRetweetWithID:statusID
                        successBlock:^(NSDictionary *status){
                            [sharedActionStatus setRetweetID:statusID statusID:[status objectForKey:@"id_str"]];
                        }
                          errorBlock:^(NSError *error){
                              // Duplicate
                              if ([error code] != 34) {
                                  [sharedActionStatus removeRetweet:statusID];
                              }
                          }];
}

+ (void)destroyRetweet:(STTwitterAPI *)twitter statusID:(NSString *)statusID
{
    JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
    NSString *destroyStatusID = [sharedActionStatus getRetweetID:statusID];
    if (destroyStatusID == nil || [destroyStatusID isEqualToString:@""]) {
        return;
    }
    [sharedActionStatus removeRetweet:statusID];
    [twitter postStatusesDestroy:destroyStatusID
                        trimUser:nil
                    successBlock:^(NSDictionary *status){
                        [[NSNotificationCenter defaultCenter] postNotificationName:JFIDestroyStatusNotification
                                                                            object:[[UIApplication sharedApplication] delegate]
                                                                          userInfo:@{@"status_id": statusID,
                                                                                     @"retweeted_by_me": @(1)}];
                    }
                      errorBlock:^(NSError *error){
                          // Duplicate
                          if ([error code] != 34) {
                              [sharedActionStatus setRetweetID:statusID statusID:destroyStatusID];
                          }
                      }];
}

+ (void)destroyStatus:(STTwitterAPI *)twitter statusID:(NSString *)statusID
{
    [twitter postStatusesDestroy:statusID
                        trimUser:nil
                    successBlock:^(NSDictionary *status){
                        [[NSNotificationCenter defaultCenter] postNotificationName:JFIDestroyStatusNotification
                                                                            object:[[UIApplication sharedApplication] delegate]
                                                                          userInfo:@{@"status_id": statusID}];
                    }
                      errorBlock:^(NSError *error){
                      }];
}

@end
