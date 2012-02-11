//
//  NowPlaying.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "NowPlaying.h"

@implementation NowPlaying

@synthesize isPlaying = _isPlaying;
@synthesize artist = _artist;
@synthesize album = _album;
@synthesize track = _track;
@synthesize artSmallUrl = _artSmallUrl;

- (id)initWithJson:(NSString *)json
{
    if ((self = [super initWithJson:json]))
    {
        // Assign nowPlaying property.
        NSString *nowPlayingValue = [self valueForProperty:@"recenttracks.track[0].@attr.nowplaying"];
        self.isPlaying = [nowPlayingValue isEqualToString:@"true"];

        self.artist = [self valueForProperty:@"recenttracks.track[0].artist.#text"];
        self.album = [self valueForProperty:@"recenttracks.track[0].album.#text"];
        self.track = [self valueForProperty:@"recenttracks.track[0].name"];

        NSArray *images = [self valueForProperty:@"recenttracks.track[0].image"];
        for (NSDictionary *imageDict in images)
        {
            if ([[imageDict valueForKey:@"size"] isEqualToString:@"small"])
            {
                NSString *urlString = [imageDict valueForKey:@"#text"];
                if ([urlString length])
                {
                    self.artSmallUrl = [NSURL URLWithString:urlString];
                }

                break;
            }
        }
    }

    return self;
}

@end
