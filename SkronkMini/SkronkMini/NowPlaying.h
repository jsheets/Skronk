//
//  NowPlaying.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NowPlaying : NSObject

@property (retain) NSString *json;

- (id)initWithJson:(NSString *)json;

@end
