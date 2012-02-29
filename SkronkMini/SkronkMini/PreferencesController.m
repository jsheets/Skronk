//
//  PreferencesController.m
//  SkronkMini
//
//  Created by John Sheets on 2/14/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "PreferencesController.h"
#import "SRRecorderControl.h"
#import "SRCommon.h"

@implementation PreferencesController

@synthesize bar = _bar;
@synthesize generalPreferenceView = _generalPreferenceView;
@synthesize lastFmPreferenceView = _lastFmPreferenceView;
@synthesize lastFmTextField = _lastFmTextField;
@synthesize currentView = _currentView;

NSString *const kGeneralPrefsIdentifier = @"GeneralPrefsIdentifier";
NSString *const kLastFmPrefsIdentifer = @"LastFmPrefsIdentifer";

- (id)init
{
    if ((self = [super initWithWindowNibName:@"Preferences"]))
    {
        // Initialization code here.
    }

    return self;
}

- (void)awakeFromNib
{
    [self.window setContentSize:self.generalPreferenceView.frame.size];
    [self.window.contentView addSubview:self.generalPreferenceView];

    self.currentView = self.generalPreferenceView;
    [self.bar setSelectedItemIdentifier:@"General"];

}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)generalTabClicked:(id)sender
{

    if (self.currentView == self.generalPreferenceView)
    {
        NSLog(@"Already in General tab");
        return;
    }

    NSLog(@"Switching to General tab");

    [self.bar setSelectedItemIdentifier:@"General"];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];

    [self.lastFmTextField resignFirstResponder];
    [[[self.window contentView] animator] replaceSubview:self.currentView with:self.generalPreferenceView];
    self.currentView = self.generalPreferenceView;

    [NSAnimationContext endGrouping];
}

- (IBAction)lastFmTabClicked:(id)sender
{

    if (self.currentView == self.lastFmPreferenceView)
    {
        NSLog(@"Already in last.fm tab");
        return;
    }

    NSLog(@"Switching to last.fm tab");

    [self.bar setSelectedItemIdentifier:@"last.fm"];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];

    [[[self.window contentView] animator] replaceSubview:self.currentView with:self.lastFmPreferenceView];
    self.currentView = self.lastFmPreferenceView;

    [NSAnimationContext endGrouping];

    [self.lastFmTextField becomeFirstResponder];
}


#pragma mark -
#pragma mark SRShortcutControl delegate


- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;
{
    NSLog(@"New key combo: %@ (%lu)", SRStringForCocoaModifierFlagsAndKeyCode(newKeyCombo.flags, newKeyCombo.code), newKeyCombo.flags);
}

@end
