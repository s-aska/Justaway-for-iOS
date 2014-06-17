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
                            NSLog(@"[createFavorite] error code:%i description:%@", [error code], [error description]);
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
                                          NSLog(@"[destroyFavorite] error code:%i description:%@", [error code], [error description]);
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
                              NSString *duplicate = @"sharing is not permissible for this status";
                              if ([error code] != 34 &&
                                  [[error description] rangeOfString:duplicate].location == NSNotFound) {
                                  [sharedActionStatus removeRetweet:statusID];
                                  NSLog(@"[createRetweet] error code:%i description:%@", [error code], [error description]);
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
                              NSLog(@"[destroyRetweet] error code:%i description:%@", [error code], [error description]);
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

+ (void)quote:(JFIEntity *)entity
{
    NSString *text = [NSString stringWithFormat:@" @%@", entity.statusURL];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"range_location": @0,
                                                                 @"range_length": @0}];
}

+ (void)reply:(JFIEntity *)entity
{
    NSString *text = [NSString stringWithFormat:@"@%@ ", entity.screenName];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"in_reply_to_status_id": entity.statusID}];
}

@end
