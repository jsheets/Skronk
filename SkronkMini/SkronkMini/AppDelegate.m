//
//  AppDelegate.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "NowPlaying.h"
#import "ASIHTTPRequest.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "PreferencesController.h"
#import "SRCommon.h"
#import "RoundedView.h"

static NSString *const kGlobalHotKey = @"Global Hot Key";

static NSString *const kPreferenceAutohide = @"autohide";
static NSString *const kPreferenceAlwaysOnTop = @"alwaysOnTop";
static NSString *const kPreferenceShowInMenubar = @"showInMenubar";
static NSString *const kPreferenceWatchLastFm = @"watchLastFm";
static NSString *const kPreferenceAutosizeToFit = @"autosizeToFit";
static NSString *const kPreferenceShowNetworkAvailability = @"showNetworkAvailability";
static NSString *const kPreferenceLastFmUsername = @"lastFmUsername";
static NSString *const kPreferenceTransparentBackground = @"transparentBackground";

static CGFloat const kServiceIconMaxAlpha = 0.8f;
static CGFloat const kServiceIconDimAlpha = 0.3f;
static CGFloat const kServiceIconHiddenAlpha = 0.0f;

@interface AppDelegate ()
- (void)updateCurrentTrack;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize roundedView = _roundedView;
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize art = _art;
@synthesize statusMenu = _statusMenu;
@synthesize showHideMenuItem = _showHideMenuItem;
@synthesize showHideStatusbarItem = _showHideStatusbarItem;
@synthesize statusItem = _statusItem;
@synthesize timer = _timer;
@synthesize preferencesController = _preferencesController;
@synthesize isSleeping = _isSleeping;
@synthesize serviceIcon = _serviceIcon;
@synthesize backgroundWidth = _backgroundWidth;

- (void)resetTimer
{
    if (self.timer)
    {
        [self.timer invalidate];
    }

    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateCurrentTrack) userInfo:nil repeats:YES];
}

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

- (void)performAnimation:(NSDictionary *)properties
{
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:properties]];
    [animation setDuration:0.5];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation startAnimation];
}

- (void)resizeWindowTo:(NSRect)newFrame
{
    // If nothing's changed, don't bother animating anything.
    if (self.window.frame.size.width == newFrame.size.width && self.window.frame.size.height == newFrame.size.height)
    {
        return;
    }

    NSDictionary *move = [NSDictionary dictionaryWithObjectsAndKeys:
        self.window, NSViewAnimationTargetKey,
        [NSValue valueWithRect:self.window.frame], NSViewAnimationStartFrameKey,
        [NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey,
        nil];

    [self performAnimation:move];
}

- (void)animateWindowFade:(NSString *)fadeEffect
{
    NSDictionary *fadeOut = [NSDictionary dictionaryWithObjectsAndKeys:
        self.window, NSViewAnimationTargetKey,
        fadeEffect, NSViewAnimationEffectKey, nil];

    [self performAnimation:fadeOut];
}

- (void)fadeInWindow
{
    // Fade in window sliver then expand to normal height.
    [self animateWindowFade:NSViewAnimationFadeInEffect];

    NSRect newFrame = self.window.frame;
    newFrame.size.height = 36;
    [self resizeWindowTo:newFrame];
}

- (void)fadeOutWindow
{
    // Shrink the window then fade out.
    NSRect newFrame = self.window.frame;
    newFrame.size.height = 3;
    [self resizeWindowTo:newFrame];

    [self animateWindowFade:NSViewAnimationFadeOutEffect];
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

            // Don't update here after all. Causes issues with quick hide/show.
//            [self updateCurrentTrack];
//            [self resetTimer];
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

- (void)startNetworkAnimation
{
//    if (self.serviceIcon.alphaValue == kServiceIconHiddenAlpha) return;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:kServiceIconMaxAlpha];
    animation.toValue = [NSNumber numberWithFloat:kServiceIconDimAlpha];
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.autoreverses = YES;
    animation.repeatCount = 100;

    [self.serviceIcon.layer addAnimation:animation forKey:@"opacity"];
}

- (void)endNetworkAnimation
{
//    if (self.serviceIcon.alphaValue == kServiceIconHiddenAlpha) return;

    // Pause a bit longer for usability.
    [NSThread sleepForTimeInterval:1.0];

    [self.serviceIcon.layer removeAnimationForKey:@"opacity"];
}

- (void)showServiceUp
{
    [[self.serviceIcon animator] setAlphaValue:kServiceIconMaxAlpha];
}

- (void)showServiceDown
{
    [[self.serviceIcon animator] setAlphaValue:kServiceIconDimAlpha];
}

- (NSMutableAttributedString *)trackDisplayText:(NowPlaying *)nowPlaying
{
    NSMutableAttributedString *displayText = nil;

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

        NSString *plainString = [fields componentsJoinedByString:@" - "];
        displayText = [[NSMutableAttributedString alloc] initWithString:plainString];
    }
    else
    {
        displayText = [[NSMutableAttributedString alloc] init];

        NSColor *whiteColor = nowPlaying.isPlaying ? [NSColor colorWithCalibratedWhite:0.9 alpha:1.0] : [NSColor grayColor];
        NSDictionary *white = [NSDictionary dictionaryWithObject:whiteColor forKey:NSForegroundColorAttributeName];
        NSDictionary *gray = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont fontWithName:@"Helvetica" size:13.0], NSFontAttributeName,
            [NSColor grayColor], NSForegroundColorAttributeName,
            nil];

        NSAttributedString *fancyString;

        // White real text, gray join text, bold artist name.
        if (hasTrack)
        {
//            NSString *plainText = [NSString stringWithFormat:@"\"%@\"", nowPlaying.track];
            fancyString = [[NSAttributedString alloc] initWithString:nowPlaying.track attributes:white];
            [displayText appendAttributedString:fancyString];
        }

        if (hasArtist)
        {
            fancyString = [[NSAttributedString alloc] initWithString:@" by " attributes:gray];
            [displayText appendAttributedString:fancyString];

            fancyString = [[NSAttributedString alloc] initWithString:nowPlaying.artist attributes:white];
            [displayText appendAttributedString:fancyString];
        }

        if (hasAlbum)
        {
            fancyString = [[NSAttributedString alloc] initWithString:@" on " attributes:
                gray];
            [displayText appendAttributedString:fancyString];

            fancyString = [[NSAttributedString alloc] initWithString:nowPlaying.album attributes:
                white];
            [displayText appendAttributedString:fancyString];
        }
    }

    return displayText;
}

- (NSMutableAttributedString *)grayTrackText
{
    NSMutableAttributedString *displayText = [[NSMutableAttributedString alloc] initWithAttributedString:self.label.attributedStringValue];

    NSDictionary *gray = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    [displayText setAttributes:gray range:NSMakeRange(0, displayText.length)];

    return displayText;
}

- (void)adjustWindowSize
{
    NSRect newFrame = self.window.frame;

    // Settings.
    BOOL showNetworkAvailability = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowNetworkAvailability];
    BOOL transparentBackground = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceTransparentBackground];
    BOOL autosizeToFit = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAutosizeToFit];

    NSRect labelRect = self.label.frame;

    CGFloat paddingBeforeText = labelRect.origin.x;  // 42
    CGFloat paddingAfterText = showNetworkAvailability ? 38 : 12; // 38 with 26px service icon, or 12.
    CGFloat padding = paddingBeforeText + paddingAfterText + 7;

    if (autosizeToFit)
    {
        // Calculate how wide the text wants to be.
        NSAttributedString *trackText = self.label.attributedStringValue;
        NSDictionary *fontAttributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:14.0] forKey:NSFontAttributeName];
        NSSize fontSize = [trackText.string sizeWithAttributes:fontAttributes];

        CGFloat windowWidth = fontSize.width + padding;

        // Clamp window width to the size of the background image, if showing.
        if (!transparentBackground && windowWidth > self.backgroundWidth)
        {
            windowWidth = self.backgroundWidth;
        }

        // Resize text field.
        labelRect.size.width = windowWidth - padding;
        [[self.label animator] setFrame:labelRect];

        // Set new window width.
        newFrame.size.width = windowWidth;
    }
    else
    {
        // Hardcoded window size.
        newFrame.size.width = 640;
    }

    [self resizeWindowTo:newFrame];
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
    
    BOOL showNetworkAvailability = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowNetworkAvailability];
    if (showNetworkAvailability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startNetworkAnimation];
        });
    }

    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
//        NSLog(@"Received JSON: %@", responseString);

        NSMutableAttributedString *displayText = nil;

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
        else
        {
            // Not playing. Would like to gray out the current text when not playing, but
            // can't rely on last.fm JSON to still have it. If the current track has not yet
            // been scrobbled, the text will immediately fall back to the previous track.
            //
            // Eh, just gray out whatever text used to be there. Initial track already taken care of above.
            displayText = [self grayTrackText];
        }

        // Back on main thread...
        dispatch_async(dispatch_get_main_queue(), ^{
            // If we have something new to report, show it.
            if (displayText)
            {
                self.label.attributedStringValue = displayText;
                [self adjustWindowSize];
            }

            // Hide album art if not playing.
            [self.art setHidden:!nowPlaying.isPlaying];

            // Update service icon visibility.
            if (showNetworkAvailability)
            {
                [self showServiceUp];
            }

            // Hide window when not playing and autohide is on.
            BOOL hideWhenNotPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAutohide];
            BOOL hideWindow = !nowPlaying.isPlaying && hideWhenNotPlaying;
            [self showWindow:!hideWindow];

            // Stop pulsing service icon.
            if (showNetworkAvailability)
            {
                [self endNetworkAnimation];
            }
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
        if (showNetworkAvailability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.label.attributedStringValue = [self grayTrackText];
                [self endNetworkAnimation];
                [self showServiceDown];
            });
        }
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
            [self resetTimer];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceShowInMenubar])
        {
            // Toggle menubar.
            BOOL shouldShowMenu = [[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 1;
            [self showInMenubar:shouldShowMenu];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceAutosizeToFit])
        {
            [self adjustWindowSize];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceAlwaysOnTop])
        {
            // Toggle always on top.
            self.alwaysOnTop = !self.alwaysOnTop;
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceTransparentBackground])
        {
            // Redraw RoundedView to update background transparency.
            [self adjustWindowSize];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceShowNetworkAvailability])
        {
            // Toggle showing service icon.
            BOOL shouldShowIcon = [[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 1;
            if (shouldShowIcon)
            {
                [self updateCurrentTrack];
                [self resetTimer];
            }
            else
            {
                [[self.serviceIcon animator] setAlphaValue:kServiceIconHiddenAlpha];
            }

            [self adjustWindowSize];

            return;
        }
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateHotkeys
{
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
    self.roundedView.backgroundImage = [NSImage imageNamed:@"concrete-background"];
    self.backgroundWidth = self.roundedView.backgroundImage.size.width;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowNetworkAvailability])
    {
        self.serviceIcon.alphaValue = 0.0f;
    }
}

- (void)registerDefaults
{
    // Set defaults to prefs.
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:NO],  kPreferenceAutohide,
        [NSNumber numberWithBool:YES], kPreferenceAlwaysOnTop,
        [NSNumber numberWithBool:NO], kPreferenceAutosizeToFit,
        [NSNumber numberWithBool:YES], kPreferenceShowInMenubar,
        [NSNumber numberWithBool:YES], kPreferenceWatchLastFm,
        [NSNumber numberWithBool:NO], kPreferenceTransparentBackground,
        [NSNumber numberWithBool:YES], kPreferenceShowNetworkAvailability,
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

    BOOL alwaysOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAlwaysOnTop];
    [self setAlwaysOnTop:alwaysOnTop];

    // Stick to all desktops.
//    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary |
//        NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

    [self updateCurrentTrack];
    [self resetTimer];

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

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceAutohide options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceShowInMenubar options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceAlwaysOnTop options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceAutosizeToFit options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceLastFmUsername options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceShowNetworkAvailability options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kPreferenceTransparentBackground options:NSKeyValueObservingOptionNew context:nil];
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
