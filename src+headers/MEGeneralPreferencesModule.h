//
//  MEGeneralPreferencesModule.h
//  Meteorologist
//
//  Created by Joseph Crobak on 09/11/2004.
//
//  Copyright (c) 2004 Joe Crobak and Meteorologist Group
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this 
//  software and associated documentation files (the "Software"), to deal in the Software 
//  without restriction, including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
//  permit persons to whom the Software is furnished to do so, subject to the following 
//  conditions:
//
//  The above copyright notice and this permission notice shall be included in all 
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
//  OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
//  OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"
#import "MELiveFeedbackSlider.h"

@interface MEGeneralPreferencesModule : NSPreferencesModule 
{	
	IBOutlet NSButton      *animateUpdatesCheckBox;
	IBOutlet NSButton      *updateCheckBox;
	IBOutlet MELiveFeedbackSlider *updateTimeSlider;
	IBOutlet NSTextField   *autoUpdateSound;
	IBOutlet NSPopUpButton *autoUpdateSoundPopUp;
	IBOutlet NSButton      *showNextUpdateTime;
	
	IBOutlet NSButton      *rotateCheckBox;
	IBOutlet MELiveFeedbackSlider *rotateTimeSlider;
	IBOutlet NSTextField   *autoRotateSound;
	IBOutlet NSPopUpButton *autoRotateSoundPopUp;	
		
	IBOutlet NSTextField *updateTime;
	IBOutlet NSTextField *rotateTime;
	
	IBOutlet NSButton    *launchAtLogin;
	
	IBOutlet NSButton    *checkForNewVersion;
	
	NSDictionary *cachedMeteoDescription;
}

// Interface Methods
- (BOOL) animateUpdates;

- (BOOL) updatesAutomatically;
- (BOOL) rotatesAutomatically;

- (BOOL) showNextUpdateTime;

- (int) automaticUpdateTime;
- (int) automaticRotateTime;

- (BOOL) launchAtStartup;

- (BOOL) checkForNewVersionAtStartup;

- (IBAction) actionPerformed:(id)sender; // called whenever a button is clicked or a text field is changed.
- (IBAction) displayHelp:(id)sender;
- (IBAction) checkForNewVersionNow:(id)sender;
- (IBAction) showNextUpdateTimeClicked:(id)sender;
- (IBAction) updateCityCheckbox:(id)sender;
- (IBAction) rotateCityCheckbox:(id)sender;
- (IBAction) updateSliderMoved:(id)sender;
- (IBAction) rotateSliderMoved:(id)sender;
- (IBAction) soundMenuClicked:(id)sender;

// Interfacing methods
- (void) savePreferences;
- (void)registerDefaults;

// Internal methods
- (NSDictionary *) meteoDescription;
- (id) validateDefaultNamed:(NSString *)name defaultValue:(id)def;
- (void) populateSoundMenu:(NSPopUpButton *)soundNamesPopup;

@end
