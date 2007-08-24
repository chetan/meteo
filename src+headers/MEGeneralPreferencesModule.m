//
//  MEGeneralPreferencesModule.m
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


#import "MEGeneralPreferencesModule.h"

NSString *MEAnimatesUpdatesDefaultsKey      = @"animateUpdates";
NSString *MEUpdatesAutomaticallyDefaultsKey = @"updatesAutomatically";
NSString *MEShowNextUpdateTimeDefaultsKey   = @"showNextUpdateTime";
NSString *MECyclesAutomaticallyDefaultsKey  = @"cyclesAutomatically";
NSString *MEAutoUpdateTimeDefaultsKey       = @"autoUpdateTime";
NSString *MECycleUpdateTimeDefaultsKey      = @"cycleUpdateTime";
NSString *MEAutoUpdateSoundDefaultsKey      = @"autoUpdateSound";
NSString *MEAutoRotateSoundDefaultsKey      = @"autoRotateSound";
NSString *MECheckNewVersionsDefaultsKey     = @"checkNewVersions";


@implementation MEGeneralPreferencesModule
#pragma mark - Inheritted from NSPreferenceModule -
/**
* Image to display in the preferences toolbar
 * 32x30 pixels (72 DPI) TIFF
 */
- (NSImage *) imageForPreferenceNamed:(NSString *)_name 
{
	return [[[NSImage imageNamed:@"MEGeneralPreferences"] retain] autorelease];
}

/**
* Override to return the name of the relevant nib
 */
- (NSString *) preferencesNibName 
{
	return @"MEGeneralPreferences";
}

- (BOOL) hasChangesPending
{
	return NO;
}

- (BOOL) isResizable 
{
	return NO;
}

- (void) initializeFromDefaults 
{ // load prefs and setup IBOutlets accordingly
	[self registerDefaults];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	if ( [defs boolForKey:MEAnimatesUpdatesDefaultsKey])
		[animateUpdatesCheckBox setState:NSOnState];
	else [animateUpdatesCheckBox setState:NSOffState];
	
	if ( [defs boolForKey:MEUpdatesAutomaticallyDefaultsKey] )
		[updateCheckBox setState:NSOnState];
	else [updateCheckBox setState:NSOffState];
	
	if ( [defs boolForKey:MEShowNextUpdateTimeDefaultsKey] )
		[showNextUpdateTime setState:NSOnState];
	else [showNextUpdateTime setState:NSOffState];
	
	if ( [defs boolForKey:MECyclesAutomaticallyDefaultsKey] )
		[rotateCheckBox setState:NSOnState];
	else [rotateCheckBox setState:NSOffState];
	
	[updateTimeSlider setIntValue:[defs integerForKey:MEAutoUpdateTimeDefaultsKey]];
	[rotateTimeSlider setIntValue:[defs integerForKey:MECycleUpdateTimeDefaultsKey]];
	
	// sound menus
	[self populateSoundMenu:autoUpdateSoundPopUp];
	[self populateSoundMenu:autoRotateSoundPopUp];
	
	[autoUpdateSoundPopUp selectItemWithTitle:[defs stringForKey:MEAutoUpdateSoundDefaultsKey]];
	[autoRotateSoundPopUp selectItemWithTitle:[defs stringForKey:MEAutoRotateSoundDefaultsKey]];
	
	if ( [defs boolForKey:MECheckNewVersionsDefaultsKey] )
		[checkForNewVersion setState:NSOnState];
	else [checkForNewVersion setState:NSOffState];
	
	// the startup item information
	[defs addSuiteNamed:@"loginwindow"];

	if ( [[defs objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self meteoDescription]] ) 
		[launchAtLogin setState:NSOnState];
	else [launchAtLogin setState:NSOffState];

	[defs synchronize]; // saves default values in case new ones were added inside validateDefaultNamed
	
	
	// interface
	[self rotateCityCheckbox:self];
	[self updateCityCheckbox:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playAutoUpdateSound)
												 name:@"MEAutoUpdateComplete" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playAutoRotateSound)
												 name:@"MEAutoRotateComplete" object:nil];
}

- (BOOL)moduleCanBeRemoved 
{	
	return YES;
}

- (BOOL)preferencesWindowShouldClose
{	
	return YES;
}


#pragma mark Interface Methods

// Interface Methods
- (BOOL) animateUpdates
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAnimatesUpdatesDefaultsKey];
}

- (BOOL) updatesAutomatically
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEUpdatesAutomaticallyDefaultsKey];
}

- (BOOL) rotatesAutomatically
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MECyclesAutomaticallyDefaultsKey];
}

- (BOOL) showNextUpdateTime
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEShowNextUpdateTimeDefaultsKey];
}


- (int) automaticUpdateTime
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:MEAutoUpdateTimeDefaultsKey];
}

- (int) automaticRotateTime
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:MEAutoRotateSoundDefaultsKey];
}

#pragma mark -

- (void) playAutoUpdateSound
{
	[self soundMenuClicked:autoUpdateSoundPopUp];
}

- (void) playAutoRotateSound
{
	[self soundMenuClicked:autoRotateSoundPopUp];
}
#pragma mark -
- (BOOL) launchAtStartup
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs addSuiteNamed:@"loginwindow"];
	
	return ( [[defs objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self meteoDescription]] );	
}

- (BOOL) checkForNewVersionAtStartup
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"checkNewVersions"] boolValue];	
}

#pragma mark Interface Actions

// called whenever a button is clicked or a text field is changed.
- (IBAction) actionPerformed:(id)sender
{
	[self savePreferences];
	if (sender == updateTimeSlider) // if the sliders changed, then must reestablish the timers.
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MEReestablishAutoUpdateTimer" object:nil];
	}
	else if (sender == rotateTimeSlider)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MEReestablishAutoRotateTimer" object:nil];
	}
}

- (IBAction) displayHelp:(id)sender
{
	
}

// this method is meant to be a detached thread, because things could take quite a while
// if the server is busy.
- (IBAction) checkForNewVersionNow:(id)sender
{
	// this is just so much easier
	NSString *thisVersion = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]; // Get the application bundle version
	NSDictionary *versionxml = [NSDictionary dictionaryWithContentsOfURL:
		[NSURL URLWithString:@"http://heat-meteo.sourceforge.net/version.xml"]];

	if (!versionxml)
	{ // check to see that we had a successful download
		NSLog(@"Unable to retrieve version from the server.");
		return;
	}
	NSString *newVer = [versionxml objectForKey:@"version"];
#ifdef DEBUG
	NSLog(@"This version is %@, the new version is %@", thisVersion, newVer);
#endif
	if (newVer && ![newVer isEqualToString:thisVersion])
	{ // then its a new version.  We're not going to count backwards!
		int returnCode = NSRunInformationalAlertPanel(NSLocalizedString(@"New Version",@""),
													  [NSString stringWithFormat:NSLocalizedString(@"A new version of Meteo (%@) is available; would you like to visit the web site?",@""),newVer],
													  NSLocalizedString(@"Visit Web Site",@""), 
													  NSLocalizedString(@"Cancel",@""),
													  nil);
		if (returnCode = NSAlertDefaultReturn) // visit website
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sourceforge.net/projects/heat-meteo/"]];
    }
}

#pragma mark -

- (IBAction) showNextUpdateTimeClicked:(id)sender
{
	[self actionPerformed:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MERedrawMenu" object:nil];
}

- (IBAction) updateCityCheckbox:(id)sender
{
	if ([updateCheckBox state] == NSOnState)
	{
		[updateTimeSlider setEnabled:YES];
		[showNextUpdateTime setEnabled:YES];
		[autoUpdateSound setTextColor:[NSColor blackColor]];
		[autoUpdateSoundPopUp setEnabled:YES];
	}
	else
	{
		[updateTimeSlider setEnabled:NO];
		[showNextUpdateTime setEnabled:NO];
		[autoUpdateSound setTextColor:[NSColor grayColor]];
		[autoUpdateSoundPopUp setEnabled:NO];
	}
	
	if (sender == updateCheckBox)
		[self actionPerformed:sender];
}

- (IBAction) rotateCityCheckbox:(id)sender
{
	if ([rotateCheckBox state] == NSOnState)
	{
		[rotateTimeSlider setEnabled:YES];
		[autoRotateSound setTextColor:[NSColor blackColor]];
		[autoRotateSoundPopUp setEnabled:YES];	}
	else
	{	
		[rotateTimeSlider setEnabled:NO];	
		[autoRotateSound setTextColor:[NSColor grayColor]];
		[autoRotateSoundPopUp setEnabled:NO];
	}

	if (sender == rotateCheckBox)
		[self actionPerformed:sender];
}

- (IBAction) updateSliderMoved:(id)sender
{
//	[self actionPerformed:sender];
	[updateTime setStringValue:[sender stringValue]];
}

- (IBAction) rotateSliderMoved:(id)sender
{
//	[self actionPerformed:sender];
	[rotateTime setStringValue:[sender stringValue]];
}

- (IBAction) soundMenuClicked:(id)sender
{
	// pick up the name from the menu
    NSString *name;
    name = [sender titleOfSelectedItem];
	if (![name isEqualToString:@"None"])
		[[NSSound soundNamed: name] play];
	[self actionPerformed:sender];
}


#pragma mark Interfacing with Others

// opposite of -initializeFromDefaults
//
// Thanks to Karl Adam of the Growl team for code to make this happen.  Taken from GrowlPref.m
// I really appreciate it - jrc
- (void) savePreferences
{ // must update the values from the interface
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	[defs setBool:([animateUpdatesCheckBox state] == NSOnState)
			 forKey:MEAnimatesUpdatesDefaultsKey];
	
	[defs setBool:([updateCheckBox state] == NSOnState)
			 forKey:MEUpdatesAutomaticallyDefaultsKey];
	[defs setBool:([showNextUpdateTime state] == NSOnState)
			 forKey:MEShowNextUpdateTimeDefaultsKey];
	[defs setBool:([rotateCheckBox state] == NSOnState)
			 forKey:MECyclesAutomaticallyDefaultsKey];
	
	[defs setInteger:[updateTimeSlider intValue] forKey:MEAutoUpdateTimeDefaultsKey];
	[defs setInteger:[rotateTimeSlider intValue] forKey:MECycleUpdateTimeDefaultsKey];
	
	// sounds
	[defs setObject:[autoUpdateSoundPopUp titleOfSelectedItem] forKey:MEAutoUpdateSoundDefaultsKey];
	[defs setObject:[autoRotateSoundPopUp titleOfSelectedItem] forKey:MEAutoRotateSoundDefaultsKey];
		
	[defs setBool:([checkForNewVersion state] == NSOnState)
			 forKey:MECheckNewVersionsDefaultsKey];
		
	// sync the startup item information
	[defs addSuiteNamed:@"loginwindow"];
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSMutableArray *loginItems = [[[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy] autorelease]; //it lies, its an array
	NSDictionary *meteoDesc = [self meteoDescription];
	
	if ( [launchAtLogin state] == NSOnState )
	{// add it if its not already there
		if (![[defs objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self meteoDescription]])
			[loginItems addObject:meteoDesc];
	}
	else
	{// shouldn't cause a problem if its not already there
		[loginItems removeObject:meteoDesc];
	}
	
	[loginWindowPrefs setObject:[NSArray arrayWithArray:loginItems]
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];

	// save and finish
	[defs synchronize];	
}

- (void)registerDefaults
{
	static BOOL defaultsHaveBeenRegistered = NO;
	
	if (!defaultsHaveBeenRegistered)
	{
		NSUserDefaults *defaults        = [NSUserDefaults standardUserDefaults];
		NSDictionary   *generalDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],
			MEAnimatesUpdatesDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEUpdatesAutomaticallyDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEShowNextUpdateTimeDefaultsKey,
			[NSNumber numberWithBool:NO],
			MECyclesAutomaticallyDefaultsKey,
			[NSNumber numberWithInt:15],
			MEAutoUpdateTimeDefaultsKey,
			[NSNumber numberWithInt:15],
			MECycleUpdateTimeDefaultsKey,
			NSLocalizedString(@"None",@""),
			MEAutoUpdateSoundDefaultsKey,
			NSLocalizedString(@"None",@""),
			MEAutoRotateSoundDefaultsKey,
			[NSNumber numberWithBool:YES],
			MECheckNewVersionsDefaultsKey,
			nil];
		
		[defaults registerDefaults:generalDefaults];
		[defaults synchronize];
		
		defaultsHaveBeenRegistered = YES;
	}
}

#pragma mark Internal methods
- (NSDictionary *)meteoDescription 
{
	if(!cachedMeteoDescription) 
	{
		NSString *meteoPath = [[NSBundle mainBundle] bundlePath];
		
		cachedMeteoDescription = [[NSDictionary alloc] initWithObjectsAndKeys:
			meteoPath, [NSString stringWithString:@"Path"],
			[NSNumber numberWithBool:NO], [NSString stringWithString:@"Hide"],
			nil];
	}
	return cachedMeteoDescription;
}

// Makes sure that the default exists, and if it doesn't, then this function creates the defaults
- (id) validateDefaultNamed:(NSString *)name defaultValue:(id)def
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	if ([defs objectForKey:name] == nil)
	{
		[defs setObject:def forKey:name];
	}
	return [defs objectForKey:name];
}

- (void) populateSoundMenu:(NSPopUpButton *)soundNamesPopup
{
    // clean out any junk left by Interface Builder
    [soundNamesPopup removeAllItems];
	[soundNamesPopup addItemWithTitle:@"None"];
	[[soundNamesPopup menu] addItem:[NSMenuItem separatorItem]];
	
    // pick up stuff in /System/Library/Sounds and ~/Libraray/Sounds
	NSArray *directories = [NSArray arrayWithObjects:@"/System/Library/Sounds",
		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Sounds"],nil];
	NSEnumerator *directoriesItr = [directories objectEnumerator];
	NSString     *currentDirectory;
	
	while (currentDirectory = [directoriesItr nextObject])
	{
		NSArray *dirContents;
		dirContents = [[NSFileManager defaultManager]
				  directoryContentsAtPath: currentDirectory];
		
		NSEnumerator *enumerator;
		enumerator = [dirContents objectEnumerator];
		
		NSString *filename;
		while (filename = [enumerator nextObject]) {
			
			// test the extension against NSSound's file types array
			NSString *extension;
			extension = [filename pathExtension];
			
			int index;
			index = [[NSSound soundUnfilteredFileTypes]
				indexOfObject: extension];
			
			// it's a match!  add just the title (without the extension)
			// to the menu
			if (index != NSNotFound) {
				
				NSMenuItem *newItem = [[[NSMenuItem alloc] 
					initWithTitle:[filename stringByDeletingPathExtension]
						   action:NULL
					keyEquivalent:@""] autorelease];
				[newItem setRepresentedObject:[NSString stringWithFormat:@"%@/%@",currentDirectory,filename]];
					
				NSMenu *popupMenu = [soundNamesPopup menu];
				if ([popupMenu indexOfItemWithTitle:[newItem title]] == -1)
					[popupMenu addItem:newItem];
			}
		}
	}
}
@end
