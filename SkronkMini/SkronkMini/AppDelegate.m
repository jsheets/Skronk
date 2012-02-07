//
//  AppDelegate.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "AppDelegate.h"
#import "NowPlaying.h"
#import "ASIHTTPRequest.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"

NSString *kGlobalHotKey = @"Global Hot Key";

@implementation AppDelegate

@synthesize window = _window;
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize progress = _progress;
@synthesize timer = _timer;
@synthesize username = _username;

- (void)updateCurrentTrack
{
    NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=3a36e88356d8d90aee7a012c6abccae1&limit=2&user=%@&format=json", self.username];
    NSURL *url = [NSURL URLWithString:urlString];

    NSLog(@"Looking up last.fm URL: %@", url);
    
    // Start spinner.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progress startAnimation:self];
    });
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
//        NSLog(@"Received JSON: %@", responseString);

        NowPlaying *nowPlaying = [[NowPlaying alloc] initWithJson:responseString];
        NSString *displayText = [NSString stringWithFormat:@"%@ - %@ - %@", nowPlaying.artist, nowPlaying.album, nowPlaying.track];

        // Back on main thread...
        dispatch_async(dispatch_get_main_queue(), ^{
            self.label.stringValue = displayText;
            self.icon.textColor = nowPlaying.isPlaying ? [NSColor alternateSelectedControlColor] : [NSColor controlShadowColor];
            
            // Stop spinner.
            [self.progress stopAnimation:self];
        });
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Error updating last.fm status for user %@: %@", self.username, [error localizedDescription]);
    }];
    
    [request startAsynchronous];
}

- (void)setupHotkeys
{
    // Modifiers: cmdKey, shiftKey, optionKey, controlKey
    
    // Cmd-Opt-Ctrl-l
    NSInteger keyCode = 37;
    NSInteger modifier = cmdKey + optionKey + controlKey;
    
    SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:keyCode modifiers:modifier];
    SGHotKey *hotKey = [[SGHotKey alloc] initWithIdentifier:kGlobalHotKey keyCombo:keyCombo target:self action:@selector(hotKeyPressed:)];
    [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
}

- (void)hotKeyPressed:(id)sender
{
    NSLog(@"Hot key pressed");
    BOOL visibleState = [self.window isVisible];
    [self.window setIsVisible:!visibleState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupHotkeys];
    
    [self.window setMovableByWindowBackground:YES];
    self.window.level = NSFloatingWindowLevel;

    self.username = @"johnsheets";
    [self updateCurrentTrack];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateCurrentTrack) userInfo:nil repeats:YES];
}

@end
