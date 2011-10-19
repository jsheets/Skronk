//
//  Track.m
//  SkronkSpike
//
//  Created by John Sheets on 10/18/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "Track.h"

@implementation Track

@synthesize artist, album, track, cover;

- (id)init
{
    if ((self = [super init]))
    {
        self.artist = @"Rage Against the Machine";
        self.album = @"Evil Empire";
        self.track = @"Bulls on Parade";
        self.cover = [NSImage imageNamed:@"evil-empire"];
    }
    
    return self;
}               
@end
