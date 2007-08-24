//
//  MECity.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Sat Jan 04 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//  Major Portions Copyright (c) 2004 Joe Crobak
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

#import "MECity.h"
#import "MEPlug-inManager.h"
#import "MEAppearancePreferencesModule.h"
#import "MEWeatherItem.h"

#define MAX_NUM_MODULES 3

@implementation MECity

#pragma mark Constructor/Destructor
// @called-by:  MECity defaultCity

- (id)init
{
	return [self initWithCityName:@"Default City"];
}

- (id)initWithCityName:(NSString*)name
{
	self = [super init];
	if (self)
	{
		cityName             = [[name copy] retain];
		isActive             = NO;
		rawData              = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];	
		usesCustomRadarImage = NO;
		customRadarImageURL  = [[NSString string] retain];
		prepareDataLock      = [[NSLock alloc] init];
		radarImage           = nil;
		
		// set up the serverTableDataSource with all of the weather servers.
		NSArray      *moduleNames = [[MEPlug_inManager defaultManager] moduleNames];
		NSEnumerator *itr = [moduleNames objectEnumerator];
		NSString     *modName;
		NSDictionary *moduleDictionary;
		int rowIndex = 0;
		serverTableData = [[MEServerTableDataSource alloc] initWithRowCount:[moduleNames count]];
		
		// for each module
		while (modName = [itr nextObject]) // each server/module is add disabled, with its name and -1 code.
		{
			moduleDictionary = [NSDictionary  dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:NO],@"enabled",
				modName, @"moduleName",
				@"",@"code",nil];
			
			[serverTableData setData:moduleDictionary forRow:rowIndex++];			
		}
		
	}
	return self;
}

+ (MECity *)defaultCity
{                             
    return [[[MECity alloc] init] autorelease];
}

- (void)dealloc
{
    [cityName release];
	[rawData release];
	[prepareDataLock release];
	[serverTableData release];
	
	[super dealloc];
}

#pragma mark Archiving/Unarchiving
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:cityName forKey:@"name"];
	[encoder encodeObject:[NSNumber numberWithBool:isActive] forKey:@"isActive"];
	[encoder encodeObject:serverTableData forKey:@"serverTableData"];
	
	[encoder encodeObject:[NSNumber numberWithBool:usesCustomRadarImage] forKey:@"usesCustomRadarImage"];
	[encoder encodeObject:customRadarImageURL forKey:@"customRadarImageURL"];
}

// this method contains some error checking because upgrades to the software in the past have
//  crashed in this function.  If a new field has been created in the new version and the 
//  prefs file didn't have a value for that pref.
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
		id tempObj;
		
		if (cityName = [decoder decodeObjectForKey:@"name"])
			[cityName retain];
		else
			cityName = [[NSString stringWithString:@"Default City"] retain];
		
		if (tempObj = [decoder decodeObjectForKey:@"isActive"])
			isActive = [tempObj boolValue];
		else
			isActive = NO;
		
		
		
		// set up the serverTableDataSource with all of the weather servers.
		NSArray      *moduleNames = [[MEPlug_inManager defaultManager] moduleNames];
		NSEnumerator *itr = [moduleNames objectEnumerator];
		NSString     *modName;
		NSDictionary *moduleDictionary;
		int rowIndex = 0;
		if (serverTableData = [decoder decodeObjectForKey:@"serverTableData"])
			[serverTableData retain];
		else
		{
			serverTableData = [[MEServerTableDataSource alloc] initWithRowCount:[moduleNames count]];
			
			// for each module
			while (modName = [itr nextObject]) // each server/module is add disabled, with its name and -1 code.
			{
				moduleDictionary = [NSDictionary  dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:NO],@"enabled",
					modName, @"moduleName",
					@"",@"code",nil];
				
				[serverTableData setData:moduleDictionary forRow:rowIndex++];			
			}
		}

		if (tempObj = [decoder decodeObjectForKey:@"usesCustomRadarImage"])
			usesCustomRadarImage = [tempObj boolValue];
		else
			usesCustomRadarImage = NO;
		
		if (customRadarImageURL = [decoder decodeObjectForKey:@"customRadarImageURL"])
			[customRadarImageURL retain];
		else
			customRadarImageURL = [[NSString string] retain];
		
		// not from file
		rawData         = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];	
		prepareDataLock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark Setters/Accessors

- (MEServerTableDataSource *)serverTableDataSource
{
	return [[serverTableData retain] autorelease];
}

- (void)setCityName:(NSString *)name
{
    [cityName release]; // JRC - was autorelease
    cityName = [name retain];
}

- (NSString *)cityName
{
    return cityName;
}


- (void)setActive:(BOOL)act
{
    isActive = act;
}

- (BOOL)isActive
{
    return isActive;
}

#pragma mark -

- (void) setRadarImage:(NSImage *)anImage
{
	if (anImage != nil)
		[anImage retain];
	if (radarImage != nil)
		[radarImage release];
	radarImage = anImage;
}

- (NSImage *) radarImage
{
	return [[radarImage retain] autorelease];
}

- (void) setUsesCustomRadarImage:(BOOL)newVal
{
	usesCustomRadarImage = newVal;
}

- (BOOL) usesCustomRadarImage;
{
	return usesCustomRadarImage;
}

- (void) setCustomRadarImageURL: (NSString *)newVal
{
	if (customRadarImageURL)
		[customRadarImageURL release];
	customRadarImageURL = [newVal copy];
}

- (NSString *) customRadarImageURL
{
	return customRadarImageURL;
}

#pragma mark Action Methods
- (void)updateWeatherReport
{
#ifdef DEBUG
	NSLog(@"%@ is updating its weather....",cityName);
#endif
	
	// must check to see if the weather is already being updated!
	// why update the weather 2x?
	[NSThread detachNewThreadSelector:@selector(threadedPrepareNewServerData:) toTarget:self withObject:nil];
	//[weather prepareNewServerData];
}

- (void)threadedPrepareNewServerData:(id)arg
{
	NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
	
	[prepareDataLock lock];	     // get lock
	[self prepareNewServerData]; //load data
	[prepareDataLock unlock];	 // release lock
	
	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"METhreadedServerDataAcquired" object:nil];
	
	[arp release]; // autorelease pool
	
	[NSThread exit]; // quit this thread
}
// Downloads (parses) the weather data for each server supported in this Weather object
- (void)prepareNewServerData
{
	MEServerTableDataSource *serversDS = serverTableData;
	NSString                *modName;
    NSString                *theCode;
	MEWeatherModule         *weatherMod;
	int i;
	
  	for (i = 0; i<[serversDS rowCount]; i++)
	{
		if([[[serversDS dataForRow:i] objectForKey:@"enabled"] boolValue])
		{
			theCode = [[serversDS dataForRow:i] objectForKey:@"code"];
			modName = [[serversDS dataForRow:i] objectForKey:@"moduleName"];
			weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
#ifdef DEBUG
			NSLog(@"  Downloading for weather module \"%@\" (code: %@)",modName,theCode);
#endif
			NSDictionary *moduleWeatherData = [weatherMod parseWeatherDataForCode:theCode];
			if (moduleWeatherData)
				[rawData setObject:moduleWeatherData forKey:modName];  // retain is unnecessary			
			break;
		}
	}
#ifdef DEBUG
	NSLog(@"%@ is FINISHED updating its weather.",cityName);
#endif
}

#pragma mark Accessing Downloaded Data

-(int)maxDaysSupported
{
	int              maxDays = 0;
	NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
    NSString        *modName;
	NSDictionary    *currentWeather;
	
	while (modName = [itr nextObject])
	{
		currentWeather = [rawData objectForKey:modName];
		if (currentWeather && [currentWeather objectForKey:@"Forecast Array"])
		{
			int numDaysInForecastArray = [[currentWeather objectForKey:@"Forecast Array"] count];
			maxDays = MAX(maxDays,numDaysInForecastArray);
		}
	}	
	return maxDays;
}

-(NSString *)localizedForecastKeyForEnglishForecastKey:(NSString *)key
{
	NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
    NSString        *modName;
	NSString        *localizedKey;
	
	while (modName = [itr nextObject])
	{
		localizedKey = [[[MEPlug_inManager defaultManager] moduleObjectNamed:modName] forecastItemNamed:key];
		if (![localizedKey isEqualToString:@"DEFAULT"])
			return localizedKey;
	}	
	return nil;
}

// Enumerates all of the weather modules for this city.  It returns the data for key
// from the first weatherModule it sees that supplies data for that key.
- (NSString *)stringForKey:(NSString *)key
{
	NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
    NSString        *modName;
	NSDictionary    *currentWeather;

    while(modName = [itr nextObject])
	{
		currentWeather = [rawData objectForKey:modName];
		if (currentWeather)
			return [currentWeather objectForKey:key];
	}
	return @"?";
}


- (NSString *)forecastStringForKey:(NSString *)key forDay:(int)dayNum
{
	NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
    NSString        *modName;
	NSDictionary    *dayWeather;
	NSArray			*forecastArray;
	
    while(modName = [itr nextObject])
	{
		forecastArray = [[rawData objectForKey:modName] objectForKey:@"Forecast Array"];
		if (forecastArray && [forecastArray count] > dayNum) {
			dayWeather = [forecastArray objectAtIndex:dayNum];
			if (dayWeather)
				return [dayWeather objectForKey:key]; // description]; ???
		}
	}
	return nil;
}

- (NSImage *)imageForKey:(NSString *)key size:(int)size imageDir:(NSString *)localImagesPath
{
    NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
	NSString        *modName;
    MEWeatherModule *weatherMod;
	NSString        *filename;
	MEWeatherItem	*value;
	
    while(modName = [itr nextObject])
    {
		if (value = [[rawData objectForKey:modName] objectForKey:key])
		{
			weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
			filename = [weatherMod filenameForIconValue:value];
			
			return [self imageForFilename:filename size:size imageDir:localImagesPath];
		}
    }

    return nil;
}

- (NSImage *)forecastImageForDay:(int)dayNumber imageDir:(NSString *)localImagesPath
{
	NSEnumerator    *itr = [[serverTableData activeModuleNames] objectEnumerator];
	NSString        *modName;
    MEWeatherModule *weatherMod;
	MEWeatherItem	*value;
	NSArray			*forecastArray;
	NSDictionary    *dayWeather;
	NSString        *filename;
	
	// search through the weather modules
    while(modName = [itr nextObject])
    {   // access the forecast data for this city
		forecastArray = [[rawData objectForKey:modName] objectForKey:@"Forecast Array"];
		weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName]; // access the weather module
		if (forecastArray && [forecastArray count] > dayNumber) // make sure that the day number is within the forecastArray
		{
			dayWeather = [forecastArray objectAtIndex:dayNumber]; // pull the specified day's weather out of the forecastArray
			if (dayWeather && (value = [dayWeather objectForKey:@"Icon"])) // determine the value of the "Icon" key
			{ // lookup the filename for this value in the weatherMod
				filename = [weatherMod filenameForIconValue:value];
				return [self imageForFilename:filename size:-1 imageDir:localImagesPath];
			}
		}
    }
	
    return nil;	
}

#pragma mark "Private" Methods

- (NSImage *)imageForFilename:(NSString *)filename size:(int)size imageDir:(NSString *)localImagesPath
{
	NSImage *icon;
	
	if (size == 128) // Dock image
	{
		localImagesPath = [localImagesPath stringByAppendingString:@"Dock Icons/Weather Status/"];
	}
	else // Menu Bar Icon will do fine
	{
		localImagesPath = [localImagesPath stringByAppendingString:@"Menu Bar Icons/"];
	}
	
	
	if (filename)
	{
		icon = [[[NSImage alloc] initWithContentsOfFile:
			[NSString stringWithFormat:@"%@%@",localImagesPath,filename]] autorelease];				
	}
	else // bad filename
	{
		icon = [[NSImage alloc] initWithContentsOfFile:
			[NSString stringWithFormat:@"%@Unknown.tiff",localImagesPath]];
	}
	
	if (icon && size > 0)
	{
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(size,size)];
	}
	
	return icon;
}

@end

#pragma mark -

@implementation NSMutableArray (DuplicationAdditions)

- (id)duplicate
{
    return [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:self]];
}

@end
