//
//  MEWeatherAlertsPreferencesModule.m
//  Meteorologist
//
//  Created by Joseph Crobak on 09/11/2004.
//
//  Copyright (c) 2005 Joe Crobak and Meteorologist Group
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



#import "MEWeatherAlertsPreferencesModule.h"
#import "MEAppearancePreferencesModule.h"

const int MEAlertEmailFlag = 1;
const int MEAlertSongFlag  = 4;
const int MEBounceDockFlag = 8;

NSString *MEAlertOptionsDefaultsKey = @"alertOptions";
NSString *MEAlertSongDefaultsKey    = @"alertSong";
NSString *MEAlertEmailDefaultsKey   = @"alertEmail";

@implementation MEWeatherAlertsPreferencesModule
/**
* Image to display in the preferences toolbar
 * 32x30 pixels (72 DPI) TIFF
 */
- (NSImage *) imageForPreferenceNamed:(NSString *)_name 
{
	return [[[NSImage imageNamed:@"MEWeatherAlertPreferences"] retain] autorelease];
}

/**
* Override to return the name of the relevant nib
 */
- (NSString *) preferencesNibName 
{
	return @"MEWeatherAlertsPreferences";
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
{
	[self registerDefaults];
	// check buttons
	[emailButton setState:[self alertEmailEnabled]];
	[songButton setState:[self alertSongEnabled]];
	[bounceDockButton setState:[self bounceDockEnabled]];
	[bounceDockButton setEnabled:[[MEAppearancePreferencesModule sharedInstance] isInDock]];
	
	// saved values
	[self populateSoundMenu:songMenu];	
	[songMenu selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:MEAlertSongDefaultsKey]];	
	[emailAddress setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:MEAlertEmailDefaultsKey]];
}

- (BOOL)moduleCanBeRemoved 
{	
	return YES;
}

- (BOOL)preferencesWindowShouldClose
{	
	return YES;
}

#pragma mark Non-inheritted methods

- (int)alertOptions
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:MEAlertOptionsDefaultsKey];
}

- (BOOL)alertSongEnabled
{
	return (([self alertOptions] & MEAlertSongFlag) > 0);
}

- (BOOL)alertEmailEnabled
{
	return (([self alertOptions] & MEAlertEmailFlag) > 0);
}

- (BOOL)bounceDockEnabled
{
	return (([self alertOptions] & MEBounceDockFlag) > 0);
}

- (NSString *)alertEmailAddress
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MEAlertEmailDefaultsKey];
}

- (NSString *)song
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MEAlertSongDefaultsKey];
}

- (void)savePreferences
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int newAlertOptions = 0;
	if ([songButton state] == NSOnState)
		newAlertOptions = newAlertOptions | MEAlertSongFlag;
	if ([emailButton state] == NSOnState)
		newAlertOptions = newAlertOptions | MEAlertEmailFlag;
	if ([bounceDockButton state] == NSOnState)
		newAlertOptions = newAlertOptions | MEBounceDockFlag;
	
	[defaults setInteger:newAlertOptions forKey:MEAlertOptionsDefaultsKey];
	
	[defaults setObject:[songMenu itemAtIndex:[songMenu indexOfSelectedItem]] forKey:MEAlertSongDefaultsKey];
	[defaults setObject:[emailAddress stringValue] forKey:MEAlertEmailDefaultsKey];
	
	[defaults synchronize];
}

- (void)registerDefaults
{
	static BOOL defaultsHaveBeenRegistered = NO;
	
	if (!defaultsHaveBeenRegistered)
	{
		NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
		NSDictionary *alertDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:0],
			MEAlertOptionsDefaultsKey,
			@"",
			MEAlertEmailDefaultsKey,
			@"None",
			MEAlertSongDefaultsKey,
			nil];
		
		[defaults registerDefaults:alertDefaults];
		[defaults synchronize];
		
		defaultsHaveBeenRegistered = YES;
	}
}

#pragma mark IBActions

- (IBAction) showHelp:(id)sender
{
	
}

- (IBAction) actionPerformed:(id)sender 
{
	[self savePreferences];
}


#pragma mark Internal Methods

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
