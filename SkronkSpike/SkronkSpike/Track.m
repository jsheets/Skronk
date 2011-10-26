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

// Image sizes:
// small = 34x34
// medium = 64x64
// large = 126x126
// extralarge = 300x300
- (id)initWithLastFm:(NSDictionary *)trackDict
{
    if ((self = [super init]))
    {
        self.artist = [[trackDict valueForKeyPath:@"artist"] valueForKey:@"#text"];
        self.album = [[trackDict valueForKey:@"album"] valueForKey:@"#text"];
        self.track = [trackDict valueForKey:@"name"];
        
        NSURL *url = nil;
        NSArray *images = [trackDict valueForKey:@"image"];
        for (NSDictionary *imageDict in images)
        {
            if ([[imageDict valueForKey:@"size"] isEqualToString:@"large"])
            {
                NSString *urlString = [imageDict valueForKey:@"#text"];
                if (urlString)
                {
                    url = [NSURL URLWithString:urlString];
                    self.cover = [[[NSImage alloc] initWithContentsOfURL:url] autorelease];
                    
                    break;
                }
            }
        }
        
        if (self.cover == nil)
        {
            NSLog(@"Unable to find cover art for %@ - %@ - %@", self.artist, self.album, self.track);
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
