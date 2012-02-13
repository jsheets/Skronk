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
@synthesize art = _art;
@synthesize hideWhenNotPlaying = _hideWhenNotPlaying;

- (BOOL)windowIsVisible
{
    return self.window.alphaValue == 1.0;
}

- (void)fadeInWindow
{
    // Fade in then expand.
    NSDictionary *newFadeIn = [NSDictionary dictionaryWithObjectsAndKeys:
                                      self.window, NSViewAnimationTargetKey,
                                      NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];

    // Fade in stripe, then block until fully visible.
    NSArray *animations = [NSArray arrayWithObject:newFadeIn];
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];

    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDuration:0.5];
    [animation startAnimation];

    // When fade-in is complete, expand the window.
    NSRect newFrame = [self.window frame];
    newFrame.size.height = 30;
    [self.window setFrame:newFrame display:YES animate:YES];
}

- (void)fadeOutWindow
{
    // Shrink then fade out.
    NSRect newFrame = [self.window frame];
    newFrame.size.height = 3;
    [self.window setFrame:newFrame display:YES animate:YES];
    [self.window.animator setAlphaValue:0.0];
}

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

        NSString *displayText = nil;

        NowPlaying *nowPlaying = [[NowPlaying alloc] initWithJson:responseString];
        if (nowPlaying.isPlaying)
        {
            NSMutableArray *fields = [NSMutableArray array];
            if (nowPlaying.artist.length > 0) [fields addObject:nowPlaying.artist];
            if (nowPlaying.album.length > 0) [fields addObject:nowPlaying.album];
            if (nowPlaying.track.length > 0) [fields addObject:nowPlaying.track];
            
            displayText = [fields componentsJoinedByString:@" - "];
        }

        // Back on main thread...
        dispatch_async(dispatch_get_main_queue(), ^{
            // If we have something new to report, show it.
            if (displayText)
            {
                self.label.stringValue = displayText;
            }

//            self.label.textColor = nowPlaying.isPlaying ? [NSColor textColor] : [NSColor controlShadowColor];
            self.label.textColor = nowPlaying.isPlaying ? [NSColor highlightColor] : [NSColor controlShadowColor];
            self.icon.textColor = nowPlaying.isPlaying ? [NSColor alternateSelectedControlColor] : [NSColor controlShadowColor];

            self.art.hidden = !nowPlaying.isPlaying;
            if (self.hideWhenNotPlaying)
            {
                if (nowPlaying.isPlaying)
                {
                    if (![self windowIsVisible])
                    {
                        [self fadeInWindow];
                    }
                }
                else
                {
                    // Not playing. If window is still visible, hide it.
                    if ([self windowIsVisible])
                    {
                        [self fadeOutWindow];
                    }
                }
            }

            // Stop spinner.
            [self.progress stopAnimation:self];
        });

        // Fetch album art.
        if (nowPlaying.isPlaying && nowPlaying.artSmallUrl)
        {
            NSImage *albumImage = [[NSImage alloc] initWithContentsOfURL:nowPlaying.artSmallUrl];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.art.hidden = NO;
                self.art.image = albumImage;
            });
        }
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

    // Show/hide abruptly.
//    BOOL newVisibleState = ![self.window isVisible];
//    [self.window setIsVisible:newVisibleState];

    // Show/hide smoothly.
    BOOL wasVisible = [self windowIsVisible];
    if (wasVisible)
    {
        [self fadeOutWindow];
    }
    else
    {
        [self fadeInWindow];
    }

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.hideWhenNotPlaying = YES;

    [self setupHotkeys];
    
    [self.window setMovableByWindowBackground:YES];
    self.window.level = NSFloatingWindowLevel;
//    self.window.level = kCGMainMenuWindowLevel - 1;

    // Stick to all windows.
//    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary |
//        NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

    self.username = @"johnsheets";
    [self updateCurrentTrack];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateCurrentTrack) userInfo:nil repeats:YES];
}

@end
