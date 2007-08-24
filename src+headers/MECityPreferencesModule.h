//
//  MECityPreferencesModule.h
//  Meteorologist
//
//  Created by Joseph Crobak on Sun May 30 2004.
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


#import <Foundation/Foundation.h>
#import "NSPreferences.h"
#import "MECity.h"
#import "MECitySearchResultsTable.h"
#import "MEWebUtils.h"

@interface MECityPreferencesModule : NSPreferencesModule 
{	
	// Stuff on the left side
	IBOutlet NSTableView *cityTable;
    IBOutlet NSButton    *addCity;
    IBOutlet NSButton    *removeCity;
	
	// The tabs on the rest of the window
	IBOutlet NSTabView *tabView;
	
	// Items in first tab (servers)
	IBOutlet NSTextField *cityName;
    IBOutlet NSTableView *serverTable;
	
	// Second tab
	IBOutlet NSButton    *useCustomRadarImage;
	IBOutlet NSTextField *customImageURL;
	IBOutlet NSButton    *previewButton;
	
	IBOutlet NSWindow    *imagePreviewWindow;
	IBOutlet NSImageView *imagePreview;
	IBOutlet NSTextField *loadingText;
	IBOutlet NSProgressIndicator *loadingIndicator;
	
	// search window
	IBOutlet NSTextField		 *searchTerm;
    IBOutlet NSButton			 *search;
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTableView		 *searchResultsTable;
	IBOutlet NSButton			 *addServer;
	IBOutlet NSWindow			 *searchSheet;

	// search window search results.
	MECitySearchResultsTable *resultsTableData;
		
	MECity		   *currentCity;
    NSMutableArray *cities;
	
	MEWebFetcher   *searchResultsFetcher;
	BOOL changesToSearchString;
}

// GUI Methods:
- (void) addEnableButtonToTableView:(NSTableView *)tableView columnIdentifier:(NSString *)identifier;
- (MECity *) loadCityIntoView:(MECity *)city;
- (void) disableInterface;
- (void) enableInterface;

// Archiving/Unarchiving Methods
- (NSMutableArray *) citiesForData:(NSMutableArray *)dataArray;
- (NSMutableArray *) dataForCities:(NSMutableArray *)cityArray;

// Interfacing with other objects
- (void) discoverCities;
- (NSArray *) cities;
- (void) activeServersChanged;
- (void) addNewCity;

// -- INTERFACE METHODS --

- (IBAction) actionPerformed:(id)sender;
// Left Column Stuff
- (IBAction) newCity:(id)sender;
- (IBAction) removeCity:(id)sender;
- (IBAction) editCity:(id)sender;

// Servers Tab
- (IBAction) openServerHelp:(id)sender;

	// Second Tab
- (IBAction) openAdvancedOptionsHelp: (id)sender;
- (IBAction) toggleCustomRadarImageCheckbox: (id)sender;
- (IBAction) previewCustomRadarImage: (id)sender;

// Search Window
- (IBAction) performSearch:(id)sender;
- (IBAction) openCitySearchHelp:(id)sender;
- (IBAction) cancelAddServer:(id)sender;
- (IBAction) addServer:(id)sender;
- (IBAction) displaySearchSheet:(id)sender;

// From MEController
- (NSMutableArray *) citiesForData:(NSMutableArray *)dataArray;
- (NSMutableArray *) dataForCities:(NSMutableArray *)cityArray;

// NSTableView stuff
- (NSArray *) arrayForTableView:(NSTableView *)aTableView;

- (void) tabViewDataForCity:(MECity *)city;
- (void) tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)  numberOfRowsInTableView:(NSTableView *)aTableView;
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

	// Internal Methods
- (void) textDidChange:(NSNotification *)aNotification;
- (void) saveChanges;
- (void) dontSaveChanges;


@end
