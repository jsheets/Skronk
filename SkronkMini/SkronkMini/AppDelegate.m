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
#import "SRCommon.h"

static NSString *const kGlobalHotKey = @"Global Hot Key";

static NSString *const kPreferenceAutohide = @"autohide";
static NSString *const kPreferenceAlwaysOnTop = @"alwaysOnTop";
static NSString *const kPreferenceShowInMenubar = @"showInMenubar";
static NSString *const kPreferenceWatchLastFm = @"watchLastFm";
static NSString *const kPreferenceLastFmUsername = @"lastFmUsername";

@implementation AppDelegate

@synthesize window = _window;
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize progress = _progress;
@synthesize art = _art;
@synthesize statusMenu = _statusMenu;
@synthesize showHideMenuItem = _showHideMenuItem;
@synthesize showHideStatusbarItem = _showHideStatusbarItem;
@synthesize statusItem = _statusItem;
@synthesize timer = _timer;
@synthesize preferencesController = _preferencesController;
@synthesize isSleeping = _isSleeping;

- (BOOL)alwaysOnTop
{
    return self.window.level == NSFloatingWindowLevel;
}

- (void)setAlwaysOnTop:(BOOL)onTop
{
    self.window.level = onTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
}

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
    else if (self.statusItem)
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
- (void)showWindow:(BOOL)showWindow
{
    self.isSleeping = !showWindow;

    if (showWindow)
    {
        if (![self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Hide Skronk";
            self.showHideStatusbarItem.title = @"Hide Skronk";
            [self fadeInWindow];
        }
    }
    else
    {
        // If window is still visible, hide it.
        if ([self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Show Skronk";
            self.showHideStatusbarItem.title = @"Show Skronk";
            [self fadeOutWindow];
        }
    }
}

- (NSString *)trackDisplayText:(NowPlaying *)nowPlaying
{
    NSString *displayText = nil;

    BOOL hasArtist = nowPlaying.artist.length > 0;
    BOOL hasAlbum = nowPlaying.album.length > 0;
    BOOL hasTrack = nowPlaying.track.length > 0;

    BOOL hyphenFormat = NO;
    if (hyphenFormat)
    {
        NSMutableArray *fields = [NSMutableArray array];
        if (hasArtist) [fields addObject:nowPlaying.artist];
        if (hasAlbum) [fields addObject:nowPlaying.album];
        if (hasTrack) [fields addObject:nowPlaying.track];

        displayText = [fields componentsJoinedByString:@" - "];
    }
    else
    {
        NSString *trackText = hasTrack ? [NSString stringWithFormat:@"\"%@\"", nowPlaying.track] : @"";
        NSString *artistText = hasArtist ? [NSString stringWithFormat:@" by %@", nowPlaying.artist] : @"";
        NSString *albumText = hasAlbum ? [NSString stringWithFormat:@", on %@", nowPlaying.album] : @"";

        displayText = [NSString stringWithFormat:@"%@%@%@", trackText, artistText, albumText];
    }

    return displayText;
}

- (void)updateCurrentTrack
{
    if (self.isSleeping)
    {
//        NSLog(@"Sleeping...");
        return;
    }

    BOOL watchLastFm = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceWatchLastFm];
    if (!watchLastFm)
    {
        NSLog(@"Last.fm disabled...skipping update.");
        return;
    }

    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];
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

            displayText = [self trackDisplayText:nowPlaying];
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

            BOOL hideWhenNotPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAutohide];
//            NSLog(@"Autohide is %@", hideWhenNotPlaying ? @"ON" : @"OFF");

            // Hide window when not playing and autohide is on.
            BOOL hideWindow = !nowPlaying.isPlaying && hideWhenNotPlaying;
            [self showWindow:!hideWindow];

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

// Watch preferences for changes.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults])
    {
        if ([keyPath isEqualToString:kPreferenceAutohide] || [keyPath isEqualToString:kPreferenceLastFmUsername])
        {
            [self updateCurrentTrack];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceShowInMenubar])
        {
            // Toggle menubar.
            BOOL shouldShowMenu = [[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 1;
            [self showInMenubar:shouldShowMenu];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceAlwaysOnTop])
        {
            // Toggle always on top.
            self.alwaysOnTop = !self.alwaysOnTop;
            return;
        }
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateHotkeys
{
    // Modifiers: cmdKey, shiftKey, optionKey, controlKey
    
    // Cmd-Opt-Ctrl-l
//    NSInteger keyCode = 37;
//    NSInteger modifier = cmdKey + optionKey + controlKey;
//    NSLog(@"Hard-coded modifiers: (%lu %lu)", keyCode, modifier);

    NSInteger hideCode = [[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceHideShortcutCode];
    NSInteger hideFlags = [[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceHideShortcutFlags];
    NSLog(@"Preference modifiers: (%lu %lu)", hideCode, SRCocoaToCarbonFlags(hideFlags));

    SGHotKey *oldHotKey = [[SGHotKeyCenter sharedCenter] hotKeyWithIdentifier:kGlobalHotKey];
    [[SGHotKeyCenter sharedCenter] unregisterHotKey:oldHotKey];

    SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:hideCode modifiers:SRCocoaToCarbonFlags(hideFlags)];
    SGHotKey *hotKey = [[SGHotKey alloc] initWithIdentifier:kGlobalHotKey keyCombo:keyCombo target:self action:@selector(hotKeyPressed:)];
    [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
}

- (void)hotKeyPressed:(id)sender
{
//    NSLog(@"Hot key pressed");
    [self showHideClicked:sender];
}

- (IBAction)showHideClicked:(id)sender
{
    BOOL wasVisible = [self windowIsVisible];
    [self showWindow:!wasVisible];
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
}

- (void)registerDefaults
{
    // Set defaults to prefs.
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:NO],  kPreferenceAutohide,
        [NSNumber numberWithBool:YES], kPreferenceAlwaysOnTop,
        [NSNumber numberWithBool:YES], kPreferenceShowInMenubar,
        [NSNumber numberWithBool:YES], kPreferenceWatchLastFm,
//        @"woot", kPreferenceLastFmUsername,
        nil
    ];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self registerDefaults];
    [self updateHotkeys];

    // Explicitly restore autosaved window position, since this doesn't seem to happen by default.
    [self.window setFrameAutosaveName:@"Skronk"];

    [self.window setMovableByWindowBackground:YES];

    BOOL alwaysOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAlwaysOnTop];
    [self setAlwaysOnTop:alwaysOnTop];

    // Stick to all windows.
//    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary |
//        NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

    [self updateCurrentTrack];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateCurrentTrack) userInfo:nil repeats:YES];

    // If not last.fm username set, bring up Preferences dialog with text field focused.
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];
    if (username == nil)
    {
        self.label.stringValue = @"Please enter a last.fm user name to continue...";
        [self preferencesClicked:self];
        [self.preferencesController.window makeFirstResponder:self.preferencesController.lastFmTextField];
    }
    
    BOOL shouldShowMenubar = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowInMenubar];
    [self showInMenubar:shouldShowMenubar];

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceAutohide options:(NSKeyValueObservingOptionNew) context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceShowInMenubar options:(NSKeyValueObservingOptionNew) context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceAlwaysOnTop options:(NSKeyValueObservingOptionNew) context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceLastFmUsername options:(NSKeyValueObservingOptionNew) context:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    // Briefly unhide if we gain focus.
    [self showWindow:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Smooth fade-out.
    [self showWindow:NO];
}

@end
