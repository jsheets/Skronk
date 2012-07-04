//
//  AppDelegate.m
//  SkronkFM
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"

#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "ASIHTTPRequest.h"
#import "SRCommon.h"
#import "FFMLastFmJson.h"
#import "FFMSong.h"

#import "PreferencesController.h"
#import "RoundedView.h"
#import "FFMSongUpdater.h"
#import "FFMITunesUpdater.h"
#import "FFMLastFMUpdater.h"
#import "FFMLastFMAppUpdater.h"
#import "FFMMogUpdater.h"
#import "FFMRdioUpdater.h"
#import "FFMSpotifyUpdater.h"

static NSString *const kGlobalHotKey = @"Global Hot Key";

static NSString *const kPreferenceAutohide = @"autohide";
static NSString *const kPreferenceAlwaysOnTop = @"alwaysOnTop";
static NSString *const kPreferenceShowInMenubar = @"showInMenubar";
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
@synthesize currentlyPlaying = _currentlyPlaying;
@synthesize currentAlbumArtURL = _currentAlbumArtURL;
@synthesize currentAlbumArt = _currentAlbumArt;
@synthesize missingArt = _missingArt;
@synthesize currentSong = _currentSong;

@synthesize currentSongUpdater = _currentSongUpdater;
@synthesize iTunesUpdater = _iTunesUpdater;
@synthesize lastFmUpdater = _lastFmUpdater;
@synthesize lastFmAppUpdater = _lastFmAppUpdater;
@synthesize mogUpdater = _mogUpdater;
@synthesize rdioUpdater = _rdioUpdater;
@synthesize spotifyUpdater = _spotifyUpdater;
@synthesize timerCounter = _timerCounter;

- (id)init
{
    if ((self = [super init]))
    {
        // Ping the timer once every second for the life of the application.
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
            target:self selector:@selector(pingTimer) userInfo:nil repeats:YES];
    }

    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)resetTimer
{
    self.timerCounter = 0;
}

// Hit once per second for the life of the application. Filter pings depending on the
// updater, or sleepedness.
- (void)pingTimer
{
    if (!self.isSleeping && self.currentSongUpdater.updateFrequency > 0 &&
        (self.timerCounter % self.currentSongUpdater.updateFrequency) == 0)
    {
        // Safe to update.
//        NSLog(@"PING!! (%lu)", self.timerCounter);
        [self updateCurrentTrack];
    }
    else
    {
//        NSLog(@"Skipping ping (%lu).", self.timerCounter);
    }

    self.timerCounter += 1;
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
//        self.statusItem.title = @"π";
        self.statusItem.highlightMode = YES;
        self.statusItem.image = [NSImage imageNamed:@"menubar-icon-playing.png"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"menubar-icon-alt.png"];
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

    // Works for hide, but disables shortcut. Nuts.
//    [[NSRunningApplication currentApplication] hide];
}

// Update window visibility if changed.
- (void)showWindow:(BOOL)showWindow
{
    self.isSleeping = !showWindow;

    if (showWindow)
    {
        if (![self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Sleep SkronkFM";
            self.showHideStatusbarItem.title = @"Sleep SkronkFM";
            [self fadeInWindow];

            // Don't update here after all. Causes issues with quick hide/show.
            [self resetTimer];
        }
    }
    else
    {
        // If window is still visible, hide it.
        if ([self windowIsVisible])
        {
            self.showHideMenuItem.title = @"Wake SkronkFM";
            self.showHideStatusbarItem.title = @"Wake SkronkFM";
            [self fadeOutWindow];
        }
    }
}

- (void)startNetworkAnimation
{
    if (self.currentSongUpdater.isServiceRemote)
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.fromValue = [NSNumber numberWithFloat:kServiceIconMaxAlpha];
        animation.toValue = [NSNumber numberWithFloat:kServiceIconDimAlpha];
        animation.duration = 0.5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.autoreverses = YES;
        animation.repeatCount = 100;

        [self.serviceIcon.layer addAnimation:animation forKey:@"opacity"];
    }
}

- (void)endNetworkAnimation
{
    if (self.currentSongUpdater.isServiceRemote)
    {
        [self.serviceIcon.layer removeAnimationForKey:@"opacity"];
    }
}

- (void)showServiceUp
{
    [[self.serviceIcon animator] setAlphaValue:kServiceIconMaxAlpha];
}

- (void)showServiceDown
{
    [[self.serviceIcon animator] setAlphaValue:kServiceIconDimAlpha];
}

- (NSMutableAttributedString *)trackDisplayText:(FFMSong *)currentSong coloredText:(BOOL)colored
{
    NSMutableAttributedString *displayText = nil;

    BOOL hasArtist = currentSong.artist.length > 0;
    BOOL hasAlbum = currentSong.album.length > 0;
    BOOL hasTrack = currentSong.track.length > 0;

    // If we don't already have track text (not "Loading..."), load the last track played previously.
    BOOL firstLoad = [self.label.stringValue isEqualToString:@"Loading..."];
    
    BOOL errorLoading = currentSong.errorText != nil;

    if (errorLoading)
    {
        displayText = [[NSMutableAttributedString alloc] initWithString:currentSong.errorText];
    }
    else if (firstLoad || currentSong.isPlaying)
    {
        displayText = [[NSMutableAttributedString alloc] init];

        NSColor *highlightColor = colored ? [NSColor colorWithCalibratedWhite:0.9 alpha:1.0] : [NSColor grayColor];
        NSDictionary *white = [NSDictionary dictionaryWithObject:highlightColor forKey:NSForegroundColorAttributeName];
        NSDictionary *gray = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont fontWithName:@"Helvetica" size:13.0], NSFontAttributeName,
            [NSNumber numberWithFloat:0.9f], NSBaselineOffsetAttributeName,
            [NSColor grayColor], NSForegroundColorAttributeName,
            nil];

        NSAttributedString *fancyString;

        // White real text, gray join text, bold artist name.
        if (hasTrack)
        {
//            NSString *plainText = [NSString stringWithFormat:@"\"%@\"", nowPlaying.track];
            fancyString = [[NSAttributedString alloc] initWithString:currentSong.track attributes:white];
            [displayText appendAttributedString:fancyString];
        }

        if (hasArtist)
        {
            fancyString = [[NSAttributedString alloc] initWithString:@" by " attributes:gray];
            [displayText appendAttributedString:fancyString];

            fancyString = [[NSAttributedString alloc] initWithString:currentSong.artist attributes:white];
            [displayText appendAttributedString:fancyString];
        }

        if (hasAlbum)
        {
            fancyString = [[NSAttributedString alloc] initWithString:@" on " attributes:
                gray];
            [displayText appendAttributedString:fancyString];

            fancyString = [[NSAttributedString alloc] initWithString:currentSong.album attributes:
                white];
            [displayText appendAttributedString:fancyString];
        }
    }
    else
    {
        // Gray out current text. If we don't already have track text (not "Loading...")
        // load the last track played previously.s
        NSAttributedString *labelText = self.label.attributedStringValue;
        displayText = [[NSMutableAttributedString alloc] initWithAttributedString:labelText];

        NSDictionary *gray = [NSDictionary dictionaryWithObjectsAndKeys:
//            [NSFont fontWithName:@"Helvetica" size:14.0], NSFontAttributeName,
            [NSColor grayColor], NSForegroundColorAttributeName,
            nil];
        NSRange range = NSMakeRange(0, displayText.length);
        [displayText setAttributes:gray range:range];
    }

    return displayText;
}

- (void)adjustWindowSize
{
    NSRect newFrame = self.window.frame;

    // Settings.
    BOOL showNetworkAvailability = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowNetworkAvailability];
    BOOL transparentBackground = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceTransparentBackground];
    BOOL autosizeToFit = YES; //[[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAutosizeToFit];

    NSRect labelRect = self.label.frame;

    CGFloat paddingBeforeText = labelRect.origin.x;  // 42
    CGFloat paddingAfterText = showNetworkAvailability ? 38 : 12; // 38 with 26px service icon, or 12.
    CGFloat padding = paddingBeforeText + paddingAfterText + 5;

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
        if (self.label.frame.size.width != labelRect.size.width)
        {
//            NSLog(@"Resizing text to %@", NSStringFromRect(labelRect));
            [self.label setFrame:labelRect];
//            [[self.label animator] setFrame:labelRect];
        }

        // Set new window width.
        newFrame.size.width = windowWidth;
    }
    else
    {
        // Hardcoded window size.
        newFrame.size.width = 640;
        labelRect.size.width = 564;
        self.label.frame = labelRect;
    }
    [self.label sizeToFit];

    [self resizeWindowTo:newFrame];
}

- (void)updateCurrentTrack
{
    // Make sure we have the current best music service.
    [self checkServices];

    // TODO: Move last.fm username lookup to checkServices (skip last.fm).
    NSString *lastFmUsername = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];
    if (lastFmUsername == nil)
    {
//        NSLog(@"Username not set...skipping update.");
        return;
    }

    // TODO: Move network check to checkServices (skip last.fm).
    BOOL showNetworkAvailability = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceShowNetworkAvailability];
    if (showNetworkAvailability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startNetworkAnimation];
        });
    }

    // Run in background.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Grab the current song from the current music service.
        self.currentSong = [self.currentSongUpdater fetchCurrentSong];

        if (self.currentSong.errorText == nil)
        {
            // Succeeded, got a song.
            NSMutableAttributedString *displayText = [self trackDisplayText:self.currentSong coloredText:self.currentSong.isPlaying];

            // Back on main thread...
            dispatch_async(dispatch_get_main_queue(), ^{
                // If we have something new to report, show it.
                if (displayText /*&& ![displayText.string isEqualToString:self.label.stringValue]*/)
                {
                    self.label.attributedStringValue = displayText;
                    [self adjustWindowSize];
                }

                // Update service icon visibility.
                if (showNetworkAvailability)
                {
                    [self showServiceUp];
                }

                // Hide window when not playing and autohide is on.
                BOOL hideWhenNotPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceAutohide];
                BOOL hideWindow = !self.currentSong.isPlaying && hideWhenNotPlaying;
                [self showWindow:!hideWindow];

                // Stop pulsing service icon.
                if (showNetworkAvailability)
                {
                    [self endNetworkAnimation];
                }
            });

            // Fetch album art, synchronously, while the above block also executes.
            // Only update if we're currently playing, and the image URL has changed to something new.
            // But if currentlyPlaying has nil URL, we want to clear out the image.
            if (self.currentSong && self.currentSong.isPlaying)
            {
                NSImage *albumImage = nil;
                if (self.currentSong.albumImage)
                {
                    albumImage = self.currentSong.albumImage;
                }
                else if (self.currentSong.artSmallUrl == nil)
                {
                    // Have a live track, with no art.
                    self.currentAlbumArtURL = nil;
                    albumImage = self.missingArt;
                }
                else
                {
                    BOOL shouldUpdateArt = ![self.currentAlbumArtURL isEqual:self.currentSong.artSmallUrl];
                    if (shouldUpdateArt)
                    {
//                        NSLog(@"Downloading new album art...");
                        NSURL *artUrl = self.currentSong.artSmallUrl;
                        self.currentAlbumArt = [[NSImage alloc] initWithContentsOfURL:artUrl];
                        if (self.currentAlbumArt)
                        {
                            // Only valid art counts.
                            self.currentAlbumArtURL = self.currentSong.artSmallUrl;
                        }
                        albumImage = self.currentAlbumArt ? self.currentAlbumArt : self.missingArt;
                    }
                }

                // Update album image back on main thread.
                if (albumImage)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.art.image = albumImage;
                    });
                }
            }
            else
            {
//            self.statusItem.image = [NSImage imageNamed:@"menubar-icon.png"];
            }
        }
        else
        {
            // Something bad happened, probably network.
            __weak NSString *errString = self.currentSong.errorText;
            NSLog(@"%@", errString);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Display error text in UI.
                NSAttributedString *displayString = [[NSAttributedString alloc] initWithString:errString];
                self.label.attributedStringValue = displayString;
                [self adjustWindowSize];

                if (showNetworkAvailability)
                {
                    [self endNetworkAnimation];
                    [self showServiceDown];
                }
            });
        }
    });
}

// Watch preferences for changes.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults])
    {
        if ([keyPath isEqualToString:kPreferenceAutohide])
        {
//            NSLog(@"Reloading current track after changing %@", keyPath);
            [self resetTimer];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceLastFmUsername])
        {
//            NSLog(@"Reloading current track after changing %@", keyPath);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.label.stringValue = @"Loading...";
                self.art.image = self.missingArt;

                [self resetTimer];
            });
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
            self.roundedView.needsDisplay = YES;
            [self adjustWindowSize];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceShowNetworkAvailability])
        {
            // Toggle showing service icon.
            BOOL shouldShowIcon = [[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 1;
            if (shouldShowIcon)
            {
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
//    NSLog(@"Preference modifiers: (%lu %lu)", hideCode, SRCocoaToCarbonFlags(hideFlags));

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
    
    // Skip toggling show/hide if already hidden and clicked Close menu again.
    // Don't want Close to show the window.
    BOOL alreadyClosed = !wasVisible && [sender respondsToSelector:@selector(title)] && [[sender title] isEqualToString:@"Close"];
    if (!alreadyClosed)
    {
        [self showWindow:!wasVisible];
    }
}

- (IBAction)showHelpClicked:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.skronkapp.com/help"]];
}

- (IBAction)preferencesClicked:(id)sender
{
    if (self.preferencesController == nil)
    {
        self.preferencesController = [[PreferencesController alloc] init];
    }

    [self.preferencesController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [self.preferencesController.window makeKeyAndOrderFront:self];
}

- (IBAction)openLastFmClicked:(id)sender
{
    NSString *urlString = [self.currentlyPlaying valueForProperty:@"recenttracks.track[0].url"];
    if (urlString)
    {
        NSURL *url = [NSURL URLWithString:urlString];
//        NSLog(@"Open in last.fm: %@", url);
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (IBAction)openUserClicked:(id)sender
{
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];
    NSString *urlString = [NSString stringWithFormat:@"http://www.last.fm/user/%@", username];
    if (urlString)
    {
        NSURL *url = [NSURL URLWithString:urlString];
//        NSLog(@"Open in last.fm: %@", url);
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)awakeFromNib
{
    // Hide window so we don't get a jump when we restore the window position.
    [self.window setAlphaValue:0];
    self.roundedView.backgroundImage = [NSImage imageNamed:@"concrete-background"];
    self.backgroundWidth = self.roundedView.backgroundImage.size.width;
    self.missingArt = [NSImage imageNamed:@"album-art-missing.png"];

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
        [NSNumber numberWithBool:YES], kPreferenceAutosizeToFit,
        [NSNumber numberWithBool:YES], kPreferenceShowInMenubar,
        [NSNumber numberWithBool:NO], kPreferenceTransparentBackground,
        [NSNumber numberWithBool:YES], kPreferenceShowNetworkAvailability,
//        @"woot", kPreferenceLastFmUsername,
        nil
    ];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)checkApplications
{
    NSLog(@"Scanning for applications.");
}

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    NSLog(@"AppleScript error: %@", [error localizedDescription]);
    return nil;
}

- (void)checkServices
{
    FFMSongUpdater *oldUpdater = self.currentSongUpdater;

    // Determine which music service we should be watching. Herein lies the magic.
    // If a local app is playing, always pick that. However, if a local app is running
    // but not playing, but last.fm is, go with that.

    if (self.iTunesUpdater.isServiceAvailable && self.iTunesUpdater.isServicePlaying)
    {
        self.currentSongUpdater = self.iTunesUpdater;
    }
    else if (self.spotifyUpdater.isServiceAvailable && self.spotifyUpdater.isServicePlaying)
    {
        self.currentSongUpdater = self.spotifyUpdater;
    }
    else if (self.rdioUpdater.isServiceAvailable && self.rdioUpdater.isServicePlaying)
    {
        self.currentSongUpdater = self.rdioUpdater;
    }
    else if (self.mogUpdater.isServiceAvailable && self.mogUpdater.isServicePlaying)
    {
        // Pause not supported, so lower priority.
        self.currentSongUpdater = self.mogUpdater;
    }
//    else if (self.lastFmAppUpdater.isServiceAvailable && self.lastFmAppUpdater.isServicePlaying)
//    {
//        // Pause not supported, so lower priority.
//        self.currentSongUpdater = self.lastFmAppUpdater;
//    }
    else
    {
        // Fall back last on remote last.fm web service.
        self.currentSongUpdater = self.lastFmUpdater;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentSongUpdater != oldUpdater)
        {
            // Switched to a different service. Clear out old service junk.
            self.art.image = self.missingArt;
            [self resetTimer];
        }
        self.serviceIcon.image = self.currentSongUpdater.icon;
    });
}

- (void)initMusicServices:(NSString *)lastFmUsername
{
    self.lastFmUpdater = [[FFMLastFMUpdater alloc] initWithUserName:lastFmUsername apiKey:@"3a36e88356d8d90aee7a012c6abccae1"];
    self.lastFmUpdater.icon = [NSImage imageNamed:@"last.fm-service"];

    self.iTunesUpdater = [[FFMITunesUpdater alloc] init];
    self.iTunesUpdater.icon = [NSImage imageNamed:@"iTunes-service"];
    self.iTunesUpdater.updateFrequency = 5;

    self.lastFmAppUpdater = [[FFMLastFmAppUpdater alloc] init];
    self.lastFmAppUpdater.icon = [NSImage imageNamed:@"audioscrobbler-service"];
    self.lastFmAppUpdater.updateFrequency = 5;

    self.mogUpdater = [[FFMMogUpdater alloc] init];
    self.mogUpdater.icon = [NSImage imageNamed:@"Mog-service"];
    self.mogUpdater.updateFrequency = 5;

    self.rdioUpdater = [[FFMRdioUpdater alloc] init];
    self.rdioUpdater.icon = [NSImage imageNamed:@"Rdio-service"];
    self.rdioUpdater.updateFrequency = 5;

    self.spotifyUpdater = [[FFMSpotifyUpdater alloc] init];
    self.spotifyUpdater.icon = [NSImage imageNamed:@"Spotify-service"];
    self.spotifyUpdater.updateFrequency = 5;

    [self checkServices];
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

    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];

    [self initMusicServices:username];

    self.art.image = self.missingArt;
    [self resetTimer];

    // If not last.fm username set, bring up Preferences dialog with text field focused.
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
    
    [self checkApplications];
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
