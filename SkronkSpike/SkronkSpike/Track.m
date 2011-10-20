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

- (id)initWithDictionary:(NSDictionary *)trackDict
{
    if ((self = [super init]))
    {
        self.artist = [trackDict valueForKey:@"artist"];
        self.album = [trackDict valueForKey:@"album"];
        self.track = [trackDict valueForKey:@"track"];
        
        NSImage *image = [NSImage imageNamed:[trackDict valueForKey:@"coverFile"]];
        if (image)
        {
            self.cover = image;
        }
    }
    
    return self;
}               

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
