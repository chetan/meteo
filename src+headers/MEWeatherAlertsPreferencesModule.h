//
//  MEWeatherAlertsPreferencesModule.h
//  Meteorologist
//
//  Created by Joseph Crobak on 09/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

@interface MEWeatherAlertsPreferencesModule : NSPreferencesModule 
{
	IBOutlet NSButton      *emailButton;
	IBOutlet NSTextField   *emailAddress;
	
	IBOutlet NSButton      *songButton;
	IBOutlet NSPopUpButton *songMenu;
	
	IBOutlet NSButton      *bounceDockButton;
	
}

- (IBAction) actionPerformed:(id)sender; // called whenever a button is clicked or a text field is changed.
- (IBAction) showHelp:(id)sender;

- (int)alertOptions;
- (BOOL)alertSongEnabled;
- (BOOL)alertEmailEnabled;
- (BOOL)bounceDockEnabled;

- (NSString *)alertEmailAddress;
- (NSString *)song;

- (void)registerDefaults;

- (void) populateSoundMenu:(NSPopUpButton *)soundNamesPopup;

@end
