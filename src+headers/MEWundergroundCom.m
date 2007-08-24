//
//  MEWundergroundCom.m
//  Meteorologist
//
//  Created by Joseph Crobak on 2/11/05.
//
//  Copyright (c) 2005 Joe Crobak  
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

#import "MEWundergroundCom.h"
#import "MEWeatherItem.h"
#import "MEWebUtils.h"
#import "NSString-Additions.h"
//#import "MEConstants.h"
#import <AGRegex/AGRegex.h>

@implementation MEWundergroundCom

- (id)initWithBundlePath:(NSString *)bundlePath
{
	self = [super init];
	if (self)
	{
		NSString *path          = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"WundergroundCom" ofType:@"xml"];
		moduleDict              = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
		currentConditionItemsLookup = 
			[[NSDictionary dictionaryWithObjectsAndKeys:		
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Weather Image",@""),@"label",
					MENoUnits,@"units",nil],
				@"Weather Image",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Clouds",@""),@"label",
					MEFeetUnits,@"units",nil],
				@"Clouds",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Temperature",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Temperature",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Windchill",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Windchill",
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
				@"Conditions",
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
					NSLocalizedString(@"Yesterday's Max",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Yesterday's Maximum",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Yesterday's Min",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Yesterday's Minimum",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Yesterday's Heating Deg. Days",@""),@"label",
					MENoUnits,@"units",nil],
				@"Yesterday's Heating Degree Days",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Yesterday's Cooling Deg. Days",@""),@"label",
					MENoUnits,@"units",nil],
				@"Yesterday's Cooling Degree Days",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Sunrise",@""),@"label",
					MEUnitsIncludedWithValue,@"units",nil],
				@"Sunrise",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Sunset",@""),@"label",
					MEUnitsIncludedWithValue,@"units",nil],
				@"Sunset",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Moon Rise",@""),@"label",
					MEUnitsIncludedWithValue,@"units",nil],
				@"Moon Rise",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Moon Set",@""),@"label",
					MEUnitsIncludedWithValue,@"units",nil],
				@"Moon Set",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Moon Phase",@""),@"label",
					MENoUnits,@"units",nil],
				@"Moon Phase",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Moon Phase Image",@""),@"label",
					MENoUnits,@"units",nil],
				@"Moon Phase Image",
				nil] retain];

		forecastItemsLookup = 
			[[NSDictionary dictionaryWithObjectsAndKeys:
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
					NSLocalizedString(@"Overnight Forecast",@""),@"label",
					MENoUnits,@"units",nil],
				@"Overnight Forecast",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"High",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"High",
				[NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedString(@"Low",@""),@"label",
					MEFahrenheitUnits,@"units",nil],
				@"Low",
				nil] retain];
		
		NSAssert(moduleDict,@"There was an error loading the xml file for the Plug-in: \"MEWundergroundCom\"");
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
	return @"http://mobile.wunderground.com/cgi-bin/findweather/getForecast?brand=mobile&query=%@";
}


#pragma mark parsing downloaded weather data

- (NSDictionary *)parseWeatherDataForCode:(NSString *)code
{
	NSURL    *url = [NSURL URLWithString:code];
	NSString *pageContents;

#ifdef DEBUG
	NSLog(@"Loading: %@",url);
#endif
	
	pageContents = [[MEWebFetcher webFetcher] fetchURLtoString:url];
	
	if(!pageContents)
	{
		//NSLog(@"Failed downloading: %@",url);
		return nil;
	}
	
#ifdef DEBUG
	NSLog(@"The string for the URL is %d long.",[pageContents length]);
#endif
	
	NSMutableDictionary *newWeatherData = [[NSMutableDictionary alloc] initWithCapacity:[[self supportedCurrentConditionItems] count]+1]; // +1 for Forecast Dictionary
	
	[newWeatherData setObject:[url absoluteString] forKey:@"Weather Link"];
	
	// This regex, as of 02.22.05 provides:
	// Temperature, Windchill, Humidity, Dew Point, Wind, Pressure, Conditions, Visibility, Clouds, Yesterday's Maximum,
	// Yesterday's Minimum, Yesterday's Heating Degree Days, Sunrise, Sunset, Moon Rise, Moon Set	
	AGRegex *CCRegex = [AGRegex regexWithPattern:@"<tr><td>\\s*([ \\w']*)\\s*</td>[.\\s]*<td>[.\\s]*(<span class=\"nowrap\">)*[.\\s]*<b>(.*)</b>" options:AGRegexMultiline];
	NSArray *allCurrCondItems = [CCRegex findAllInString:pageContents];
	
	if (allCurrCondItems && [allCurrCondItems count])
	{
		int i;
		for (i=0; i<[allCurrCondItems count]; i++)
		{
			AGRegexMatch *match = [allCurrCondItems objectAtIndex:i];
			NSString *itemName  = [match groupAtIndex:1]; 
			NSString *itemValue = [match groupAtIndex:3];
			MEWeatherUnits *baseUnits = [self unitsForCurrentConditionItemNamed:itemName];
			if ([baseUnits isEqualToString:MEFahrenheitUnits])
			{
//				NSLog(@"adding degree sign!");
				itemValue = [NSString stringWithFormat:@"%@%C",itemValue,(unichar)0x00B0];
			}
			NSString *localizedItemName = [self currentConditionItemNamed:itemName];
			[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																		value:itemValue]
							   forKey:localizedItemName];
			
//			NSLog(@"%@: %@",localizedItemName,[newWeatherData objectForKey:localizedItemName]);
		}
	}
		
	// Special wind match
	AGRegex *windRegex = [AGRegex regexWithPattern:@"<tr><td>Wind</td>[.\\s]*<td>[.\\s]*<b>(.*)</b> at[.\\s]*(<span class=\"nowrap\">)*[.\\s]*<b>(.*)</b>" options:AGRegexMultiline];
	AGRegexMatch *windMatch = [windRegex findInString:pageContents];
	if (windMatch)
	{
		NSString *itemValue = [NSString stringWithFormat:NSLocalizedString(@"%@ %@",@""),
			[windMatch groupAtIndex:1],[windMatch groupAtIndex:3]];
		MEWeatherUnits *baseUnits = [self unitsForCurrentConditionItemNamed:@"Wind"];
		[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																	value:itemValue]
						   forKey:[self currentConditionItemNamed:@"Wind"]];
	}
	
	// Special clouds match
	AGRegex *cloudsRegex = [AGRegex regexWithPattern:@"<tr><td>Clouds</td>[.\\s]*<td>[.\\s]*<b>(.*)</b>[.\\s]*([\\(\\)\\w]*)[.\\s]*:[.\\s]*(<span class=\"nowrap\">)*[.\\s]*<b>(.*)</b>" options:AGRegexMultiline];
	AGRegexMatch *cloudsMatch = [cloudsRegex findInString:pageContents];
	if (cloudsMatch)
	{
		NSString *itemValue = [NSString stringWithFormat:@"%@ %@: %@",[cloudsMatch groupAtIndex:1],[cloudsMatch groupAtIndex:2],[cloudsMatch groupAtIndex:4]];
		MEWeatherUnits *baseUnits = [self unitsForCurrentConditionItemNamed:@"Clouds"];
		[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																	value:itemValue]
						   forKey:[self currentConditionItemNamed:@"Clouds"]];
	}
	
	// Special moon phase match
	AGRegex *moonPhaseRegex = [AGRegex regexWithPattern:@"<tr><td>Moon Phase</td><td><img src=\"(.*gif)\".*<br>(.*)</td>" options:AGRegexMultiline];
	AGRegexMatch *moonPhaseMatch = [moonPhaseRegex findInString:pageContents];
	if (moonPhaseMatch)
	{
		MEWeatherUnits *baseUnits = [self unitsForCurrentConditionItemNamed:@"Moon Phase Image"];
		[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																	value:[moonPhaseMatch groupAtIndex:1]]
						   forKey:[self currentConditionItemNamed:@"Moon Phase Image"]];
		baseUnits = [self unitsForCurrentConditionItemNamed:@"Moon Phase"];
		[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:baseUnits
																	value:[moonPhaseMatch groupAtIndex:2]]
						   forKey:[self currentConditionItemNamed:@"Moon Phase"]];
	}
	
	// special radar image match
	AGRegex *radarImageRegex = [AGRegex regexWithPattern:@"/nids/(.*)19"];
	AGRegexMatch *radarImageMatch = [radarImageRegex findInString:pageContents];
	if (radarImageMatch)
	{
		[newWeatherData setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:@"Radar Image"]
																	value:[NSString stringWithFormat:@"http://radblast.wunderground.com/cgi-bin/radar/WUNIDS?station=%@&brand=new",[radarImageMatch groupAtIndex:1]]]
						   forKey:[self currentConditionItemNamed:@"Radar Image"]];		
	}
	
	// special weather alert match
	AGRegex *weatherAlertRegex = [AGRegex regexWithPattern:@"National Weather Service:.*<a href=\"(.*)\">.*Statement</a>" options:AGRegexMultiline | AGRegexDotAll];
	AGRegexMatch *weatherAlertMatch = [weatherAlertRegex findInString:pageContents];
	if (weatherAlertMatch)
	{
		NSLog(@"Weather Alert found for %@!",code);
		NSURL *alertURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.wunderground.com%@",[weatherAlertMatch groupAtIndex:1]]];
		NSArray *alerts = [self parseWeatherAlertForURL:alertURL];
		
		[newWeatherData setObject:alerts
						   forKey:[self currentConditionItemNamed:@"Weather Alert"]];
	}
	else
	{
		NSLog(@"NO Weather Alert found for %@.",code);
	}
	
	// Extended Forecast match - needs to be thoroughly tested
	AGRegex *forecastRegex = [AGRegex regexWithPattern:@"src=\"(.*)\" width.*\\s?.*<b>(.*)</b><br />\\s*(.*)\\.\\s*(High|Low)s?:?\\s*([\\w ]*) (\\d*s?)." options:AGRegexMultiline];
	NSArray *forecastMatches = [forecastRegex findAllInString:pageContents];
	NSMutableArray *forecastArray = [NSMutableArray array]; 
	NSMutableDictionary *forecastDictionary;

	if (forecastMatches && [forecastMatches count])
	{
		int i;
		for (i=0; i<[forecastMatches count]; i++)
		{
			// Possible localizations for "Forecast"
			// NSLocalizedString(@"Partly cloudy",@"");
			// NSLocalizedString(@"Mostly cloudy",@"");
			// NSLocalizedString(@"Increasing clouds",@"");
			
			// Possible localizeable for "highs _____ deg"
			// NSLocalizedString(@"around",@"");
			// NSLocalizedString(@"in the",@"");
			// NSLocalizedString(@"in the upper",@"");
			// NSLocalizedString(@"in the mid",@"");
			
			forecastDictionary = [NSMutableDictionary dictionary];

			BOOL isNight = NO;
			AGRegexMatch *match = [forecastMatches objectAtIndex:i];
			//NSLog(@"%@",match);
			
			if([match groupAtIndex:2]) { // day

				if ([[match groupAtIndex:2] hasSuffix:@"Night"] || [[match groupAtIndex:2] isEqualToString:@"Tonight"])
				{
					isNight = YES;
					if ([forecastArray lastObject] && [[forecastArray lastObject] objectForKey:@"Day"])
						forecastDictionary = [forecastArray lastObject];
				}
				else
					[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:@"Day"]
																					value:[match groupAtIndex:2]]
										   forKey:[self forecastItemNamed:@"Day"]];        
			}
			if([match groupAtIndex:1] && !isNight) // first group is src=(...)
				[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:@"Icon"]
																		 value:[match groupAtIndex:1]]
									   forKey:[self forecastItemNamed:@"Icon"]];
			
			if([match groupAtIndex:3] && !isNight)
				[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:@"Forecast"]
																		 value:[match groupAtIndex:3]]
									   forKey:[self forecastItemNamed:@"Forecast"]];
			else if ([match groupAtIndex:3])
				[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:@"Overnight Forecast"]
																				value:[match groupAtIndex:3]]
									   forKey:[self forecastItemNamed:@"Overnight Forecast"]];
			
			if([match groupAtIndex:4] && [match groupAtIndex:5] && [match groupAtIndex:6])
				[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:[match groupAtIndex:4]]
																		 value:[NSString stringWithFormat:@"%@ %@ %@",[match groupAtIndex:4],[match groupAtIndex:5],[match groupAtIndex:6]]]
									   forKey:[self forecastItemNamed:[match groupAtIndex:4]]];
			else if([match groupAtIndex:4] && [match groupAtIndex:6])
				[forecastDictionary setObject:[MEWeatherItem weatherItemWithBaseUnits:[self unitsForForecastItemNamed:[match groupAtIndex:5]]
																		 value:[NSString stringWithFormat:@"%@: %@",[match groupAtIndex:4],[match groupAtIndex:6]]]
									   forKey:[self forecastItemNamed:[match groupAtIndex:5]]];
			if (!isNight)
				[forecastArray addObject:forecastDictionary];
		}
	}
	NSDictionary *firstDay;
	MEWeatherItem *firstDayIcon;
	if ((firstDay     = [forecastArray objectAtIndex:0]) && 
		(firstDayIcon = [firstDay objectForKey:[self forecastItemNamed:@"Icon"]]))
	{
		[newWeatherData setObject:firstDayIcon forKey:@"Weather Image"];
	}
	[newWeatherData setObject:forecastArray forKey:@"Forecast Array"];
	
	return [newWeatherData autorelease];
}

//
// Returns NSArray with the search results for the given searchTerm (empty array if no results)
//
- (NSArray *)performCitySearchOnPageContents:(NSString *)pageContents pageURL:(NSString *)pageURL
{	
	NSString *serverAddressPrefix = @"http://mobile.wunderground.com";
	if (!pageContents)
	{
		NSLog(@"Error downloading search results");
		return [NSArray array];
	}

	//NSLog(@"Search Results length = %i",[pageContents length]);
	NSMutableArray *citiesFound = [NSMutableArray array];
	
	// See if it is "NOT FOUND"
	// "City Not Found"
	AGRegex *notFoundRegex = [AGRegex regexWithPattern:@"City Not Found"];	
	AGRegexMatch *notFoundMatch = [notFoundRegex findInString:pageContents];
	if (notFoundMatch)
		NSLog(@"City Not Found");
	
	// See if there are Multiple Search Results
	// "Place: Temperature"
	AGRegex *multipleMatchesRegex = [AGRegex regexWithPattern:@"<a href=\"(.*)\">(.*)</a>\\s?:"];
	NSArray *multipleMatchesArray = [multipleMatchesRegex findAllInString:pageContents];
	if (multipleMatchesArray && [multipleMatchesArray count])
	{
		NSLog(@"Found Matches!:");
		int i;
		for (i=0; i<[multipleMatchesArray count]; i++)
		{
			AGRegexMatch *match = [multipleMatchesArray objectAtIndex:i];
			NSLog(@"%@: %@",[match groupAtIndex:2],[match groupAtIndex:1]);
			[citiesFound addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[serverAddressPrefix stringByAppendingString:[match groupAtIndex:1]],
				@"code",[match groupAtIndex:2],@"name",nil]];
		}
	}
	
	// See if there is a single Search Result.
	//  (if so then wunderground loads that page, so the URL we loaded contains the "code")
	AGRegex *singleMatchRegex = [AGRegex regexWithPattern:@"<title>\\s(.*)\\sForecast</title>"]; 
	AGRegexMatch *singleMatch = [singleMatchRegex findInString:pageContents];
	if (singleMatch)
	{
		//NSLog(@"Match Found:\n %@",singleMatch);
		
		[citiesFound addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[singleMatch groupAtIndex:1],
			@"name",pageURL,@"code",nil]];
	}
	return citiesFound;
	
}

- (NSArray *)parseWeatherAlertForURL:(NSURL *)alertURL
{
	//NSLog(@"alert url = %@",alertURL);
	NSMutableString *alertString;
	NSString *alertTitle;
	NSString *pageContents = [[MEWebFetcher webFetcher] fetchURLtoString:alertURL];
	
	AGRegex *alertStringRegex = [AGRegex regexWithPattern:@"<img src=\"[\\S ]*><b>([\\S ]*)</b><img src=\"[\\S\\s]*<center><b>(Statement[\\S ]*)</b></center><br />([\\S\\s]*)</td>\\s*</tr>\\s*</table>\\s*<br /><a href=\"[\\S]*\">Return to city page</a>"
												  options:AGRegexMultiline | AGRegexLazy];
//	AGRegex *alertStringRegex = [AGRegex regexWithPattern:@"<center><b>(Statement[\\S ]*)</b></center><br />([\\S\\s]*)</td>\\s*</tr>\\s*</table>\\s*<br /><a href=\"[\\S]*\">Return to city page</a>"
//												  options:AGRegexMultiline | AGRegexLazy];
	
	NSArray *alertMatches = [alertStringRegex findAllInString:pageContents];
	NSMutableArray *alerts = [NSMutableArray arrayWithCapacity:[alertMatches count]];	
	AGRegexMatch *alertStringMatch;
	int i;
	for (i = 0; i < [alertMatches count]; i++)
	{
		alertStringMatch = [alertMatches objectAtIndex:i];
		if (alertStringMatch != nil)
		{
			alertString = [[NSString stringWithFormat:@"%@:\n%@",[alertStringMatch groupAtIndex:2],[alertStringMatch groupAtIndex:3]] mutableCopy];
			[alertString replaceOccurrencesOfString:@"<br>" 
										 withString:@"\n" 
											options:NULL 
											  range:NSMakeRange(0,[alertString length])];
			[alertString replaceOccurrencesOfString:@"&nbsp;" 
										 withString:@" " 
											options:NULL 
											  range:NSMakeRange(0,[alertString length])];
			
			alertString = [[alertString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
			alertTitle  = [alertStringMatch groupAtIndex:1];
			
			[alerts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				alertString,@"description",
				alertTitle,@"title",
				[alertURL absoluteString],@"url",
				nil]];
		}
	}
	
	NSLog(@"alert matches: %i",[alertMatches count]);
	return alerts;
}

- (NSString *)filenameForIconValue:(MEWeatherItem *)weatherItem
{
	NSDictionary *weatherImagesLookup; // lookup dictionary. produces a file name for a value
	NSString     *imageFilename; // filename associated with value.
	NSString     *value = [weatherItem description];
	weatherImagesLookup = [moduleDict objectForKey:@"weatherImages"]; // from XML file
	imageFilename       = [weatherImagesLookup objectForKey:[[value lastPathComponent] stringByDeletingPathExtension]];
	
	return imageFilename;
}

- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
	NSImage *img = nil;
    
    NSString *name = [[string lastPathComponent] stringByDeletingPathExtension];
    
    NSString *imageName;	
    
    if([key isEqualToString:@"Moon Phase Image"])
    {
        name = [name stripPrefix:@"moon"];
        
        img = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"Dock Icons/Moon Phase/MoonPhase-%@.tiff",name]] autorelease];
        
        if(!img)
            img = [[[NSImage alloc] initWithContentsOfFile:@"Dock Icons/Weather Status/Moon.tiff"] autorelease];
		
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
@end
