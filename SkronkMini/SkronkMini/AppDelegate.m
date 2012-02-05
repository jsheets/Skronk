//
//  AppDelegate.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize label = _label;

- (void)updateCurrentTrackForUser:(NSString *)username
{
    NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=3a36e88356d8d90aee7a012c6abccae1&limit=2&user=%@&format=json", username];
    NSURL *url = [NSURL URLWithString:urlString];

    NSLog(@"Looking up last.fm URL: %@", url);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.label.stringValue = @"Artist - Album - Track";
    [self.window setMovableByWindowBackground:YES];
    self.window.level = NSFloatingWindowLevel;

    [self updateCurrentTrackForUser:@"johnsheets"];
}

@end
