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
    }

    return self;
}

@end
