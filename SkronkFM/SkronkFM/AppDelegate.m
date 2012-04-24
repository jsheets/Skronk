//
//  AppDelegate.m
//  SkronkFM
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NowPlaying.h"
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
//            [self updateCurrentTrack];
//            [self resetTimer];
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

- (NSMutableAttributedString *)trackDisplayText:(NowPlaying *)nowPlaying coloredText:(BOOL)colored
{
    NSMutableAttributedString *displayText = nil;

    BOOL hasArtist = nowPlaying.artist.length > 0;
    BOOL hasAlbum = nowPlaying.album.length > 0;
    BOOL hasTrack = nowPlaying.track.length > 0;

    // If we don't already have track text (not "Loading..."), load the last track played previously.
    BOOL firstLoad = [self.label.stringValue isEqualToString:@"Loading..."];
    
    BOOL errorLoading = nowPlaying.error != nil;

    if (errorLoading)
    {
        NSString *message = [NSString stringWithFormat:@"last.fm Error: %@", nowPlaying.error];
        displayText = [[NSMutableAttributedString alloc] initWithString:message];
    }
    else if (firstLoad || nowPlaying.isPlaying)
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
    if (self.isSleeping)
    {
//        NSLog(@"Sleeping...");
        return;
    }

    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceLastFmUsername];
    if (username == nil)
    {
//        NSLog(@"Username not set...skipping update.");
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=3a36e88356d8d90aee7a012c6abccae1&limit=2&user=%@&format=json", username];
    NSURL *url = [NSURL URLWithString:urlString];

//    NSLog(@"Looking up last.fm URL: %@", url);
    
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

        self.currentlyPlaying = [[NowPlaying alloc] initWithJson:responseString];

        displayText = [self trackDisplayText:self.currentlyPlaying coloredText:self.currentlyPlaying.isPlaying];

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
            BOOL hideWindow = !self.currentlyPlaying.isPlaying && hideWhenNotPlaying;
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
        if (self.currentlyPlaying.isPlaying)
        {
            if (self.currentlyPlaying.artSmallUrl == nil)
            {
                // Have a live track, with no art.
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.art.image = self.missingArt;
                });
            }
            else
            {
                BOOL shouldUpdateArt = ![self.currentAlbumArtURL isEqual:self.currentlyPlaying.artSmallUrl];
                if (shouldUpdateArt)
                {
//                    NSLog(@"Downloading new album art...");
                    self.currentAlbumArt = [[NSImage alloc] initWithContentsOfURL:self.currentlyPlaying.artSmallUrl];
                    if (self.currentAlbumArt)
                    {
                        // Only valid art counts.
                        self.currentAlbumArtURL = self.currentlyPlaying.artSmallUrl;
                    }

                    // Update album image back on main thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.art.image = self.currentAlbumArt ? self.currentAlbumArt : self.missingArt;
//                        self.statusItem.image = [NSImage imageNamed:@"menubar-icon-playing.png"];
                    });
                }
            }
        }
        else
        {
//            self.statusItem.image = [NSImage imageNamed:@"menubar-icon.png"];

        }
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSString *errString = [NSString stringWithFormat:@"Error updating last.fm status: %@", [error localizedDescription]];
        NSLog(@"%@", errString);

        dispatch_async(dispatch_get_main_queue(), ^{
            // Display error text in UI.
            NSAttributedString *displayString = [[NSAttributedString alloc] initWithString:errString];
            self.label.attributedStringValue = displayString;
            
            if (showNetworkAvailability)
            {
                [self endNetworkAnimation];
                [self showServiceDown];
            }
        });
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
        if ([keyPath isEqualToString:kPreferenceAutohide])
        {
//            NSLog(@"Reloading current track after changing %@", keyPath);
            [self updateCurrentTrack];
            [self resetTimer];
            return;
        }
        else if ([keyPath isEqualToString:kPreferenceLastFmUsername])
        {
//            NSLog(@"Reloading current track after changing %@", keyPath);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.label.stringValue = @"Loading...";
                self.art.image = self.missingArt;

                [self updateCurrentTrack];
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

    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    iTunes.delegate = self;
    if ([iTunes isRunning])
    {
        iTunesTrack *currentTrack = iTunes.currentTrack;
        if ([currentTrack exists])
        {
            NSLog(@"iTunes is currently playing '%@' by '%@' on '%@'.", 
                  currentTrack.name, currentTrack.artist, currentTrack.album);
        }
        else
        {
            NSLog(@"iTunes is running but not playing anything.");
        }
    }
    else
    {
        NSLog(@"iTunes is not running...skipping iTunes check.");
        
    }
}

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    NSLog(@"AppleScript error: %@", [error localizedDescription]);
    return nil;
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

    self.art.image = self.missingArt;
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
