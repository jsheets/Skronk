//
//  NowPlaying.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMJson.h"

@interface NowPlaying : FMJson

@property (assign) BOOL isPlaying;

@property (retain) NSString *artist;
@property (retain) NSString *album;
@property (retain) NSString *track;
@property (retain) NSURL *artSmallUrl;
@property (retain) NSString *error;

@end
