#import <XCTest/XCTest.h>
#import "NSDate+Justaway.h"

@interface NSDate_Justaway : XCTestCase

@end

@implementation NSDate_Justaway

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
    // relativeDescription
    XCTAssertEqualObjects([[NSDate date] relativeDescription], @"now");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3] relativeDescription], @"3s");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60] relativeDescription], @"3m");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60*60] relativeDescription], @"3h");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60*60*24] relativeDescription], @"3d");
    
    // absoluteDescription
    NSDate *createdAt = [NSDate dateWithString:@"Wed Jun 06 20:07:10 +0000 2012"];
    NSString *absoluteDescription = [createdAt absoluteDescription];
    XCTAssertEqualObjects(absoluteDescription, @"2012/06/07 05:07:10", );
}

@end
