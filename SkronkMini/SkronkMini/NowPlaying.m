//
//  NowPlaying.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "NowPlaying.h"

@implementation NowPlaying

@synthesize json = _json;

- (id)initWithJson:(NSString *)json
{
    if ((self = [super init]))
    {
        _json = json;
    }

    return self;
}

@end
