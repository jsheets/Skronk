//
//  AppDelegate.m
//  SkronkSpike
//
//  Created by John Sheets on 10/2/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "AppDelegate.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"

NSString *kGlobalHotKey = @"Global Hot Key";

@implementation AppDelegate

@synthesize window = _window;
@synthesize statusMenu, trackArray;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
//    [self.window setLevel:kCGDesktopWindowLevel];
    
    NSURL *tracksURL = [[NSBundle mainBundle] URLForResource:@"sample-tracks" withExtension:@"plist"];
    NSLog(@"Tracks URL: %@", tracksURL);
    
    if (tracksURL)
    {
        self.trackArray = [NSDictionary dictionaryWithContentsOfURL:tracksURL];
        NSLog(@"Tracks: %@", self.trackArray);
    }
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

- (void)hotKeyPressed:(id)sender
{
    NSLog(@"Hot key pressed");
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
