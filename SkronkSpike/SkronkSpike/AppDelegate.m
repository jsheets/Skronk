//
//  AppDelegate.m
//  SkronkSpike
//
//  Created by John Sheets on 10/2/11.
//  Copyright (c) 2011 FourFringe. All rights reserved.
//

#import "AppDelegate.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "TrackViewController.h"

NSString *kGlobalHotKey = @"Global Hot Key";

@implementation AppDelegate

@synthesize window = _window;
@synthesize statusMenu, trackViewController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
//    [self.window setLevel:kCGDesktopWindowLevel];
    
    self.trackViewController = [[[TrackViewController alloc] init] autorelease];
    [self.window.contentView addSubview:self.trackViewController.view];
    
    // Inject view controller into responder chain.
    //    NSResponder *nextResponder = [self.window.contentView nextResponder];
    //    [self.window.contentView setNextResponder:self.trackViewController];
    //    [self.trackViewController setNextResponder:nextResponder];
    //    NSResponder *nextResponder = [self.window nextResponder];
    //    [self.window setNextResponder:self.trackViewController];
    //    [self.trackViewController setNextResponder:nextResponder];
    
//    self.window.initialFirstResponder = self.trackViewController.view;
    [self.window makeFirstResponder:self.trackViewController.view];
}

- (void)setupHotkeys
{
    // Modifiers: cmdKey, shiftKey, optionKey, controlKey
    
    // Cmd-Opt-Ctrl-g
    NSInteger keyCode = 5;
    NSInteger modifier = cmdKey + optionKey + controlKey;
    
    SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:keyCode modifiers:modifier];
    SGHotKey *hotKey = [[SGHotKey alloc] initWithIdentifier:kGlobalHotKey keyCombo:keyCombo target:self action:@selector(hotKeyPressed:)];
    [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
}

- (void)awakeFromNib
{
    [self setupHotkeys];
    
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    _statusItem.menu = self.statusMenu;
    _statusItem.title = @"SkronkSpike";
    _statusItem.highlightMode = YES;
//    _statusItem.image = nil;
}

- (void)nextTrack
{
    NSUInteger selection = self.trackViewController.arrayController.selectionIndex;
    NSUInteger count = [self.trackViewController.trackArray count];
    
    NSLog(@"Current Selection = %lu (of %lu)", selection, count);
    selection++;
    if (selection >= count)
    {
        selection = 0;
    }
    self.trackViewController.arrayController.selectionIndex = selection;
}

- (void)hotKeyPressed:(id)sender
{
    NSLog(@"Hot key pressed");
    [self nextTrack];
}

- (IBAction)statusClicked:(id)sender
{
    NSLog(@"Status clicked");
}

- (IBAction)growlClicked:(id)sender
{
    NSLog(@"Growl clicked");
}

@end
