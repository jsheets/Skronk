//
//  Track.h
//  SkronkSpike
//
//  Created by John Sheets on 10/18/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Track : NSObject

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *album;
@property (nonatomic, copy) NSString *track;
@property (nonatomic, retain) NSImage *cover;

- (id)initWithDictionary:(NSDictionary *)trackDict;

@end
