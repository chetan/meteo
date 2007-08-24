//
//  MEAppearancePreferences.h
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


#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"
#import "MEPropertyDataSource.h"

@interface MEAppearancePreferencesModule : NSPreferencesModule  
{
	IBOutlet NSTabView     *appearancesTabView;
	
	// ------ General    -------- //
	IBOutlet NSMatrix      *displayLocation;
	
	IBOutlet NSMatrix      *units;
	IBOutlet NSButton      *showBothCF;
	IBOutlet NSButton      *showTempUnits;
	
	IBOutlet NSButton      *displayTemp;
	IBOutlet NSButton      *displayCityName;
	IBOutlet NSButton      *displayIcon;
	IBOutlet NSPopUpButton *menuFontName;
	IBOutlet NSPopUpButton *menuFontSize;
	IBOutlet NSColorWell   *menuColor;
	
	IBOutlet NSSlider      *dockImageOpacity;
	IBOutlet NSPopUpButton *dockFontName;
	IBOutlet NSColorWell   *dockColor;
	
	// ------ Menu Layout ------- //
	IBOutlet NSButton      *currentConditionsInSubMenu;
	IBOutlet NSTableView   *propertiesTable;

	IBOutlet NSTableView   *forecastPropertiesTable;
	IBOutlet NSButton      *enableExtendedForecast;
	IBOutlet NSButton      *extendedForecastInSubmenu;
	IBOutlet NSButton      *forecastOnOneLine;
	IBOutlet NSButton      *showWeatherIcons;
	IBOutlet NSPopUpButton *daysInForecast;
	
	MEPropertyDataSource   *propertiesDataSource,
		*forecastPropertiesDataSource;
	BOOL changesMade;
}

// Interface methods
- (IBAction) displayLocationChange:(id)sender;
- (IBAction) showTempAsBothClicked:(id)sender;
- (IBAction) enableExtendedForecastClicked:(id)sender;
- (IBAction) actionPerformed:(id)sender; // called whenever a button is clicked or a text field is changed.
- (IBAction) displayGeneralHelp:(id)sender;
- (IBAction) displayLayoutHelp:(id)sender;

	// Accessors

	// > General
- (BOOL) isInDock;
- (BOOL) isInMenu;

- (BOOL) isMetric; 
- (BOOL) showBothCF;
- (BOOL) hideTempUnits;

	// -> Menu Bar
- (BOOL) displayTemp;
- (BOOL) displayCityName;
- (BOOL) displayIcon;
- (NSString *) menuFontName;
- (int) menuFontSize;
- (NSColor *) menuTextColor;

	// -> Dock
- (float)imageOpacity;
- (NSString *) dockFontName;
- (NSColor *) dockTextColor;

	// > Menu Layout
- (BOOL) displayCurrentConditionsInSubMenu;
- (BOOL) extendedForecastIsEnabled;
- (BOOL) displayExtendedForecastInSubMenu;
- (BOOL) forecastOnOneLine;
- (BOOL) displayWeatherIconsInExtendedForecast;
- (int) numberOfDaysInForecast;

	// Interfacing methods
- (BOOL) hasChanges;
- (void) savePreferences;
- (NSMutableArray *) activeProperties;
- (NSMutableArray *)activeForecastProperties;


	// Internal Methods
//- (id) validateDefaultNamed:(NSString *)name defaultValue:(id)def;
- (void) registerDefaults;
- (void) initPropertiesDataSource;
- (void) initForecastPropertiesDataSource;
- (int)searchDataSource:(MEPropertyDataSource *)dataSource ForProperty:(NSString *)property;

@end
