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
    // dateWithString
    XCTAssertEqualWithAccuracy([[NSDate dateWithTwitterDate:@"Wed Jun 06 20:07:10 +0900 2012"] timeIntervalSince1970], 1338980830, 0.000000001);
    XCTAssertEqualWithAccuracy([[NSDate dateWithTwitterDate:@"Wed Jun 06 20:07:10 +0000 2012"] timeIntervalSince1970], 1339013230, 0.000000001);
    
    // relativeDescription
    XCTAssertEqualObjects([[NSDate date] relativeDescription], @"now");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3] relativeDescription], @"3s");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60] relativeDescription], @"3m");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60*60] relativeDescription], @"3h");
    XCTAssertEqualObjects([[NSDate dateWithTimeIntervalSinceNow:-3*60*60*24] relativeDescription], @"3d");
    
    // absoluteDescription
    NSDateFormatter *formatter = NSDateFormatter.new;
    formatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    XCTAssertEqualObjects([[NSDate date] absoluteDescription], [formatter stringFromDate:[NSDate date]]);
}

@end
