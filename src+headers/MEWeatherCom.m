//
//  MEWeatherCom.m
//  Meteorologist
//
//  Created by Joseph Crobak on Fri Jul 23 2004.
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


#import "MEWeatherCom.h"
#import "MEWebUtils.h"
#import "MEStringSearcher.h"
#import "NSString-Additions.h"
#import <AGRegex/AGRegex.h>

#define DEFAULT_TIMEOUT 30

@implementation MEWeatherCom

- (id)initWithBundlePath:(NSString *)bundlePath
{
	self = [super init];
	if (self)
	{
		NSString *path = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"WeatherCom" ofType:@"xml"];
		moduleDict = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
		
		currentConditionItemsLookup = 
			[[NSDictionary dictionaryWithObjectsAndKeys:		
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Weather Image",@""),@"label",
					MENoUnits,@"units",nil],
				@"Weather Image",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Temperature",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Temperature",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Feels Like",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Feels Like",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Dew Point",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Dew Point",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Humidity",@""),@"label",
					MEPercentUnits,@"units",nil],
				@"Humidity",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Visibility",@""),@"label",
					MEMilesUnits,@"units",nil],
				@"Visibility",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Pressure",@""),@"label",
					MEInchesPressureUnits,@"units",nil],
				@"Pressure",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Current Conditions",@""),@"label",
					MENoUnits,@"units",nil],
				@"Current Conditions",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Wind",@""),@"label",
					MEMPHUnits,@"units",nil],
				@"Wind",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Weather Link",@""),@"label",
					MENoUnits,@"units",nil],
				@"Weather Link",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Radar Image",@""),@"label",
					MENoUnits,@"units",nil],
				@"Radar Image",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Weather Alert",@""),@"label",
					MENoUnits,@"units",nil],
				@"Weather Alert",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"UV Index",@""),@"label",
					MENoUnits,@"units",nil],
				@"UV Index",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Hourly Forecast",@""),@"label",
					MENoUnits,@"units",nil],
				@"Hourly Forecast",
				nil] retain];
		
		forecastItemsLookup = 
			[[NSDictionary dictionaryWithObjectsAndKeys:
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Link",@""),@"label",
					MENoUnits,@"units",nil],
				@"Link",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Date",@""),@"label",
					MENoUnits,@"units",nil],
				@"Date",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Day",@""),@"label",
					MENoUnits,@"units",nil],
				@"Day",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Icon",@""),@"label",
					MENoUnits,@"units",nil],
				@"Icon",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Forecast",@""),@"label",
					MENoUnits,@"units",nil],
				@"Forecast",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"High",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"High",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Low",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Low",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"UV Index",@""),@"label",
					MENoUnits,@"units",nil],
				@"UV Index",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Wind Speed",@""),@"label",
					MEMPHUnits,@"units",nil],
				@"Wind Speed",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Wind Direction",@""),@"label",
					MENoUnits,@"units",nil],
				@"Wind Direction",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Chance Precip",@""),@"label",
					MEPercentUnits,@"units",nil],
				@"Chance Precip",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Humidity",@""),@"label",
					MEPercentUnits,@"units",nil],
				@"Humidity",
				nil] retain];
		
		NSLog(@"starting tests...");
		//[self doTests];
		NSLog(@"tests ended.");
		NSAssert(moduleDict,@"There was an error loading the xml file for the Plug-in: \"MEWeatherCom\"");
	}
	return self;
}

#pragma mark -

- (MEWeatherUnits *)unitsForCurrentConditionItemNamed:(NSString *)name
{
	if ([currentConditionItemsLookup objectForKey:name] && 
		[[currentConditionItemsLookup objectForKey:name] objectForKey:@"units"])
		return [[currentConditionItemsLookup objectForKey:name] objectForKey:@"units"];
	return MENoUnits;
}

// Provided an English item name, this provides the localized equivalent.  It looks up the object
// in the table currentConditionsLookup.
- (NSString *)currentConditionItemNamed:(NSString *)name
{
	if ([currentConditionItemsLookup objectForKey:name] && 
		[[currentConditionItemsLookup objectForKey:name] objectForKey:@"label"])
		return [[currentConditionItemsLookup objectForKey:name] objectForKey:@"label"];
	return @"DEFAULT";
}

- (MEWeatherUnits *)unitsForForecastItemNamed:(NSString *)name
{
	if ([forecastItemsLookup objectForKey:name] &&
		[[forecastItemsLookup objectForKey:name] objectForKey:@"units"])
		return [[forecastItemsLookup objectForKey:name] objectForKey:@"units"];
	return MENoUnits;
}

// Provided an English item name, this provides the localized equivalent.  It looks up the object
// in the table forecastItemsLookup.
- (NSString *)forecastItemNamed:(NSString *)name
{
	if ([forecastItemsLookup objectForKey:name] &&
		[[forecastItemsLookup objectForKey:name] objectForKey:@"label"])
		return [[forecastItemsLookup objectForKey:name] objectForKey:@"label"];
	return @"DEFAULT";
}


- (NSArray *)supportedCurrentConditionItems
{
	NSArray *allValues = [currentConditionItemsLookup allValues];
	NSMutableArray *currentConditionNames = [NSMutableArray arrayWithCapacity:[allValues count]];
	int i;
	
	for (i=0; i<[allValues count]; i++)
		[currentConditionNames addObject:[[allValues objectAtIndex:i] objectForKey:@"label"]];
	
	return currentConditionNames;
}

- (NSArray *)supportedForecastItems
{
	NSArray *allValues = [forecastItemsLookup allValues];
	NSMutableArray *forecastNames = [NSMutableArray arrayWithCapacity:[allValues count]];
	int i;
	
	for (i=0; i<[allValues count]; i++)
		[forecastNames addObject:[[allValues objectAtIndex:i] objectForKey:@"label"]];
	
	return forecastNames;
}

- (NSString *) searchURL
{
	return @"http://www.weather.com/search/enhanced?where=%@";
}
#pragma mark parsing downloaded weather data


- (NSString *)filenameForIconValue:(MEWeatherItem *)weatherItem
{	
	NSDictionary *weatherImagesLookup; // lookup dictionary. produces a file name for a value
	NSString     *imageFilename; // filename associated with value.
	NSString     *value = [weatherItem description];
	
	weatherImagesLookup = [moduleDict objectForKey:@"weatherImages"]; // from XML file
	imageFilename       = [weatherImagesLookup objectForKey:value];
	
	return imageFilename;
}

- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    NSImage *img = nil;
    
    NSString *name = [[string lastPathComponent] stringByDeletingPathExtension];
    
    NSString *imageName;
    
    if([key isEqualToString:@"Moon Phase"])
    {
        img = [[[NSImage alloc] initWithContentsOfFile:@"/Library/Application Support/Meteo/Weather Status/Moon.tiff"] autorelease];
        
        if(!img)
            [[[NSImage alloc] initWithContentsOfFile:[@"~/Library/Application Support/Meteo/Weather Status/Moon.tiff" stringByExpandingTildeInPath]] autorelease];
        
        if(img)
            return img;
    }
    
	NSDictionary *weatherImagesLookup = [moduleDict objectForKey:@"weatherImages"]; // from XML file
	
	imageName = [weatherImagesLookup objectForKey:name]; // from XML file
	if (!imageName)
		imageName = [weatherImagesLookup objectForKey:@"unknown"]; // from XML file

    img = [MEWeatherModule imageForFileName:imageName forDock:dock];
    
    return img;
}

#pragma mark performing search
- (NSArray *)performCitySearchOnPageContents:(NSString *)pageContents pageURL:(NSString *)pageURL
{	
	NSMutableArray *citiesFound = [NSMutableArray array];
	if (!pageContents)
	{
		NSLog(@"Error downloading search results");
		return [NSArray array];
	}
	
	//NSLog(@"Search URL: (%@).",[searchResultsURL absoluteString]);
	//NSLog(@"Search Results length = %i",[searchResults length]);
	
	// See if it is "NOT FOUND"
	// "City Not Found"
	AGRegex *notFoundRegex = [AGRegex regexWithPattern:@"No items found."];	
	AGRegexMatch *notFoundMatch = [notFoundRegex findInString:pageContents];
	if (notFoundMatch)
		NSLog(@"City Not Found");
	
	// See if there are Multiple Search Results
	// "Place: Temperature"
	AGRegex *matchesRegex = [AGRegex regexWithPattern:@"<B>\\d+\\..*/local/(.*)\\?.*(<B)?>(.*)(</B></A>|</A></B>)&nbsp;" options:AGRegexMultiline];
	NSArray *multipleMatchesArray = [matchesRegex findAllInString:pageContents];
	if (multipleMatchesArray && [multipleMatchesArray count])
	{
		//NSLog(@"Found Matches!:");
		//NSLog([multipleMatchesArray description]);
		int i;
		for (i=0; i<[multipleMatchesArray count]; i++)
		{
			AGRegexMatch *match    = [multipleMatchesArray objectAtIndex:i];
			NSString     *cityName = [match groupAtIndex:3];
			NSString     *code     = [match groupAtIndex:1];
			
			//NSLog(@"%@ ******* %@",cityName,code);
			
			[citiesFound addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:code,
				@"code",cityName,@"name",nil]];
		}
	}
	
	// See if there is a single Search Result.
	//  (if so then wunderground loads that page, so the URL we loaded contains the "code")
	AGRegex *zipMatchRegex = [AGRegex regexWithPattern:@"<B>Right Now for</B><BR>(.*) \\((.*)\\)<BR>"]; 
	AGRegexMatch *zipMatch = [zipMatchRegex findInString:pageContents];
	if (zipMatch)
	{
		//NSLog(@"Match Found:\n %@",zipMatch);
		NSString *cityName = [zipMatch groupAtIndex:1];
		NSString *code     = [zipMatch groupAtIndex:2];
		[citiesFound addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:code,
			@"code",cityName,@"name",nil]];
	}
	
	return citiesFound;
}

#pragma mark parsing downloaded weather data
- (NSDictionary *)parseWeatherDataForCode:(NSString *)code
{
    NSURL *url;
    NSString *pageContents;
    
	NSString *address = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
									(CFStringRef)[NSString stringWithFormat:[moduleDict objectForKey:@"weatherURL"],code],NULL,NULL,kCFStringEncodingUTF8);
    url = [NSURL URLWithString:address];
		
	pageContents = [[MEWebFetcher webFetcher] fetchURLtoString:url];	// autoreleased already

    if(!pageContents) // NSRunAlertPanel?
	{
		NSLog(@"The string for the URL was empty");
        return NO;
	}

	//NSLog(@"The string for the URL (%@) is %d long.",url,[pageContents length]);

    NSMutableDictionary *newWeatherData = [[NSMutableDictionary alloc] initWithCapacity:[[self supportedCurrentConditionItems] count]+1]; // +1 for Forecast Dictionary
    
    [newWeatherData setObject:[url absoluteString] forKey:@"Weather Link"];
    
	// This regex gets Weather Image, Current Conditions, Temperature, Feels Like
	AGRegex *basicsRegex = [AGRegex regexWithPattern:@"wxicons/52/(.*)\\.gif.*obsTextA>(.*)</B.*obsTempTextA>(.*)&deg;F</B>.*<BR>.*<B CLASS=obsTextA>.*Feels Like.*<BR> (.*)&deg;F</B></DIV></TD>"
											 options:AGRegexMultiline | AGRegexDotAll];
	AGRegexMatch *basicsMatch = [basicsRegex findInString:pageContents];

	//NSLog(@"basicsRegex found: %@",basicsMatch);
	
	// Weather Image
	MEWeatherUnits *imageUnits = [self unitsForCurrentConditionItemNamed:@"Weather Image"];
	[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:imageUnits
																value:[basicsMatch groupAtIndex:1]]
					   forKey:[self currentConditionItemNamed:@"Weather Image"]];
	
	// Current Conditions
	MEWeatherUnits *currentConditionsUnits = [self unitsForCurrentConditionItemNamed:@"Current Conditions"];
	[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:currentConditionsUnits
																value:[basicsMatch groupAtIndex:2]]
					   forKey:[self currentConditionItemNamed:@"Current Conditions"]];
	
	// Temperature
	MEWeatherUnits *temperatureUnits = [self unitsForCurrentConditionItemNamed:@"Temperature"];
	[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:temperatureUnits
																value:[NSString stringWithFormat:@"%@%C",
																	[basicsMatch groupAtIndex:3],(unichar)0x00B0]]
					   forKey:[self currentConditionItemNamed:@"Temperature"]];
	
	// Feels Like
	MEWeatherUnits *feelsLikeUnits = [self unitsForCurrentConditionItemNamed:@"Feels Like"];
	[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:feelsLikeUnits
																value:[NSString stringWithFormat:@"%@%C",
																	[basicsMatch groupAtIndex:4],(unichar)0x00B0]]
					   forKey:[self currentConditionItemNamed:@"Feels Like"]];
	
	// This regex gets UV Index, Wind, Humidity, Pressure, Dew Point, Visibility
	AGRegex *moreBasicsRegex = [AGRegex regexWithPattern:@"<TR>\\s*<TD VALIGN=\"top\"  CLASS=\"obsTextA\"( WIDTH=\"75\" )?>([\\w ]*):</td>\\s*<TD><IMG SRC=\"http://image.weather.com/web/blank.gif\" WIDTH=10 HEIGHT=1 BORDER=0 ALT=\"\"></td>\\s*<TD VALIGN=\"top\"  CLASS=\"obsTextA\">([\\.\\w %]*)(&nbsp;.*pressure.gif\">|&deg;F)?</td>\\s*</tr>"
												  options:AGRegexMultiline | AGRegexDotAll];
	NSArray *allMatches = [moreBasicsRegex findAllInString:pageContents];
	
	if (allMatches && [allMatches count])
	{
		int i;
		for (i=0; i<[allMatches count]; i++)
		{
			AGRegexMatch *match = [allMatches objectAtIndex:i];
			NSString *itemName  = [match groupAtIndex:2];
			NSString *itemValue = [match groupAtIndex:3];
			MEWeatherUnits *baseUnits = [self unitsForCurrentConditionItemNamed:itemName];
			if ([baseUnits isEqualToString:MEFahrenheitUnits])
			{
				//				NSLog(@"adding degree sign!");
				itemValue = [NSString stringWithFormat:@"%@%C",itemValue,(unichar)0x00B0];
			}
			else if ([baseUnits isEqualToString:MEMPHUnits])
			{
				itemValue = [itemValue stripSuffix:@" mph"];
			}
			else if ([baseUnits isEqualToString:MEMilesUnits])
			{
				itemValue = [itemValue stripSuffix:@" miles"];
			}
			NSString *localizedItemName = [self currentConditionItemNamed:itemName];
			[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																		value:itemValue]
							   forKey:localizedItemName];
			//NSLog(@"  Match No %d: %@ = %@",i,itemName,itemValue);
		}
		
	}
	else
	{
		NSLog(@"No matches found for moreBasicsRegex");
	}
	
	// Radar Image
	AGRegex *radarImageRegex = [AGRegex regexWithPattern:@"radar_76x56.jpg','(.*jpg)',"];
	AGRegexMatch *radarImageMatch = [radarImageRegex findInString:pageContents];
	
	MEWeatherUnits *radarImageUnits = [self unitsForCurrentConditionItemNamed:@"Radar Image"];
	[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:radarImageUnits
																value:[radarImageMatch groupAtIndex:1]]
					   forKey:[self currentConditionItemNamed:@"Radar Image"]];
	
	//NSLog(@"  Radar Image = %@",[radarImageMatch groupAtIndex:1]);
	NSArray *forecastArray = [self parseExtendedForecastForCode:code];
    [newWeatherData setObject:forecastArray forKey:@"Forecast Array"];

	//NSLog([newWeatherData description]);
	return [newWeatherData autorelease];
}

-(NSArray *)parseSevereWeatherAlertsInString:(NSString *)alertHTML
{
	NSMutableArray *weatherAlerts = [NSMutableArray array];
	MEStringSearcher *alertsSS = [MEStringSearcher stringSearcherWithString:alertHTML];
    while(alertHTML != nil)
    {
		NSMutableDictionary *diction = [NSMutableDictionary dictionary];
		//<A CLASS=\"svrWxAlertText\" HREF=\"/weather/alerts/?alertId=41944&dbSeq=null\"
		NSString *alertString = [alertsSS getStringWithLeftBound:@"HREF=\\\"/weather/alerts/"
													  rightBound:@"\\\""]; 

        if(!alertString)
            break;
		
		// download this alert's HTML
		NSString *alertURL = [moduleDict objectForKey:@"alertURL"]; // from XML file
        NSString *alertHTML = [[MEWebFetcher sharedInstance] fetchURLtoString:
									[NSURL URLWithString:[NSString stringWithFormat:alertURL,alertString]]];
        
        if(!alertHTML)
            continue;
		
		// parse the alerts HTML for the good text
        MEStringSearcher *alertHTMLSS = [MEStringSearcher stringSearcherWithString:alertHTML];
        NSString *alert = [alertHTMLSS getStringWithLeftBound:@"<TD CLASS=\"blkVerdanaText11\">"
												   rightBound:@"</TD>"];
                             
        if(!alert)
            continue;
          
		// replace <P>'s with 2 newlines
        alert = [[alert componentsSeparatedByString:@"<P>"] componentsJoinedByString:@"\n\n"];
        
        if(alert)
        {
            [diction setObject:@"Weather Alert" forKey:@"title"];
            [diction setObject:alertString forKey:@"description"];
            
            [weatherAlerts addObject:diction];
        }     
    }
	return weatherAlerts;
}

-(NSArray *)parseExtendedForecastForCode:(NSString *)code
{
	NSMutableArray *forecastArray = [NSMutableArray array]; 
	NSArray *months = [NSArray arrayWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec",nil];
	NSURL *url = [NSURL URLWithString:(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
																				  (CFStringRef)[NSString stringWithFormat:@"http://www.weather.com/weather/mpdwcr/tenday?locid=%@",code],NULL,NULL,kCFStringEncodingUTF8)];
	if(!url)
	{
		NSLog(@"There was a problem creating the URL for code: %@.",code);
		return forecastArray;
	}
	
	NSString *pageContents = [[MEWebFetcher sharedInstance] fetchURLtoString:url];
	if(!pageContents)
	{
		NSLog(@"The string for the forecast data for URL %@ was empty.",url);
		return forecastArray;
	}
	//NSLog(pageContents);
	
	// 1  = Month
	// 2  = Day #
	// 3  = Day Name
	// 4  = High
	// 5  = Low
	// 6  = UV Index
	// 7  = URL of Icon
	// 8  = Forecast
	// 9  = Wind Speed
	// 10 = Short Wind Direction
	// 11 = Chance of Precip
	// 12 = Humidity
	//AGRegex *dailyForecastRegex = [AGRegex regexWithPattern:@"mpdData['dayf']\\.day[\\d]=new mpdFDObj\\(new Date\\('\\d+','(\\d+)','(\\d+)','\\d','\\d','\\d'\\),'(\\w+)','(\\d+)','(\\d+)','(\\d+)','(\\d+)','([\\w ]+)','([\\d\\w ]+)','[\\w ]*','(\\w+)','(\\d+)', '(\\d+)'\\);"];
	AGRegex *dailyForecastRegex = [AGRegex regexWithPattern:@"new mpdFDObj\\(new Date\\('\\d+','(\\d+)','(\\d+)','\\d','\\d','\\d'\\),'(\\w+)','([\\d\\+]+)','([\\d\\+]+)','([\\d\\+]+)','([\\d\\+]+)','([\\w ]+)','([\\d\\w ]+)','[\\w ]*','(\\w+)','(\\d+)', '(\\d+)'\\);"
													options:AGRegexMultiline];
	NSArray *allMatches = [dailyForecastRegex findAllInString:pageContents];
	
	if (allMatches && [allMatches count])
	{
		int i;
		for (i=0; i<[allMatches count]; i++)
		{
			AGRegexMatch *match = [allMatches objectAtIndex:i];
			//NSLog([match description]);
			NSMutableDictionary *forecastDictionary = [NSMutableDictionary dictionaryWithCapacity:[[self supportedForecastItems] count]];
				
			// Date
			MEWeatherUnits *dateUnits  = [self unitsForForecastItemNamed:@"Date"];
			NSString       *dateString = [NSString stringWithFormat:@"%@ %@",[months objectAtIndex:[[match groupAtIndex:1] intValue]],[match groupAtIndex:2]];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:dateUnits
																		value:dateString]
							   forKey:[self forecastItemNamed:@"Date"]];
			// Day
			MEWeatherUnits *dayUnits  = [self unitsForForecastItemNamed:@"Day"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:dayUnits
																		value:[match groupAtIndex:3]]
							   forKey:[self forecastItemNamed:@"Day"]];			
			// High
			MEWeatherUnits *highUnits = [self unitsForForecastItemNamed:@"High"];
			NSString       *highTemp  = [NSString stringWithFormat:@"%@%C",[match groupAtIndex:4],(unichar)0x00B0];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:highUnits
																		value:highTemp]
							   forKey:[self forecastItemNamed:@"High"]];		
			// Low
			MEWeatherUnits *lowUnits = [self unitsForForecastItemNamed:@"Low"];
			NSString       *lowTemp  = [NSString stringWithFormat:@"%@%C",[match groupAtIndex:5],(unichar)0x00B0];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:lowUnits
																		value:lowTemp]
							   forKey:[self forecastItemNamed:@"Low"]];				
			// UV Index
			MEWeatherUnits *uvIndexUnits = [self unitsForForecastItemNamed:@"UV Index"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:uvIndexUnits
																		value:[match groupAtIndex:6]]
							   forKey:[self forecastItemNamed:@"UV Index"]];
			// Icon
			MEWeatherUnits *iconUnits = [self unitsForForecastItemNamed:@"Icon"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:iconUnits
																		value:[match groupAtIndex:7]]
							   forKey:[self forecastItemNamed:@"Icon"]];
			// Forecast
			MEWeatherUnits *forecastUnits = [self unitsForForecastItemNamed:@"Forecast"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:forecastUnits
																		value:[match groupAtIndex:8]]
							   forKey:[self forecastItemNamed:@"Forecast"]];
			// Wind Speed
			MEWeatherUnits *windSpeedUnits = [self unitsForForecastItemNamed:@"Wind Speed"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:windSpeedUnits
																		value:[match groupAtIndex:9]]
							   forKey:[self forecastItemNamed:@"Wind Speed"]];
			// Wind Direction
			MEWeatherUnits *windDirUnits = [self unitsForForecastItemNamed:@"Wind Direction"];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:windDirUnits
																		value:[match groupAtIndex:10]]
							   forKey:[self forecastItemNamed:@"Wind Direction"]];
			// Chance Precip
			MEWeatherUnits *chancePrecipUnits = [self unitsForForecastItemNamed:@"Chance Precip"];
			NSString       *chancePrecipString = [NSString stringWithFormat:@"%@%%",[match groupAtIndex:11]];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:chancePrecipUnits
																			value:chancePrecipString]
								   forKey:[self forecastItemNamed:@"Chance Precip"]];
			// Humidity
			MEWeatherUnits *humidityUnits  = [self unitsForForecastItemNamed:@"Humidity"];
			NSString       *humidityString = [NSString stringWithFormat:@"%@%%",[match groupAtIndex:12]];
			[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:humidityUnits
																		value:humidityString]
							   forKey:[self forecastItemNamed:@"Humidity"]];
			[forecastArray addObject:forecastDictionary];
		}
	}
	else
	{
		NSLog(@"No Extended Forecasts Found");
	}

	return forecastArray;
}

#pragma mark Tests!

- (BOOL) testSearchForNotFound
{
	NSString *searchTerm = @"blahblah";
	NSString *percentEscapedSearchURLAsString = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, 
								(CFStringRef)[NSString stringWithFormat:[self searchURL],searchTerm],NULL,NULL,kCFStringEncodingUTF8);
		
	NSString *pageContents  = [[MEWebFetcher webFetcher] fetchURLtoString:[NSURL URLWithString:percentEscapedSearchURLAsString]];
	NSArray  *searchResults = [self performCitySearchOnPageContents:pageContents pageURL:percentEscapedSearchURLAsString];
	NSAssert([searchResults count] == 0,@"search results should be empty");
	return true;
}

- (NSDictionary *)dictionaryForCode:(NSString *)shouldBeCode name:(NSString *)shouldBeName
{
	return [NSDictionary dictionaryWithObjectsAndKeys:shouldBeCode,
		@"code",shouldBeName,@"name",nil];
}

- (BOOL) testSearchForCityNamed:(NSString *)searchName expectedArray:(NSArray *)expected
{
	NSString *percentEscapedSearchURLAsString = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, 
					   (CFStringRef)[NSString stringWithFormat:[self searchURL],searchName],NULL,NULL,kCFStringEncodingUTF8);
	NSString *pageContents  = [[MEWebFetcher webFetcher] fetchURLtoString:[NSURL URLWithString:percentEscapedSearchURLAsString]];
	NSArray  *searchResults = [self performCitySearchOnPageContents:pageContents pageURL:percentEscapedSearchURLAsString];

	NSAssert([searchResults isEqualToArray:expected], ([NSString stringWithFormat:@"Search Results doesn't equal: %@",expected]));
	
	return true;
}

- (BOOL) testSearchForMyCities
{
	[self testSearchForCityNamed:@"Easton, PA" expectedArray:
		[NSArray arrayWithObject:[self dictionaryForCode:@"USPA0467" name:@"Easton, Pennsylvania, United States"]]];
	[self testSearchForCityNamed:@"18042" expectedArray:
		[NSArray arrayWithObject:[self dictionaryForCode:@"18042" name:@"Easton, PA"]]];
	
	return true;
}

- (BOOL) testSearchForMajorUSCities
{
	[self testSearchForCityNamed:@"New York, NY" expectedArray:
		[NSArray arrayWithObjects:[self dictionaryForCode:@"USNY0996" name:@"New York, New York, United States"],
			[self dictionaryForCode:@"USNY0011" name:@"Albany, New York, United States"],
			[self dictionaryForCode:@"USNY0181" name:@"Buffalo, New York, United States"],
			[self dictionaryForCode:@"USNY1010" name:@"Niagara Falls, New York, United States"],
			[self dictionaryForCode:@"USNY1232" name:@"Rochester, New York, United States"],
			[self dictionaryForCode:@"USNY1434" name:@"Syracuse, New York, United States"],
			nil]];
	[self testSearchForCityNamed:@"Boston, MA" expectedArray:
		[NSArray arrayWithObject:[self dictionaryForCode:@"USMA0046" name:@"Boston, Massachusetts, United States"]]];
	
	return true;
}

- (BOOL) testSearchForInternationalCities
{
	[self testSearchForCityNamed:@"Galway, Ireland" expectedArray:
		[NSArray arrayWithObject:[self dictionaryForCode:@"EIXX0017" name:@"Galway, Ireland"]]];
	[self testSearchForCityNamed:@"Paris, France" expectedArray:
		[NSArray arrayWithObjects:[self dictionaryForCode:@"FRXX0076" name:@"Paris, France"],
			[self dictionaryForCode:@"FRXX0077" name:@"Paris/Charles De Gaulle, France"],nil]];
	[self testSearchForCityNamed:@"Paris" expectedArray:
		[NSArray arrayWithObjects:[self dictionaryForCode:@"FRXX0076" name:@"Paris, France"],
			[self dictionaryForCode:@"USID0192" name:@"Paris, Idaho, United States"],
			[self dictionaryForCode:@"USOH0676" name:@"New Paris, Ohio, United States"],
			[self dictionaryForCode:@"USIN0471" name:@"New Paris, Indiana, United States"],
			[self dictionaryForCode:@"USKY1218" name:@"Paris, Kentucky, United States"],
			[self dictionaryForCode:@"USIL0920" name:@"Paris, Illinois, United States"],
			[self dictionaryForCode:@"USPA1171" name:@"New Paris, Pennsylvania, United States"],
			[self dictionaryForCode:@"USAR0433" name:@"Paris, Arkansas, United States"],
			nil]];
	[self testSearchForCityNamed:@"Sydney, Australia" expectedArray:
		[NSArray arrayWithObjects:[self dictionaryForCode:@"ASXX0112" name:@"Sydney, Australia"],
			[self dictionaryForCode:@"ASXX0274" name:@"Sydney Regional Office, Australia"],nil]];
	
	return true;
}

- (void) doTests
{
	[self testSearchForNotFound];
	[self testSearchForMyCities];
	[self testSearchForMajorUSCities];
	[self testSearchForInternationalCities];
}

@end

