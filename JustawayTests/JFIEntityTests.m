#import <XCTest/XCTest.h>
#import "JFIEntity.h"

@interface JFIEntityTests : XCTestCase

@end

@implementation JFIEntityTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    NSDictionary *status = @{@"id_str": @"1",
                             @"user.name": @"Shinichiro Aska",
                             @"user.screen_name": @"su_aska",
                             @"text": @"今日は鯖味噌の日。 http://justaway.info/ \n今日は鯖味噌の日。\n今日は鯖味噌の日。 https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png http://tasks.7kai.org/?success=1#top",
                             @"source": @"web",
                             @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                             @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                             @"retweet_count": @10000,
                             @"favorite_count": @20000,
                             @"entities": @{
                                     @"urls": @[@{@"expanded_url": @"https://dev.twitter.com/terms/display-guidelines",
                                                  @"url": @"https://t.co/Ed4omjYs",
                                                  @"display_url": @"dev.twitter.com/terms/display-\u2026"}],
                                     @"user_mentions": @[@"su_aska"],
                                     @"hashtags": @[@"justaway"],
                                     @"media": @[@{@"display_url": @"pic.twitter.com/lX5LVZO",
                                                   @"expanded_url": @"http://twitter.com/fakekurrik/status/244204973972410368/photo/1",
                                                   @"media_url": @"http://pbs.twimg.com/media/A2OXIUcCUAAXj9k.png"}]
                                     }};
    
    JFIEntity *entity = [[JFIEntity alloc] initWithStatus:status];
    
    XCTAssertEqualObjects([[entity.urls objectAtIndex:0] objectForKey:@"expanded_url"], @"https://dev.twitter.com/terms/display-guidelines");
    XCTAssertEqualObjects([[entity.urls objectAtIndex:0] objectForKey:@"display_url"], @"dev.twitter.com/terms/display-\u2026");
    XCTAssertEqualObjects([[entity.urls objectAtIndex:0] objectForKey:@"url"], @"https://t.co/Ed4omjYs");
    XCTAssertEqualObjects([[entity.media objectAtIndex:0] objectForKey:@"display_url"], @"pic.twitter.com/lX5LVZO");
    XCTAssertEqualObjects([[entity.media objectAtIndex:0] objectForKey:@"expanded_url"], @"http://twitter.com/fakekurrik/status/244204973972410368/photo/1");
    XCTAssertEqualObjects([[entity.media objectAtIndex:0] objectForKey:@"media_url"], @"http://pbs.twimg.com/media/A2OXIUcCUAAXj9k.png");
}

@end
