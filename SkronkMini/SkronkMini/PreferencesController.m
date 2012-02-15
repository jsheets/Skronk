//
//  PreferencesController.m
//  SkronkMini
//
//  Created by John Sheets on 2/14/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

@synthesize bar = _bar;
@synthesize generalPreferenceView = _generalPreferenceView;
@synthesize lastFmPreferenceView = _lastFmPreferenceView;

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
    // Set toolbar delegate to self.

}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

//- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
//{
//    return nil;
//}
//
//- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
//{
//    return nil;
//}
//
//- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
//{
//    return nil;
//}
//
//- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
//{
//    return [NSArray arrayWithObjects:kGeneralPrefsIdentifier, kLastFmPrefsIdentifer, nil];
//}

//- (void)toolbarWillAddItem:(NSNotification *)notification
//{
//
//}

//- (void)toolbarDidRemoveItem:(NSNotification *)notification
//{
//
//}

- (IBAction)generalTabClicked:(id)sender
{
    NSLog(@"GENERAL");
}

- (IBAction)lastFmTabClicked:(id)sender
{
    NSLog(@"LAST.FM");
}
@end
