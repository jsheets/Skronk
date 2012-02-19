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
#import "PreferencesController.h"

NSString *kGlobalHotKey = @"Global Hot Key";

@implementation AppDelegate

@synthesize window = _window;
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize progress = _progress;
@synthesize timer = _timer;
@synthesize art = _art;
@synthesize statusMenu = _statusMenu;
@synthesize statusItem = _statusItem;
@synthesize showHideMenuItem = _showHideMenuItem;
@synthesize preferencesController = _preferencesController;

- (void)showInMenubar:(BOOL)showMenu
{
    if (showMenu)
    {
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusItem.menu = self.statusMenu;
        self.statusItem.title = @"π";
        self.statusItem.highlightMode = YES;
//    self.statusItem.image = nil;
    }
    else
    {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    }
}

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
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:newFadeIn]];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDuration:0.5];
    [animation startAnimation];

    // When fade-in is complete, expand the window.
    NSRect newFrame = self.window.frame;
    newFrame.size.height = 30;

    NSDictionary *move = [NSDictionary dictionaryWithObjectsAndKeys:
        self.window, NSViewAnimationTargetKey,
        [NSValue valueWithRect:self.window.frame], NSViewAnimationStartFrameKey,
        [NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey,
        nil];

//    NSLog(@"Animating fadeIn from %@ to %@", NSStringFromRect(self.window.frame), NSStringFromRect(newFrame));
    animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:move]];
    [animation setDuration:0.5];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation startAnimation];

//    [self.window setFrame:newFrame display:YES animate:YES];
}

- (void)fadeOutWindow
{
    // Shrink then fade out.
    NSRect newFrame = [self.window frame];
    newFrame.size.height = 3;
    [self.window setFrame:newFrame display:YES animate:YES];
    [self.window.animator setAlphaValue:0.0];
}

// Update window visibility if changed.
- (void)fadeWindow:(BOOL)showWindow
{
    if (showWindow)
    {
        if (![self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Hide Skronk";
            [self fadeInWindow];
        }
    }
    else
    {
        // If window is still visible, hide it.
        if ([self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Show Skronk";
            [self fadeOutWindow];
        }
    }
}

- (void)updateCurrentTrack
{
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastFmUsername"];
    if (username == nil)
    {
        NSLog(@"Username not set...skipping update.");
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=3a36e88356d8d90aee7a012c6abccae1&limit=2&user=%@&format=json", username];
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
        BOOL firstTime = [self.label.stringValue isEqualToString:@"Loading..."];
        if (nowPlaying.isPlaying || firstTime)
        {
            if (firstTime)
            {
                NSLog(@"Initial startup, not playing: loading previous track.");
            }

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

            [self.art setHidden:!nowPlaying.isPlaying];

            BOOL hideWhenNotPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:@"autohide"];
//            NSLog(@"Autohide is %@", hideWhenNotPlaying ? @"ON" : @"OFF");

            // Hide window when not playing and autohide is on.
            BOOL hideWindow = !nowPlaying.isPlaying && hideWhenNotPlaying;
            [self fadeWindow:!hideWindow];

            // Stop spinner.
            [self.progress stopAnimation:self];
        });

        // Fetch album art.
        NSImage *albumImage = nil;
        if (nowPlaying.isPlaying && nowPlaying.artSmallUrl)
        {
            albumImage = [[NSImage alloc] initWithContentsOfURL:nowPlaying.artSmallUrl];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.art setHidden:!nowPlaying.isPlaying];
            self.art.image = albumImage;
        });
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Error updating last.fm status for user %@: %@", username, [error localizedDescription]);
    }];
    
    [request startAsynchronous];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ((object == [NSUserDefaults standardUserDefaults]))
    {
        if ([keyPath isEqualToString:@"autohide"])
        {
            [self updateCurrentTrack];
            return;
        }
        else if ([keyPath isEqualToString:@"showInMenubar"])
        {
            // Toggle menubar.
            BOOL shouldShowMenu = [[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 1;
            [self showInMenubar:shouldShowMenu];
            return;
        }
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

    [self showHideClicked:sender];
}

- (IBAction)showHideClicked:(id)sender
{
    // Show/hide smoothly.
    BOOL wasVisible = [self windowIsVisible];
    [self fadeWindow:!wasVisible];
}

- (IBAction)preferencesClicked:(id)sender
{
    NSLog(@"Preferences clicked.");
    if (self.preferencesController == nil)
    {
        self.preferencesController = [[PreferencesController alloc] init];
    }

    [self.preferencesController showWindow:self];
}

- (void)awakeFromNib
{
    // Hide window so we don't get a jump when we restore the window position.
    [self.window setAlphaValue:0];

    BOOL shouldShowMenubar = [[NSUserDefaults standardUserDefaults] boolForKey:@"showInMenubar"];
    [self showInMenubar:shouldShowMenubar];

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"autohide" options:(NSKeyValueObservingOptionNew) context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"showInMenubar" options:(NSKeyValueObservingOptionNew) context:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupHotkeys];

    // Explicitly restore autosaved window position, since this doesn't seem to happen by default.
    [self.window setFrameAutosaveName:@"Skronk"];

    [self.window setMovableByWindowBackground:YES];
    self.window.level = NSFloatingWindowLevel;

    // Stick to all windows.
//    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary |
//        NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

    [self updateCurrentTrack];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateCurrentTrack) userInfo:nil repeats:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    // Briefly unhide if we gain focus.
    [self fadeWindow:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Smooth fade-out.
    [self fadeWindow:NO];
}

@end
