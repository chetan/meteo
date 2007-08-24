//
//  MEAppearancePreferences.m
//  Meteorologist
//
//  Created by Joseph Crobak on 08/11/2004.
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


#import "MEAppearancePreferencesModule.h"
#import "MEPlug-inManager.h"
#import "NSUserDefaults+MEColorSupport.h"

NSString *MEAppearanceDisplayLocationDefaultsKey       = @"displayLocation";
NSString *MEAppearanceUnitsDefaultsKey                 = @"units";
NSString *MEAppearanceShowBothCFDefaultsKey            = @"showBothCF";
NSString *MEAppearanceHideCFDefaultsKey                = @"hideCF";
NSString *MEAppearanceDisplayTempDefaultsKey           = @"displayTemp";
NSString *MEAppearanceDisplayCityNameDefaultsKey       = @"displayCityName";
NSString *MEAppearanceDisplayMenuIconDefaultsKey       = @"displayMenuIcon"; //
NSString *MEAppearanceMenuFontNameDefaultsKey          = @"menuFontName";
NSString *MEAppearanceMenuFontSizeDefaultsKey          = @"menuFontSize";
NSString *MEAppearanceMenuColorDefaultskey             = @"menuColor";
NSString *MEAppearanceImageOpacityDefaultsKey          = @"imageOpacity";
NSString *MEAppearanceDockFontNameDefaultsKey          = @"dockFontName";
NSString *MEAppearanceDockFontColorDefaultsKey         = @"dockFontColor";
NSString *MEAppearanceDisplayTodayInSubmenuDefaultsKey = @"displayTodayInSubmenu";
NSString *MEAppearanceForecastDaysOnDefaultsKey        = @"forecastDaysOn";
NSString *MEAppearanceViewForecastInSubmenuDefaultsKey = @"viewForecastInSubmenu";
NSString *MEAppearanceForecastInlineDefaultsKey        = @"forecastInline";
NSString *MEAppearanceDisplayDayImageDefaultsKey       = @"displayDayImage";
NSString *MEAppearanceForecastDaysNumberDefaultsKey    = @"forecastDaysNumber";



@implementation MEAppearancePreferencesModule
- (id)init 
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)awakeFromNib
{
	[propertiesTable setAutosaveName:@"propertiesTable"];
	[propertiesTable registerForDraggedTypes:[NSArray arrayWithObjects:[propertiesTable autosaveName], nil]];

	[forecastPropertiesTable setAutosaveName:@"forecastPropertiesTable"];
	[forecastPropertiesTable registerForDraggedTypes:[NSArray arrayWithObjects:[forecastPropertiesTable autosaveName], nil]];

	// -- add the checkbox buttons
	NSButtonCell *cell = [[[NSButtonCell alloc] init] autorelease];
	[cell setButtonType:NSSwitchButton];
	[cell setTitle:@""];
	[cell setImagePosition:NSImageOverlaps];
	[cell setControlSize:NSSmallControlSize];

	[[propertiesTable tableColumnWithIdentifier:@"enabled"] setDataCell:cell];
	[[forecastPropertiesTable tableColumnWithIdentifier:@"enabled"] setDataCell:cell];
	// --
	[forecastPropertiesTable reloadData];
	[propertiesTable reloadData];
	
	[appearancesTabView selectFirstTabViewItem:self];

//	[self initializeFromDefaults];
}
#pragma mark - Inheritted from NSPreferenceModule -
/**
* Image to display in the preferences toolbar
 * 32x30 pixels (72 DPI) TIFF
 */
- (NSImage *) imageForPreferenceNamed:(NSString *)_name 
{
	return [[[NSImage imageNamed:@"MEAppearancePreferences"] retain] autorelease];
}

/**
* Override to return the name of the relevant nib
 */
- (NSString *) preferencesNibName 
{
	return @"MEAppearancePreferences";
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
	NSArray *allFonts = [[[NSFontManager sharedFontManager] availableFonts] sortedArrayUsingSelector:@selector(compare:)];
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	// General Tab
	[displayLocation selectCellWithTag:[defs integerForKey:MEAppearanceDisplayLocationDefaultsKey]];
	[units selectCellWithTag:[defs integerForKey:MEAppearanceUnitsDefaultsKey]];
	
	if ( [defs boolForKey:MEAppearanceShowBothCFDefaultsKey] )
		[showBothCF setState:NSOnState];
	else [showBothCF setState:NSOffState];
	
	if ( [defs boolForKey:MEAppearanceHideCFDefaultsKey] )
		[showTempUnits setState:NSOffState];
	else [showTempUnits setState:NSOnState];
	
	// -> MenuBar
	if ( [defs boolForKey:MEAppearanceDisplayTempDefaultsKey] )
		[displayTemp setState:NSOnState];
	else [displayTemp setState:NSOffState];
	
	if ( [defs boolForKey:MEAppearanceDisplayCityNameDefaultsKey] )
		[displayCityName setState:NSOnState];
	else [displayCityName setState:NSOffState];

	if ( [defs boolForKey:MEAppearanceDisplayMenuIconDefaultsKey] )
		[displayIcon setState:NSOnState];
	else [displayIcon setState:NSOffState];
	
	[menuFontName removeAllItems];
	[menuFontName addItemsWithTitles:allFonts];



	if ([allFonts indexOfObject:[defs objectForKey:MEAppearanceMenuFontNameDefaultsKey]] == NSNotFound)
	{ // this occurs when a saved font was disabled by the system/user and is not available
		[defs setObject:[[NSFont menuFontOfSize:0] fontName] forKey:MEAppearanceMenuFontNameDefaultsKey];
	}
	// at this point, menuFontName definitely exists
	[menuFontName selectItemWithTitle:[defs objectForKey:MEAppearanceMenuFontNameDefaultsKey]];
	
	// the contents of the menuFontSize popup is hard coded in the nib, so we only have to select
	//  the correct menuItem
	[menuFontSize selectItemWithTitle:[defs objectForKey:MEAppearanceMenuFontSizeDefaultsKey]];
	
	[menuColor setColor:[defs colorForKey:MEAppearanceMenuColorDefaultskey]];
	
	// -> Dock
	[dockImageOpacity setFloatValue:[defs floatForKey:MEAppearanceImageOpacityDefaultsKey]];

	[dockFontName removeAllItems];
	[dockFontName addItemsWithTitles:allFonts];
	// menuFontOfSize:0 returns a default sized font, but I don't really care, I'm just getting
	//   the font name
	if ([allFonts indexOfObject:[defs objectForKey:MEAppearanceDockFontNameDefaultsKey]] == NSNotFound)
	{ // this occurs when a saved font was disabled by the system/user and is not available
		[defs setObject:[[NSFont menuFontOfSize:0] fontName] forKey:MEAppearanceDockFontNameDefaultsKey];
	}
	// at this point, dockFontName definitely exists
	[dockFontName selectItemWithTitle:[defs objectForKey:MEAppearanceDockFontNameDefaultsKey]];

	[dockColor setColor:[defs colorForKey:MEAppearanceDockFontColorDefaultsKey]];
	
	// Menu Layout Tab
	if ( [defs boolForKey:MEAppearanceDisplayTodayInSubmenuDefaultsKey] )
		[currentConditionsInSubMenu setState:NSOnState];
	else [currentConditionsInSubMenu setState:NSOffState];
	
	//    propertiesDataSource
	[self initPropertiesDataSource];
	[self initForecastPropertiesDataSource];
	
	if ( [defs boolForKey:MEAppearanceForecastDaysOnDefaultsKey] )
		[enableExtendedForecast setState:NSOnState];
	else [enableExtendedForecast setState:NSOffState];
	if ( [defs boolForKey:MEAppearanceViewForecastInSubmenuDefaultsKey] )
		[extendedForecastInSubmenu setState:NSOnState];
	else [extendedForecastInSubmenu setState:NSOffState];
	if ( [defs boolForKey:MEAppearanceForecastInlineDefaultsKey] )
		[forecastOnOneLine setState:NSOnState];
	else [forecastOnOneLine setState:NSOffState];
	if ( [defs boolForKey:MEAppearanceDisplayDayImageDefaultsKey] )
		[showWeatherIcons setState:NSOnState];
	else [showWeatherIcons setState:NSOffState];
	
	[daysInForecast selectItemWithTitle:[NSString stringWithFormat:@"%i",
		[defs integerForKey:MEAppearanceForecastDaysNumberDefaultsKey]]]; 

	// this saves any newly added defaults
	[defs synchronize];
	// This enables/disables the interface correctly
	[self displayLocationChange:self];
	[self showTempAsBothClicked:self];
	[self enableExtendedForecastClicked:self];
	
}

- (void) willBeDisplayed
{
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

// this method enables or disables the Menu/Dock portions of the interface
//  based on which is selected in the "displayLocation" NSMatrix
- (IBAction) displayLocationChange:(id)sender
{	
	if (displayLocation != nil) 
	{
		int column = [displayLocation selectedColumn];
		BOOL enableMenuArea, enableDockArea;
		
		//NSLog(@"selected column: %i",column);
		
		if ( column == 0 || column == 2 )  // Menu || Both
			enableMenuArea = YES;
		else
			enableMenuArea = NO;
		
		// enable or disable Menu related options //
		[displayTemp setEnabled:enableMenuArea];
		[displayCityName setEnabled:enableMenuArea];
		[displayIcon setEnabled:enableMenuArea];
		[menuFontName setEnabled:enableMenuArea];
		[menuFontSize setEnabled:enableMenuArea];
		[menuColor setEnabled:enableMenuArea];
		
		if ( column == 1 || column == 2 ) // Dock || Both
			enableDockArea = YES;
		else
			enableDockArea = NO;
		
		// enable or disable Dock related options //
		[dockImageOpacity setEnabled:enableDockArea];
		[dockFontName setEnabled:enableDockArea];
		[dockColor setEnabled:enableDockArea];
				
		// write the LSUIElement to "Info.plist" //
		BOOL succesfulWrite;
		int oldLSUIValue = -1; // unknown until we read Info.plist
		int newLSUIValue = enableDockArea ? 0 : 1;
			
		NSString *plistPath = [NSString stringWithFormat:@"%@/%@",[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent],@"Info.plist"];
		NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
		
		// read old value from file.  it's either 0 or 1.  If the key is not in the plist, it is -1 //
		NSNumber *LSUIElementValue = [infoPlist objectForKey:@"LSUIElement"];
		if (LSUIElementValue != nil)
			oldLSUIValue = [LSUIElementValue intValue];
		
		//NSLog(@"Old val: %i, New val; %i",oldLSUIValue,newLSUIValue);
		if (oldLSUIValue != newLSUIValue) 
		{
			// "try" to set new LSUIElement value, if necessary. //
			[infoPlist setObject:[NSNumber numberWithInt:newLSUIValue] forKey:@"LSUIElement"];
			succesfulWrite = [infoPlist writeToFile:plistPath atomically:NO];
			if (!succesfulWrite)
			{
				NSRunAlertPanel(@"Error",@"In order to make changes to the display location, Meteorologist.app must be writeable.",@"OK",nil,nil);
				[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(displayLocationHelper) userInfo:nil repeats:NO];
				//		NSLog(@"oldIndex = %@, %@",oldIndex,[[whereToDisplay selectedCell] title]);
			}
			else
			{
				NSRunAlertPanel(@"Error",@"You have made changes to the display location of Meteo.  These changes won't take effect until Meteo is restarted.",@"OK",nil,nil);
				[NSTask launchedTaskWithLaunchPath:@"/usr/bin/touch" arguments:[NSArray arrayWithObject:[[NSBundle mainBundle] bundlePath]]];
				//[self outletAction:self];
			}
		}
		
		//if (sender != self) // don't want to save and generate menu during initializeFromDefaults
		//	[self actionPerformed:sender];
		if (sender != self)
			[self savePreferences];				
	}
}

// this method enables or disables the hideTempUnits NSButton based on
//  the state of showBothCF
- (IBAction) showTempAsBothClicked:(id)sender
{
	if ([showBothCF state] == NSOnState)
	{
		[showTempUnits setEnabled:NSOffState];
	}
	else
	{
		[showTempUnits setEnabled:NSOnState];
	}

	if (sender != self) // don't want to save and generate menu during initializeFromDefaults
		[self actionPerformed:sender];
}

// this method enables or disables the Extended Forecast portion of the interface
//  based on the state of enableExtendedForecast
- (IBAction) enableExtendedForecastClicked:(id)sender
{
	BOOL enableItems;
	
	if ([enableExtendedForecast state] == NSOnState)
	{
		enableItems = YES;
	}
	else
	{
		enableItems = NO;
	}
	
	[extendedForecastInSubmenu setEnabled:enableItems];
	[forecastOnOneLine setEnabled:enableItems];
	[showWeatherIcons setEnabled:enableItems];
	[daysInForecast setEnabled:enableItems];
	[forecastPropertiesDataSource setSelectable:enableItems];
	[forecastPropertiesDataSource setEditable:enableItems];
	[forecastPropertiesTable reloadData];
	
	if (sender != self) // don't want to save and generate menu during initializeFromDefaults
		[self actionPerformed:sender];
}

// called whenever a button is clicked or a text field is changed.
- (IBAction) actionPerformed:(id)sender
{
	//changesMade = YES;
	[self savePreferences];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MERedrawMenu" object:nil];
}

- (IBAction) displayGeneralHelp:(id)sender
{
	
}

- (IBAction) displayLayoutHelp:(id)sender
{
	
}

#pragma mark Accessors
#pragma mark > General
- (BOOL) isInDock
{
	int value = [[NSUserDefaults standardUserDefaults] integerForKey:MEAppearanceDisplayLocationDefaultsKey];
	if (value == 1 || value == 2) // Dock || Both
	{
		return YES;
	}
	return NO;
}

- (BOOL) isInMenu
{
	int value = [[NSUserDefaults standardUserDefaults] integerForKey:MEAppearanceDisplayLocationDefaultsKey];
	if (value == 0 || value == 2) // Menu || Both
	{
		return YES;
	}
	return NO;
	
}

- (BOOL) isMetric
{
	return ([[NSUserDefaults standardUserDefaults] integerForKey:MEAppearanceUnitsDefaultsKey] == 1);
}

- (BOOL) showBothCF
{
	return ([[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceShowBothCFDefaultsKey]);
}

- (BOOL) hideTempUnits
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceHideCFDefaultsKey];
}

#pragma mark -> Menu Bar
- (BOOL) displayTemp
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceDisplayTempDefaultsKey];
}

- (BOOL) displayCityName
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceDisplayCityNameDefaultsKey];
}

- (BOOL) displayIcon
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceDisplayMenuIconDefaultsKey];
}

- (NSString *) menuFontName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MEAppearanceMenuFontNameDefaultsKey];
}

- (int) menuFontSize
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:MEAppearanceMenuFontSizeDefaultsKey];
}

- (NSColor *) menuTextColor
{
	return [[NSUserDefaults standardUserDefaults] colorForKey:MEAppearanceMenuColorDefaultskey];
}

#pragma mark -> Dock
- (float)imageOpacity
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:MEAppearanceImageOpacityDefaultsKey];

}

- (NSString *) dockFontName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MEAppearanceDockFontNameDefaultsKey];
}

- (NSColor *) dockTextColor
{
	return [[NSUserDefaults standardUserDefaults] colorForKey:MEAppearanceDockFontColorDefaultsKey];
}

#pragma mark > Menu Layout
- (BOOL) displayCurrentConditionsInSubMenu
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceDisplayTodayInSubmenuDefaultsKey];
}

- (BOOL) extendedForecastIsEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceForecastDaysOnDefaultsKey];
}

- (BOOL) displayExtendedForecastInSubMenu
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceViewForecastInSubmenuDefaultsKey];
}

- (BOOL) forecastOnOneLine
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceForecastInlineDefaultsKey];
}

- (BOOL) displayWeatherIconsInExtendedForecast
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:MEAppearanceDisplayDayImageDefaultsKey];
}

- (int) numberOfDaysInForecast
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:MEAppearanceForecastDaysNumberDefaultsKey];
}

#pragma mark Interfacing with Others
- (BOOL) hasChanges
{
	return changesMade;
}

- (NSMutableArray *)activeProperties
{
	int i;
	NSMutableArray *activeProperties = [NSMutableArray arrayWithCapacity:[propertiesDataSource rowCount]];
	
	for (i=0; i<[propertiesDataSource rowCount]; i++)
	{
		if ([[[propertiesDataSource dataForRow:i] objectForKey:@"enabled"] boolValue])
		{
			[activeProperties addObject:[[propertiesDataSource dataForRow:i] objectForKey:@"propertyName"]];
		}
	}
	
	return [[activeProperties retain] autorelease];
}

- (NSMutableArray *)activeForecastProperties
{
	int i;
	NSMutableArray *activeProperties = [NSMutableArray arrayWithCapacity:[forecastPropertiesDataSource rowCount]];
	
	for (i=0; i<[forecastPropertiesDataSource rowCount]; i++)
	{
		if ([[[forecastPropertiesDataSource dataForRow:i] objectForKey:@"enabled"] boolValue])
		{
			[activeProperties addObject:[[forecastPropertiesDataSource dataForRow:i] objectForKey:@"propertyName"]];
		}
	}
	
	return [[activeProperties retain] autorelease];
}

#pragma mark Internal Methods

// opposite of -initializeFromDefaults
//
- (void) savePreferences
{ // must update the values from the interface
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	// General Tab
	[defs setInteger:[displayLocation selectedColumn] forKey:MEAppearanceDisplayLocationDefaultsKey];
	
	[defs setBool:[[[units selectedCell] title] isEqualToString:@"Metric"] forKey:MEAppearanceUnitsDefaultsKey];
	[defs setBool:([showBothCF state] == NSOnState)                        forKey:MEAppearanceShowBothCFDefaultsKey];
	[defs setBool:!([showTempUnits state] == NSOnState)                    forKey:MEAppearanceHideCFDefaultsKey];
	
	// -> MenuBar
	[defs setBool:([displayTemp state] == NSOnState)                       forKey:MEAppearanceDisplayTempDefaultsKey];
	[defs setBool:([displayCityName state] == NSOnState)                   forKey:MEAppearanceDisplayCityNameDefaultsKey];
	[defs setBool:([displayIcon state] == NSOnState)	                   forKey:MEAppearanceDisplayMenuIconDefaultsKey];
	[defs setObject:[menuFontName titleOfSelectedItem]	                   forKey:MEAppearanceMenuFontNameDefaultsKey];
	[defs setInteger:[[menuFontSize titleOfSelectedItem] intValue]         forKey:MEAppearanceMenuFontSizeDefaultsKey];
	[defs setColor:[menuColor color]                                       forKey:MEAppearanceMenuColorDefaultskey];
	
	// -> Dock
	[defs setFloat:[dockImageOpacity floatValue]		 forKey:MEAppearanceImageOpacityDefaultsKey];
	[defs setObject:[dockFontName titleOfSelectedItem]	 forKey:MEAppearanceDockFontNameDefaultsKey];
	[defs setColor:[dockColor color]                     forKey:MEAppearanceDockFontColorDefaultsKey];
	
	// Menu Layout Tab
	[defs setBool:([currentConditionsInSubMenu state] == NSOnState) forKey:MEAppearanceDisplayTodayInSubmenuDefaultsKey];
	
	[defs setObject:[NSKeyedArchiver archivedDataWithRootObject:propertiesDataSource]
			 forKey:@"propertiesDataSource"];
	[defs setObject:[NSKeyedArchiver archivedDataWithRootObject:forecastPropertiesDataSource]
			 forKey:@"forecastPropertiesDataSource"];
	
	[defs setBool:([enableExtendedForecast state] == NSOnState)      forKey:MEAppearanceForecastDaysOnDefaultsKey];
	[defs setBool:([extendedForecastInSubmenu state] == NSOnState)   forKey:MEAppearanceViewForecastInSubmenuDefaultsKey];	
	[defs setBool:([forecastOnOneLine state] == NSOnState)           forKey:MEAppearanceForecastInlineDefaultsKey];
	[defs setBool:([showWeatherIcons state] == NSOnState)            forKey:MEAppearanceDisplayDayImageDefaultsKey];
	[defs setInteger:[[daysInForecast titleOfSelectedItem] intValue] forKey:MEAppearanceForecastDaysNumberDefaultsKey];
	
	[defs synchronize];
	changesMade = NO;
}

- (void)registerDefaults
{
	static BOOL defaultsHaveBeenRegistered = NO;
	
	if (!defaultsHaveBeenRegistered)
	{
		// menuFontOfSize:0 returns a default sized font, but I don't really care, I'm just getting
		//   the font name
		NSFont *defaultFont;
		if ([NSFont respondsToSelector:@selector(menuBarFontOfSize:)])
			defaultFont = [NSFont menuBarFontOfSize:0];
		else
			defaultFont = [NSFont fontWithName:@"LucidaGrande" size:13];
				
		NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
		NSDictionary *appearanceDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:0],
			MEAppearanceDisplayLocationDefaultsKey,
			[NSNumber numberWithInt:0],
			MEAppearanceUnitsDefaultsKey,
			[NSNumber numberWithBool:NO],
			MEAppearanceShowBothCFDefaultsKey,
			[NSNumber numberWithBool:NO],
			MEAppearanceHideCFDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceDisplayTempDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceDisplayCityNameDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceDisplayMenuIconDefaultsKey,
			[defaultFont fontName],
			MEAppearanceMenuFontNameDefaultsKey,
			[[NSNumber numberWithFloat:[defaultFont pointSize]] stringValue],
			MEAppearanceMenuFontSizeDefaultsKey,
			[NSArchiver archivedDataWithRootObject:[NSColor blackColor]],
			MEAppearanceMenuColorDefaultskey,
			[NSNumber numberWithFloat:1.0],
			MEAppearanceImageOpacityDefaultsKey,
			[[NSFont menuFontOfSize:0] fontName],
			MEAppearanceDockFontNameDefaultsKey,
			[NSArchiver archivedDataWithRootObject:[NSColor blackColor]],
			MEAppearanceDockFontColorDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceDisplayTodayInSubmenuDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceForecastDaysOnDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceViewForecastInSubmenuDefaultsKey,
			[NSNumber numberWithBool:NO],
			MEAppearanceForecastInlineDefaultsKey,
			[NSNumber numberWithBool:YES],
			MEAppearanceDisplayDayImageDefaultsKey,
			[NSNumber numberWithInt:5],
			MEAppearanceForecastDaysNumberDefaultsKey,
			nil];
		
		[defaults registerDefaults:appearanceDefaults];
		[defaults synchronize];
		
		defaultsHaveBeenRegistered = YES;
	}
}


// Makes sure that the default exists, and if it doesn't, then this function creates the defaults
//- (id) validateDefaultNamed:(NSString *)name defaultValue:(id)def
//{
//	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
//	if ([defs objectForKey:name] == nil)
//	{
//		[defs setObject:def forKey:name];
//	}
//	return [defs objectForKey:name];
//}

- (void) initPropertiesDataSource
{
	NSUserDefaults  *defs = [NSUserDefaults standardUserDefaults];
	NSArray         *moduleNames = [[MEPlug_inManager defaultManager] moduleNames];
	NSEnumerator    *itr = [moduleNames objectEnumerator];
	NSString        *modName;
	MEWeatherModule *module;
	NSArray         *ignoreArray = [NSArray arrayWithObjects:NSLocalizedString(@"Weather Image",@""),
		NSLocalizedString(@"Link",@""),
		NSLocalizedString(@"Icon",@""),
		NSLocalizedString(@"Weather Link",@""),
		//NSLocalizedString(@"Weather Alert",@""),
		NSLocalizedString(@"Moon Phase Image",@""), // Right???
		nil];
	
	if (propertiesDataSource)
		[propertiesDataSource release];
	// read in the data source and if doesn't exist, then create it.
	id rawData = [defs objectForKey:@"propertiesDataSource"];
	if ( rawData != nil)
		propertiesDataSource = [[NSKeyedUnarchiver unarchiveObjectWithData:rawData] retain];
	else
		propertiesDataSource = [[MEPropertyDataSource alloc] init];
	
	// Now, this creates the propertiesDataSource if it doesn't exist,
	//  and it adds any new properties that are not present in the saved information
	while (modName = [itr nextObject])
	{ // for each module, add all of this modules properties
		module = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
		NSArray      *currentConditionItems = [module supportedCurrentConditionItems];
		NSEnumerator *cciItr                = [currentConditionItems objectEnumerator];
		NSString     *propertyName;
		
		// register all of that's modules supported current condition Items
		while(propertyName = [cciItr nextObject])
		{
			NSMutableArray	    *moduleNames;
			NSMutableDictionary *propertyDict;
			int row;
			if([ignoreArray containsObject:propertyName])
			{
				continue;
			}
			else if ((row = [self searchDataSource:propertiesDataSource ForProperty:propertyName]) != -1)
			{ // this property already exists in the array, so we'll just add on this moduleName to this property
				propertyDict = [NSMutableDictionary dictionaryWithDictionary:[propertiesDataSource dataForRow:row]];
				moduleNames = [propertyDict objectForKey:@"servers"];
				if (![moduleNames containsObject:modName])
					[moduleNames addObject:modName];
				[propertiesDataSource setData:propertyDict forRow:row];
			}
			else 
			{ // new property	
				moduleNames = [NSMutableArray arrayWithCapacity:[[[MEPlug_inManager defaultManager] moduleNames] count]];
				[moduleNames addObject:modName];
				NSMutableDictionary *propertyInfoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES],@"enabled",
					propertyName,@"propertyName",
					moduleNames,@"servers",
					nil];
				[propertiesDataSource addDataToEnd:propertyInfoDict];	
			}
		}
	}
	[propertiesTable setDataSource:propertiesDataSource];
	[propertiesTable setDelegate:propertiesDataSource];
}

- (void) initForecastPropertiesDataSource
{
	NSUserDefaults  *defs = [NSUserDefaults standardUserDefaults];
	NSArray         *moduleNames = [[MEPlug_inManager defaultManager] moduleNames];
	NSEnumerator    *itr = [moduleNames objectEnumerator];
	NSString        *modName;
	MEWeatherModule *module;
	NSArray         *ignoreArray = [NSArray arrayWithObjects:NSLocalizedString(@"Weather Image",@""),
		NSLocalizedString(@"Link",@""),
		NSLocalizedString(@"Icon",@""),
		NSLocalizedString(@"Weather Link",@""),
		NSLocalizedString(@"Moon Phase Image",@""), // Right???
		nil];
	if (forecastPropertiesDataSource)
		[forecastPropertiesDataSource release];
	// read in the data source and if doesn't exist, then create it.
	id rawData = [defs objectForKey:@"forecastPropertiesDataSource"];
	if ( rawData != nil)
		forecastPropertiesDataSource = [[NSKeyedUnarchiver unarchiveObjectWithData:rawData] retain];
	else
		forecastPropertiesDataSource = [[MEPropertyDataSource alloc] init];
	
	// Now, this creates the propertiesDataSource if it doesn't exist,
	//  and it adds any new properties that are not present in the saved information
	while (modName = [itr nextObject])
	{ // for each module, add all of this modules properties
		module = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
		NSArray      *forecastItems = [module supportedForecastItems];
		NSEnumerator *fiItr         = [forecastItems objectEnumerator];
		NSString     *propertyName;
		
		// register all of that's modules supported current condition Items
		while(propertyName = [fiItr nextObject])
		{
			NSMutableArray	    *moduleNames;
			NSMutableDictionary *propertyDict;
			int row;
			if([ignoreArray containsObject:propertyName])
			{
				continue;
			}
			else if ((row = [self searchDataSource:forecastPropertiesDataSource ForProperty:propertyName]) != -1)
			{ // this property already exists in the array, so we'll just add on this moduleName to this property
				propertyDict = [NSMutableDictionary dictionaryWithDictionary:[forecastPropertiesDataSource dataForRow:row]];
				moduleNames = [propertyDict objectForKey:@"servers"];
				if (![moduleNames containsObject:modName])
					[moduleNames addObject:modName];
				[forecastPropertiesDataSource setData:propertyDict forRow:row];
			}
			else 
			{ // new property	
				moduleNames = [NSMutableArray arrayWithCapacity:[[[MEPlug_inManager defaultManager] moduleNames] count]];
				[moduleNames addObject:modName];
				NSMutableDictionary *propertyInfoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES],@"enabled",
					propertyName,@"propertyName",
					moduleNames,@"servers",
					nil];
				[forecastPropertiesDataSource addDataToEnd:propertyInfoDict];	
			}
		}
	}
	[forecastPropertiesTable setDataSource:forecastPropertiesDataSource];
	[forecastPropertiesTable setDelegate:forecastPropertiesDataSource];
}


// returns the index of the row in the data where this property is found
- (int)searchDataSource:(MEPropertyDataSource *)dataSource ForProperty:(NSString *)property
{
    int i;
	for (i=0; i<[dataSource rowCount]; i++)
    {
		if([[[dataSource dataForRow:i] objectForKey:@"propertyName"] isEqualToString:property])
			return i;
    }
    
    return -1;
}

@end
