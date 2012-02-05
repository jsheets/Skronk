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

- (id)initWithJson:(NSString *)json
{
    if ((self = [super initWithJson:json]))
    {
        // Assign nowPlaying property.
        NSString *nowPlayingValue = [self valueForProperty:@"recenttracks.track[0].@attr.nowplaying"];
        self.isPlaying = [nowPlayingValue isEqualToString:@"true"];
    }

    return self;
}

@end
