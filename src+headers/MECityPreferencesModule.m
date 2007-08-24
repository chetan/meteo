//
//  MECityPreferencesModule.m
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


#import "MECityPreferencesModule.h"
#import "MEController.h"
#import "MEPlug-inManager.h"
#import "MEWebUtils.h"

/* Only preferences saved here are "cities" */
NSString *MECitiesDefaultsKey = @"cities";

extern NSString *MEWebUtilsBackgroundDownloadFinished;

@implementation MECityPreferencesModule

- (id)init 
{
	self = [super init];
	if (self)
	{
		resultsTableData = [[MECitySearchResultsTable alloc] initWithRowCount: 8]; // Weather.com returns 8 results
		currentCity = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cityOrderingChanged:) 
													 name:@"MECityOrderingChanged" object:cityName]; 
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundDownloadFinishedNotification:)
													 name:MEWebUtilsBackgroundDownloadFinished object:nil];
	}
	return self;
}

- (void) dealloc
{
	[resultsTableData release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[searchResultsTable setDataSource:resultsTableData];
	[searchResultsTable setDelegate:resultsTableData];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textDidChange:) 
												 name:NSControlTextDidChangeNotification 
											   object:cityName]; 
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(searchTextDidChange:)
												 name:NSControlTextDidChangeNotification 
											   object:searchTerm]; 
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(customRadarTextDidChange:)
												 name:NSControlTextDidChangeNotification
											   object:customImageURL];
    [progress setUsesThreadedAnimation:YES];
	
	[cityTable setAutosaveName:@"cityTable"];
	[cityTable setToolTip:@"A city is active if it has at least one active server."];
    [cityTable registerForDraggedTypes:[NSArray arrayWithObjects:[cityTable autosaveName], nil]];
	[cityTable setDataSource:self]; // cities array
	[cityTable setDelegate:self];
    
	[serverTable setAutosaveName:@"serverTable"];
	[serverTable setToolTip:@"For each server you wish to use, you must perform a search to determine the city's location code."];
	[serverTable registerForDraggedTypes:[NSArray arrayWithObjects:[serverTable autosaveName], nil]];
	[serverTable setDoubleAction:@selector(displaySearchSheet:)];
	[serverTable setTarget:self];
	
	// Add switch button "button cells"
	[self addEnableButtonToTableView:cityTable columnIdentifier:@"active"];	
	[self addEnableButtonToTableView:serverTable columnIdentifier:@"enabled"];	
	
	[tabView selectFirstTabViewItem:self];
}

#pragma mark - Archiving/Unarchiving Methods -
- (NSMutableArray *)citiesForData:(NSMutableArray *)dataArray
{
    NSMutableArray *cityArray = [NSMutableArray array];
    
    NSEnumerator *dataEnum = [dataArray objectEnumerator];
    NSData *data;
    
    while(data = [dataEnum nextObject])
        [cityArray addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
	
	/* for backwards compatibility */
    return cityArray;
}

- (NSMutableArray *)dataForCities:(NSMutableArray *)cityArray
{
    NSMutableArray *dataArray = [NSMutableArray array];
    
    NSEnumerator *cityEnum = [cityArray objectEnumerator];
    MECity *nextCity;
    
    while(nextCity = [cityEnum nextObject])
        [dataArray addObject:[NSKeyedArchiver archivedDataWithRootObject:nextCity]];
	
    return dataArray;
}

#pragma mark - Inheritted from NSPreferefenceModule -
/**
* Image to display in the preferences toolbar
 * 32x30 pixels (72 DPI) TIFF
 */
- (NSImage *) imageForPreferenceNamed:(NSString *)_name 
{
	return [[[NSImage imageNamed:@"MECityPreferences"] retain] autorelease];
}

/**
* Override to return the name of the relevant nib
 */
- (NSString *) preferencesNibName 
{
	return @"MECityPreferences";
}

/**
* Not sure how useful this is, so far always seems to return YES.
*/
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
	if (cities != nil && [cities count] > 0) 
	{
		[self loadCityIntoView:[cities objectAtIndex:0]];
	}
	else 
	{
		currentCity = nil;
		if (!cities)
			cities = [[NSMutableArray arrayWithCapacity:10] retain];
		[self newCity:self];
	}	
}

- (BOOL)moduleCanBeRemoved 
{
	return YES;
}

- (BOOL)preferencesWindowShouldClose
{	
	return YES;
}

#pragma mark Gui Stuff

- (void) addEnableButtonToTableView:(NSTableView *)tableView columnIdentifier:(NSString *)identifier
{
	NSButtonCell *cell = [[[NSButtonCell alloc] init] autorelease];
    [cell setButtonType:NSSwitchButton];
    [cell setTitle:@""];
    [cell setImagePosition:NSImageOverlaps];
    [cell setControlSize:NSSmallControlSize];
    [[tableView tableColumnWithIdentifier:identifier] setDataCell:cell];
}


- (MECity *)loadCityIntoView:(MECity *)city 
{
	
	if (city)
	{
		currentCity = city;
		
		[serverTable setDelegate:[city serverTableDataSource]];
		[serverTable setDataSource:[city serverTableDataSource]];
		
		
		[serverTable reloadData];
		
		[cityName setStringValue:[currentCity cityName]];	
		[cityTable selectRow:[cities indexOfObject:currentCity] byExtendingSelection:NO];
		[self enableInterface];
	}
	else
	{

		
		[self disableInterface];
	}
	return currentCity;
}

- (void)disableInterface
{
	[cityName setStringValue:@""];
	[cityName setEnabled:NO];
	[removeCity setEnabled:NO];
	[serverTable setDelegate:nil];
	[serverTable setDataSource:nil];
	[serverTable setEnabled:NO];
	[serverTable reloadData];
	
	[previewButton setEnabled:NO];
	[useCustomRadarImage setEnabled:NO];
	[customImageURL setEnabled:NO];
}

- (void)enableInterface
{
	[cityName setEnabled:YES];
	[removeCity setEnabled:YES];
	[serverTable setEnabled:YES];
	
	[self toggleCustomRadarImageCheckbox:useCustomRadarImage];
}

#pragma mark Interfacing with other objects

- (void)cityOrderingChanged:(id)arg
{
	[cityTable reloadData];
}

// loads the cities from the preferences files, if they exist
- (void) discoverCities
{
	if (cities)
		[cities release];
	
	NSMutableArray *rawCityData = [[NSUserDefaults standardUserDefaults] objectForKey:MECitiesDefaultsKey];
//	NSMutableArray *oldCities   = [[NSUserDefaults standardUserDefaults] objectForKey:MECitiesDefaultsKey];
    if(!rawCityData)
	{
//		if (oldCities)
//		{
//			NSRunAlertPanel(@"Thanks for upgrading!",@"Thank you for upgrading to Meteo 2.0.  The program has undergone a significant evolution since version 1.x, and unfortunately you will need to re-enter your cities and reconfigure some preferences.",@"OK",nil,nil);
//		}
        cities = [[NSMutableArray array] retain];
	}
    else
		cities = [[self citiesForData:rawCityData] retain];
	
	if (cityTable)
		[cityTable reloadData];
}

- (NSArray *) cities
{
	return [[cities retain] autorelease];
}

#pragma mark -

- (void) activeServersChanged
{
	if (currentCity)
	{
		MEServerTableDataSource *serversDS = [currentCity serverTableDataSource];
		if ([[serversDS activeModuleNames] count] == 0)
			[currentCity setActive:NO];
		
		// redraw the menu!
	}
}

- (void)addNewCity
{
	MECity *newCity = [MECity defaultCity];
	[cities addObject:newCity];
	[cityTable reloadData];
	
	[self loadCityIntoView:newCity];
	[tabView selectFirstTabViewItem:nil];	
	
	[[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:MECitiesDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//	[[MEController sharedInstance] generateMenu]; // hmm how am i going to do this??
	
}

#pragma mark -

#pragma mark - Interface Actions -
- (IBAction) actionPerformed:(id)sender
{
	[self saveChanges];
}

- (IBAction)newCity:(id)sender
{
	[self addNewCity];
}

- (IBAction)removeCity:(id)sender
{
	int row = [cityTable selectedRow];
	if (row != -1) 
	{
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure that you wish to delete the city \"%@?\"",@""),[currentCity cityName]];
		NSBeginAlertSheet(NSLocalizedString(@"Confirm Delete",@""),
						  NSLocalizedString(@"OK",@""),
						  NSLocalizedString(@"Cancel",@""),
						  nil,
						  [[NSPreferences sharedPreferences] preferencesWindow],
						  self,
						  @selector(confirmRemoveCitySheetDidEnd:returnCode:contextInfo:),
						  NULL,
						  NULL,
						  message);		
	}
}

- (IBAction)editCity:(id)sender
{
	int				row = [cityTable selectedRow];
	MECity		   *selectedCity = [cities objectAtIndex:row];

	if (row >= 0 && currentCity != selectedCity) 
	{
		[self loadCityIntoView:currentCity];
	}
}

- (IBAction) openServerHelp:(id)sender
{
	
}

#pragma mark -

- (IBAction) openAdvancedOptionsHelp: (id)sender
{
	
}

- (IBAction) toggleCustomRadarImageCheckbox: (id)sender
{
	if (currentCity)
	{
		[currentCity setUsesCustomRadarImage:[sender state]];
	}
	BOOL enabled;
	if ([sender state] == NSOffState)
		enabled = NO;
	else
		enabled = YES;
	[customImageURL setEnabled:enabled];
	[previewButton setEnabled:enabled];
}

- (IBAction) previewCustomRadarImage: (id)sender
{
	NSString *url = [NSString stringWithString:[customImageURL stringValue]];
	
	if (![[customImageURL stringValue] hasPrefix:@"http://"])
	{
		url = [NSString stringWithFormat:@"http://%@",url];
		[customImageURL setStringValue:url];
	}
	
	[imagePreview setImage:nil];
	if ([loadingText respondsToSelector:@selector(setHidden:)])
		[loadingText setHidden:NO];
	if ([loadingIndicator respondsToSelector:@selector(setHidden:)])
		[loadingIndicator setHidden:NO];
	[loadingIndicator setUsesThreadedAnimation:YES];
	[loadingIndicator startAnimation:nil];

	[imagePreviewWindow display];
	[imagePreviewWindow makeKeyAndOrderFront:self];

	NSImage *preview = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
	if ([loadingText respondsToSelector:@selector(setHidden:)])
		[loadingText setHidden:YES];
	if ([loadingIndicator respondsToSelector:@selector(setHidden:)])
		[loadingIndicator setHidden:YES];
	[loadingIndicator stopAnimation:nil];
	
	if (preview)
	{
		[imagePreview setImage:preview];
		[imagePreviewWindow orderFront:self];
	}
	else
	{
		NSRunAlertPanel(NSLocalizedString(@"Invalid URL",@""),
						[NSString stringWithFormat:NSLocalizedString(@"Unable to download an image at the specified URL (%@).",@""),[customImageURL stringValue]],
						NSLocalizedString(@"OK",@""),nil,nil);
		[imagePreviewWindow orderOut:self];
	}
}

#pragma mark - Search Sheet display and callback methods -

- (IBAction) displaySearchSheet:(id)sender
{	
	[searchTerm setStringValue:[currentCity cityName]];
	
	/* disable buttons, progressbar, results table */
	[addServer setEnabled:NO];
	if ([progress respondsToSelector:@selector(setHidden:)])
		[progress setHidden:YES];
	[resultsTableData setSelectable:NO];
	[resultsTableData deleteRows];
	[resultsTableData setSelectable:NO];
	[searchResultsTable deselectRow:[cityTable selectedRow]];
	changesToSearchString=YES;
	
	[NSApp beginSheet: searchSheet
	   modalForWindow: [[NSPreferences sharedPreferences] preferencesWindow]
		modalDelegate: self
	   didEndSelector: @selector(searchSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: NULL];
}

- (void)searchSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
}
	
- (IBAction)performSearch:(id)sender
{
	if (changesToSearchString)
	{
		MEServerTableDataSource *serversDS = [currentCity serverTableDataSource];
		NSString *weatherSource = [[serversDS dataForRow:[serverTable selectedRow]]
										objectForKey:@"moduleName"];	
		NSString *searchWord = [searchTerm stringValue];				
	 
		if ([progress respondsToSelector:@selector(setHidden:)])
			[progress setHidden:NO];
		[progress startAnimation:nil];
		
		MEWeatherModule *weatherModule = [[MEPlug_inManager defaultManager] moduleObjectNamed:weatherSource];
		NSAssert(weatherModule,@"Uh oh. Can't perform search on a weather module that doesn't exist!");
		
		NSString *searchURLAsString = [weatherModule searchURL];
		NSString *percentEscapedSearchURLAsString = [MEURLStringProcessor makeStringURLable:[NSString stringWithFormat:searchURLAsString,searchWord]];

		searchResultsFetcher = [[MEWebFetcher webFetcher] retain];
		
		// returns immediately
		[searchResultsFetcher fetchURLtoStringInBackground:[NSURL URLWithString:percentEscapedSearchURLAsString]];
	}
}

-(void)backgroundDownloadFinishedNotification:(NSNotification *)aNot
{
	NSLog(@"background downloaded finished notification");
	if (searchResultsFetcher != nil && (searchResultsFetcher == [aNot object]))
	{
		MEServerTableDataSource *serversDS     = [currentCity serverTableDataSource];
		NSString                *weatherSource = [[serversDS dataForRow:[serverTable selectedRow]] objectForKey:@"moduleName"];	
		MEWeatherModule         *weatherModule = [[MEPlug_inManager defaultManager] moduleObjectNamed:weatherSource];
		NSString                *pageContents  = [[aNot userInfo] objectForKey:@"string"];
		NSString                *url           = [[aNot userInfo] objectForKey:@"url"];
		if (!pageContents)
		{
			NSLog(@"There was a download error... oops");
			return;
		}
		NSArray *results = [weatherModule performCitySearchOnPageContents:pageContents pageURL:url];
		NSAssert(resultsTableData,@"resultsTableData was nil in performSearch");
		[resultsTableData deleteRows];
		
		if ([results count] == 0) 
		{
			
			NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:2];
			[aDict setObject:@"No Matching Cities Found." forKey:@"name"];
			[aDict setObject:@"-1" forKey:@"code"];
			
			[resultsTableData insertRowAt:0 withData:aDict];
			
			// now make it unselectable and grey
			[resultsTableData setSelectable:NO];
			[searchResultsTable deselectRow:[cityTable selectedRow]];
		}
		else 
		{
			NSEnumerator *itr = [results objectEnumerator];
			NSDictionary *aDict;
			int row=0;
			
			while (aDict = [itr nextObject]) {
				//NSString *test = [aDict objectForKey:@"name"];
				if ([(NSString *)[aDict objectForKey:@"name"] length] > 0)
					[resultsTableData insertRowAt:row++ withData:[aDict retain]]; // JRC
			}
			
			// make sure it's selectable and not grey 
			[searchResultsTable reloadData]; // necessary to set selectable
			[resultsTableData setSelectable:YES];
			[searchResultsTable selectRow:0 byExtendingSelection:NO];
			
			//enable button
			[addServer setEnabled:YES];
		}
		[searchResultsTable reloadData];
		
		[progress stopAnimation:nil];	
		if ([progress respondsToSelector:@selector(setHidden:)])
			[progress setHidden:YES];
		
		[searchResultsFetcher release];
		searchResultsFetcher = nil;
		
		changesToSearchString = NO;
	}
}

- (IBAction)openCitySearchHelp:(id)sender
{
	
}

- (IBAction)cancelAddServer:(id)sender
{
	[progress stopAnimation:nil];	
	if ([progress respondsToSelector:@selector(setHidden:)])
		[progress setHidden:YES];
	if (searchResultsFetcher != nil)
		[searchResultsFetcher cancelFetchURL];
	[NSApp endSheet:searchSheet returnCode:NSCancelButton];
}

- (IBAction)addServer:(id)sender
{
	NSString *code			           = [[resultsTableData dataForRow:[searchResultsTable selectedRow]]
									                      objectForKey:@"code"];	
	int row							   = [serverTable selectedRow];
	MEServerTableDataSource *serversDS = [currentCity serverTableDataSource];
	NSDictionary *newServerData = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES],@"enabled",
		code,@"code",nil];

	// save the new data for the row.
	[serversDS setData:newServerData forRow:row];
	[serverTable reloadData];
	
	// tell the city to be active
	[currentCity setActive:YES];
	[cityTable reloadData];
		
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MECityUpdate" 
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:currentCity,@"city",nil]];
	
	[NSApp endSheet:searchSheet returnCode:NSOKButton];
	
	[self saveChanges];
}

#pragma mark - custom methods for assisting in TableView maintenance -
- (NSArray *)arrayForTableView:(NSTableView *)aTableView
{
	if (aTableView == cityTable)
		return cities;
	return nil;
}

- (void) tabViewDataForCity:(MECity *)city
{
    [cityName setStringValue:[currentCity cityName]];
    [searchTerm setStringValue:[currentCity cityName]];
    
    [tabView selectFirstTabViewItem:nil];
}

#pragma mark - TableView datasource and delegate methods -

//- (NSString *)firstActiveModuleInArray:(NSArray *)moduleNames
//{
//	NSEnumerator *itr = [[[currentCity weatherReport] activeModuleNames] objectEnumerator];
//	NSString *moduleName;
//	
//	while (moduleName = [itr nextObject]) // the active servers are order the way in which we wish to fetch data.
//	{
//		if ([moduleNames containsObject:moduleName])
//			return moduleName;
//	}
//	return nil;
//}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSArray *arrayForTV = [self arrayForTableView:aTableView];
	if (arrayForTV)
		return [arrayForTV count];
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSArray *tableArray = [self arrayForTableView:aTableView];
	NSString *identifier;
	id objectAtRow;
	if (tableArray && row >=0 && row < [tableArray count]) // this row if stuff might not be necessary
	{
		identifier  = [tableColumn identifier];
		objectAtRow = [tableArray objectAtIndex:row];
		if ([objectAtRow respondsToSelector:@selector(objectForKey:)]) // NSDictionary
		{
			if ([identifier isEqualToString:@"code"] && [[objectAtRow objectForKey:identifier] isEqualToString:@""])
				return @"????";
			return [objectAtRow objectForKey:identifier];			
		}
		else if ([objectAtRow respondsToSelector:@selector(cityName)] && [identifier isEqualToString:@"cityName"])
		{
			return [objectAtRow cityName];
		}
		else if ([objectAtRow respondsToSelector:@selector(isActive)] && [identifier isEqualToString:@"active"])
		{
			return [NSNumber numberWithBool:[objectAtRow isActive]];
		}
	}
	NSAssert(0,@"tableView:objectValueForTableColumn: it shouldn't get here!!!");
	return @"";
}



- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSArray  *tableArray = [self arrayForTableView:aTableView];
    NSString *identifier = [aTableColumn identifier];
	MEServerTableDataSource *serversDS = [currentCity serverTableDataSource];
    if(tableArray && (aTableView == cityTable) && [identifier isEqualToString:@"active"])
    {
        if (([[serversDS activeModuleNames] count] == 0) &&
			([[serversDS inactiveModuleNames] count] == 0))
		{ // must perform a search
			[serverTable selectRow:0 byExtendingSelection:NO];
			[self displaySearchSheet:self];
		}
		else if (([[serversDS activeModuleNames] count] == 0) &&
				 ([[serversDS inactiveModuleNames] count] > 0))
		{ // activate the first inactive module
			int i = 0;
			NSDictionary *newServerData = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:YES],@"enabled",nil];
			for (i = 0; i<[serversDS rowCount]; i++)
			{
				if([[[serversDS dataForRow:i] objectForKey:@"enabled"] boolValue])
				{
					[serversDS setData:newServerData forRow:i];
					break;
				}
			}
			// make the city active
			[currentCity setActive:YES];
		}
		else
		{
			[currentCity setActive:![currentCity isActive]];
		}
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// reload the data on the right side
	MECity *selectedCity;
	int row = [cityTable selectedRow];
	if (row != -1)
	{
		selectedCity = [cities objectAtIndex:row];
		if (selectedCity != currentCity)
		{
			[self loadCityIntoView:selectedCity];		
		}
	}	
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualTo:@"enabled"] || [[aTableColumn identifier] isEqualTo:@"active"])
		return YES;
    return NO;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{
	NSArray *tableArray = [self arrayForTableView:aTableView];
	
	if (tableArray && aTableView == cityTable && 
		[aCell isMemberOfClass:[NSButtonCell class]])
	{
		[aCell setState:[[tableArray objectAtIndex:row] isActive]];
	}
	else if (tableArray && aTableView == serverTable && 
			 [aCell isMemberOfClass:[NSButtonCell class]])
	{
		[aCell setState:[[[tableArray objectAtIndex:row] objectForKey:[aTableColumn identifier]] boolValue]];
		[aCell setEnabled:(currentCity != nil)];
	}
	// THIS CODE MIGHT BE USEFUL LATER ON!
	//   -- This "disables"/greys out members of a tableview that are not currently available (if they require a different server)
	
	//	else if (tableArray && (aTableView == weatherPropertyTable || aTableView == forecastPropertyTable))
	//	{
	//		NSDictionary *propertyDict = [tableArray objectAtIndex:row]; // keys: enabled, property, moduleNames
	//		NSString	 *firstActiveModuleName = [self firstActiveModuleInArray:[propertyDict objectForKey:@"moduleNames"]];
	//		BOOL interfaceEnabled = (firstActiveModuleName != nil); 
	//		
	//		if ([aCell isMemberOfClass:[NSButtonCell class]])
	//		{
	//			if (interfaceEnabled)
	//				[aCell setState:[[[tableArray objectAtIndex:row] objectForKey:[aTableColumn identifier]] boolValue]];
	//			else
	//				[aCell setState:NO];
	//		}
	//		else if (interfaceEnabled == NO)
	//		{
	//			[aCell setEnabled:interfaceEnabled];
	//			[aCell setTextColor:[NSColor lightGrayColor]];
	//		}
	//		else if (interfaceEnabled == YES)
	//		{
	//			[aCell setEnabled:interfaceEnabled];
	//			[aCell setTextColor:[NSColor blackColor]];
	//		}
	//	}
}

#pragma mark -> For Drag and Drop
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    NSString *type = [tableView autosaveName];
	
    [pboard declareTypes:[NSArray arrayWithObjects:type,nil] owner:self];
    [pboard setData:[NSArchiver archivedDataWithRootObject:rows] forType:type];
    [pboard setString:[rows description] forType: NSStringPboardType];
    return YES;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSArray *selectedRows;
    NSEnumerator *rowEnum;
    NSNumber *aRow;
    
    if(row<0)
        return NO;
    
    selectedRows = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:[tableView autosaveName]]];
	
    rowEnum = [selectedRows objectEnumerator];
	
    while(aRow = [rowEnum nextObject])
    {
        int index = [aRow intValue];
        
        id obj = [[cities objectAtIndex:index] retain];
        [cities replaceObjectAtIndex:index withObject:[NSNull null]];
        
        [cities insertObject:obj atIndex:row];
        [cities removeObject:[NSNull null]];
		[obj release];
    }
    
    [tableView reloadData];
	[self saveChanges];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MERedrawMenu" object:nil];

    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationMove;
}

#pragma mark Sheet Callbacks

- (void)confirmRemoveCitySheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn)
	{
		int row = [cityTable selectedRow];
		if (row != -1) {
			
			if (currentCity == [cities objectAtIndex:row])
				[cities removeObjectAtIndex:row];
			
			if ([cities count] > 0)
			{                       
				[self loadCityIntoView:[cities objectAtIndex:0]]; // assigns this city as the new currentCity
			}
			else
			{
				currentCity = nil; 
				[self loadCityIntoView:currentCity]; // calls deactivate interface
			}
			
			[cityTable reloadData]; 
			
			[[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:MECitiesDefaultsKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MERedrawMenu" object:nil];
		}
	}
	// otherwise do nothing
}


#pragma mark Internal Methods

- (void) saveChanges
{
	[[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:MECitiesDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
}

- (void) dontSaveChanges
{
	[self discoverCities]; // reloads cities from defaults
	
}

- (void) textDidChange:(NSNotification *)aNotification
{
	[currentCity setCityName:[cityName stringValue]];
	[cityTable reloadData];
	[self saveChanges];
}

- (void) searchTextDidChange:(NSNotification *)aNotification
{
	changesToSearchString = YES;
}

- (void) customRadarTextDidChange:(NSNotification *)aNotification
{
	if ( [[customImageURL stringValue] length] == 0 )
		[previewButton setEnabled:NO];
	else
		[previewButton setEnabled:YES];

	if (currentCity)
	{
		[currentCity setCustomRadarImageURL:[customImageURL stringValue]];
	}
	
	[self saveChanges];
}

@end