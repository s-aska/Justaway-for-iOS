//
//  DelimitedReader.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public class DelimitedReader {
    var delimiter: NSData
    var buffer: NSMutableData
    
    public init(delimiter: NSData =  "\n".dataUsingEncoding(NSUTF8StringEncoding)!) {
        self.delimiter = delimiter
        self.buffer = NSMutableData()
    }
    
    public func appendData(data: NSData) {
        buffer.appendData(data)
    }
    
    public func readData() -> NSData? {
        let range = buffer.rangeOfData(delimiter, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, buffer.length))
        if range.location != NSNotFound {
            let line = buffer.subdataWithRange(NSMakeRange(0, range.location))
            buffer.replaceBytesInRange(NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
            return line
        } else {
            return nil
        }
    }
}
