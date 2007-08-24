//
//  MEWeather.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MEWeather.h"
#import "MEPlug-inManager.h"
//#import <Cocoa/Cocoa.h>

#define MAX_NUM_MODULES 3

@implementation MEWeather

- (id)init
{
	self = [super init];
	if (self)
	{
		weatherModuleNames  = [[NSMutableArray arrayWithCapacity:MAX_NUM_MODULES] retain];
		weatherModuleCodes  = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];
		weatherModuleStates = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];
		rawData             = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];	
		prepareDataLock     = [[NSLock alloc] init];
	}
	return self;
}

+ (MEWeather *)weather
{
	return [[[MEWeather alloc] init] autorelease];
}

- (void)dealloc
{
	[weatherModuleNames release];
	[weatherModuleCodes release];
	[weatherModuleStates release];
	[rawData release];
	[prepareDataLock release];
    [super dealloc];
}

- (void)addServerNamed:(NSString *)name withCode:(NSString *)code
{
	if (![weatherModuleNames containsObject:name]) 
	{
		[weatherModuleNames addObject:name];
		[weatherModuleCodes setObject:code forKey:name];
		[weatherModuleStates setObject:[NSNumber numberWithBool:YES] forKey:name];
	}
}

#pragma mark Archiving/Unarchiving
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:weatherModuleNames forKey:@"weatherModuleNames"];
	[encoder encodeObject:weatherModuleCodes forKey:@"weatherModuleCodes"];
	[encoder encodeObject:weatherModuleStates forKey:@"weatherModuleStates"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self)
	{
		weatherModuleNames  = [[decoder decodeObjectForKey:@"weatherModuleNames"] retain];
		weatherModuleCodes  = [[decoder decodeObjectForKey:@"weatherModuleCodes"] retain];
		weatherModuleStates = [[decoder decodeObjectForKey:@"weatherModuleStates"] retain];
		rawData             = [[NSMutableDictionary dictionaryWithCapacity:MAX_NUM_MODULES] retain];	

	}
	return self;
}
#pragma mark Getting Server Data

- (void)threadedPrepareNewServerData:(id)city
{
	NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];

	[prepareDataLock lock];	     // get lock
	[self prepareNewServerDataForCity:city]; //load data
	[prepareDataLock unlock];	 // release lock

	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"METhreadedServerDataAcquired" object:nil];
	
	[arp release]; // autorelease pool
	
	[NSThread exit]; // quit this thread
}
// Downloads (parses) the weather data for each server supported in this Weather object
- (void)prepareNewServerDataForCity:(MECity *)city
{
	MEServerTableDataSource *serversDS = [city serverTableDataSource];
	NSString                *modName;
    NSString                *theCode;
	MEWeatherModule         *weatherMod;
	int i;
	
  	for (i = 0; i<[serversDS rowCount]; i++)
	{
		if([[[serversDS dataForRow:i] objectForKey:@"enabled"] boolValue])
		{
			theCode = [[serversDS dataForRow:i] objectForKey:@"code"];
			modName = [[serversDS dataForRow:i] objectForKey:@"serverName"];
			weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
#ifdef DEBUG
			NSLog(@"  Downloading for weather module \"%@\" (code: %@)",modName,theCode);
#endif
			[rawData setObject:[weatherMod parseWeatherDataForCode:theCode] forKey:modName];  // retain is unnecessary			
			break;
		}
	}
}

#pragma mark Accessor Method

- (NSArray *)activeModuleNames
{
	NSEnumerator   *itr = [weatherModuleNames objectEnumerator];
	NSMutableArray *activeModuleNames = [NSMutableArray arrayWithCapacity:[weatherModuleNames count]];
	NSString *modName;
	while (modName = [itr nextObject])
	{
		if ([[weatherModuleStates objectForKey:modName] boolValue])
		{
			[activeModuleNames addObject:modName];
		}
	}
	return [[activeModuleNames retain] autorelease];
}

- (NSArray *)inactiveModuleNames
{
	NSEnumerator   *itr = [weatherModuleNames objectEnumerator];
	NSMutableArray *inactiveModuleNames = [NSMutableArray arrayWithCapacity:[weatherModuleNames count]];
	NSString *modName;
	while (modName = [itr nextObject])
	{
		if (![[weatherModuleStates objectForKey:modName] boolValue])
		{
			[inactiveModuleNames addObject:modName];
		}
	}
	return [[inactiveModuleNames retain] autorelease];
}

- (void)activateModuleNamed:(NSString *)serverName
{
	if ( [weatherModuleStates objectForKey:serverName] != nil)
		[weatherModuleStates setObject:[NSNumber numberWithBool:YES] forKey:serverName];
}
- (void)inactivateModuleNamed:(NSString *)serverName
{
	if ( [weatherModuleStates objectForKey:serverName] != nil)
		[weatherModuleStates setObject:[NSNumber numberWithBool:NO] forKey:serverName];
}

- (NSString *)codeForModuleNamed:(NSString *)name
{
	NSString *code;
	if ( (code = [weatherModuleCodes objectForKey:name]) != nil)
		return code;
	return @"";
}
#pragma mark Accessing Downloaded Data

- (NSString *)stringForKey:(NSString *)key
{
	NSEnumerator    *itr = [weatherModuleNames objectEnumerator];
    NSString        *modName;
//	MEWeatherModule *weatherMod;
	NSDictionary    *currentWeather;
	NSString        *value;
	NSString		*convertedValue;
	
	// determine units
	NSString *units = [self labelForKey:key];
	if (!units || (units && [units isEqualToString:@"None"]))
		units = @""; // make sure it's an object
	
    while(modName = [itr nextObject])
	{
		currentWeather = [rawData objectForKey:modName];
		if((value = [currentWeather objectForKey:key]) && (convertedValue = [self processConversionForValue:value key:key]))
			//if (![convertedValue isEqualToString:value])
				return [[[NSString stringWithFormat:@"%@%@",convertedValue,units] retain] autorelease];
			//else
			//	return value;
	}
	return nil;
}


- (NSString *)forecastStringForKey:(NSString *)key forDay:(int)dayNum
{
	NSEnumerator    *itr = [weatherModuleNames objectEnumerator];
    NSString        *modName;
	NSDictionary    *dayWeather;
	NSString        *value;
	NSString		*convertedValue;
	NSArray			*forecastArray;

	// determine units
	NSString *units = [self labelForKey:key];
	if (!units || (units && [units isEqualToString:@"None"]))
		units = @""; // make sure it's an object
	
    while(modName = [itr nextObject])
	{
		forecastArray = [[rawData objectForKey:modName] objectForKey:@"Forecast Array"];
		if (forecastArray && [forecastArray count] > dayNum) {
			dayWeather = [forecastArray objectAtIndex:dayNum];
			if (dayWeather && (value = [dayWeather objectForKey:key]) && 
				(convertedValue = [self processConversionForValue:value key:key]))
				return [[[NSString stringWithFormat:@"%@%@",convertedValue,units] retain] autorelease];
		}
	}
	return nil;
}

- (NSImage *)imageForKey:(NSString *)key size:(int)size inDock:(BOOL)dock
{
    NSEnumerator    *itr = [weatherModuleNames objectEnumerator];
	NSString        *modName;
    MEWeatherModule *weatherMod;
	NSImage         *img;
	NSString		*value;
	
    while(modName = [itr nextObject])
    {
		if (value = [[rawData objectForKey:modName] objectForKey:key])
		{
			weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
			if(img = [weatherMod imageForString:value givenKey:key inDock:dock])
			{
				[img setScalesWhenResized:YES];
				[img setSize:NSMakeSize(size,size)];
				return img;
			}
		}
    }

    return nil;
}

- (NSImage *)forecastImageForKey:(NSString *)key forDay:(int)dayNum size:(int)size inDock:(BOOL)dock
{
	NSEnumerator    *itr = [weatherModuleNames objectEnumerator];
	NSString        *modName;
    MEWeatherModule *weatherMod;
	NSImage         *img;
	NSString		*value;
	NSArray			*forecastArray;
	NSDictionary    *dayWeather;
	
    while(modName = [itr nextObject])
    {
		forecastArray = [[rawData objectForKey:modName] objectForKey:@"Forecast Array"];
		weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modName];
		if (forecastArray && [forecastArray count] > dayNum)
		{
			dayWeather = [forecastArray objectAtIndex:dayNum];
			if (dayWeather && (value = [dayWeather objectForKey:key])) 
			{
				if(img = [weatherMod imageForString:value givenKey:key inDock:dock])
				{
					[img setScalesWhenResized:YES];
					[img setSize:NSMakeSize(size,size)];
					return img;
				}
			}
		}
    }

    return nil;
}

#pragma mark "Private" Methods
// returns the converted string -- assuming that we're converting from:
// english -> english, metric
- (NSString *)processConversionForValue:(NSString *)value key:(NSString *)key
{
	BOOL metric = [prefs isMetric];
	
	// no conversion
	if (!metric)
		return value;
		
	// conversion necessary.
	if([key hasPrefix:@"Visibility"] || [key hasPrefix:@"Clouds"])// || [key hasPrefix:@"Wind"])
    {
		value = [NSString stringWithFormat:@"%.1f",[value floatValue]*1.6];
	}
	else if([key hasPrefix:@"Pressure"])
    {
		value = [NSString stringWithFormat:@"%.1f",[value floatValue]*33.864];
	}
	else if ([key hasPrefix:@"Temperature"] || [key hasPrefix:@"High"] || [key hasPrefix:@"Low"] || 
			 [key hasPrefix:@"Dew Point"] || [key hasPrefix:@"Feels Like"] || [key hasPrefix:@"Wind Chill"])
	{
		value = [NSString stringWithFormat:@"%.1f",(([value floatValue]-32)*5/9)];
	}
    
	return [[value retain] autorelease];
 }

- (NSString *)labelForKey:(NSString *)key
{
	NSMutableString *label = [NSMutableString stringWithCapacity:25]; // just a guess for capacity
    BOOL             metric = [prefs isMetric];
	int              unitsIndex = metric ? 1 : 0;
	BOOL             hideDegree = [prefs hideCF];
	unichar          degreeSignUTF8 = 0xB0;
	NSString        *degreeSign = [NSString stringWithCharacters:&degreeSignUTF8 length:1];
	NSArray         *units = [MEWeather unitsForKey:key];
	
	if (units && ![[units objectAtIndex:0] isEqualToString:@"None"] )
	{
		if ([[units objectAtIndex:0] isEqualToString:@"Fahrenheit"])
		{
			[label appendString:degreeSign];
			if (!hideDegree)
			{
				NSString *ForC = [NSString stringWithFormat:@"%c",
												[[units objectAtIndex:unitsIndex] characterAtIndex:0]];
				[label appendString:ForC];
			}
		}
		else
		{
			[label appendFormat:@" %@",[units objectAtIndex:unitsIndex]];
		}
	}

	return [[label retain] autorelease];
}
+ (NSArray *)unitsForKey:(NSString *)key
{
    if([key isEqualToString:@"Weather Image"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Temperature"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Feels Like"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Dew Point"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Humidity"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Visibility"])
    {
        return [NSArray arrayWithObjects:@"Miles",
                                         @"Kilometers",
                                         nil];
    }
    else if([key isEqualToString:@"Pressure"])
    {
        return [NSArray arrayWithObjects:@"Inches",
                                         @"Millibars",
                                         @"Kilopascals",
                                         @"Hectopascals",
                                         nil];
    }
    else if([key isEqualToString:@"Precipitation"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Wind"])
    {
		return [NSArray arrayWithObject:@"None"];
       // return [NSArray arrayWithObjects:@"Miles/Hour",
       //                                  @"Kilometers/Hour",
       //                                  nil];
    }
    else if([key isEqualToString:@"UV Index"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Last Update"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"High"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Wind Chill"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast - Date"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Icon"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Forecast"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast - Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast - Precipitation"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Link"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Wind"])
    {
        return [NSArray arrayWithObjects:@"Miles/Hour",
                                         @"Kilometers/Hour",
                                         nil];
    }
    else if([key isEqualToString:@"Clouds"])
    {
        return [NSArray arrayWithObjects:@"Miles",
                                         @"Kilometers",
                                         nil];
    }
    else if([key isEqualToString:@"Normal Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Record Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Normal Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Record Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else
        return [NSArray arrayWithObject:@"None"];
}

@end

/*
- (void)newForecastEnumeratorForMods:(NSArray *)mods
{
	if (forecastEnum) // JRC
		[forecastEnum release];

    NSMutableArray *arrayOfForecasts = [NSMutableArray array];
    
    NSArray *thoseMods = [self modulesForNames:mods];

    NSEnumerator *weatherEnum = [thoseMods objectEnumerator];
    MEWeatherModule *gen;
    id obj;
 
    while(gen = [weatherEnum nextObject])
    {
        if(obj = [gen objectForKey:@"Forecast Array"])
        {
            [arrayOfForecasts addObject:[NSMutableArray arrayWithArray:obj]];
        }
    }

    forecastEnum = [[MEWeatherForecastEnumerator alloc] initWithForecastArrays:arrayOfForecasts];
}

*/
/*
- (NSArray *)moduleNamesSupportingProperty:(NSString *)property
{
    NSMutableArray *array = [NSMutableArray array];

    NSEnumerator *itr = [weatherModuleNames objectEnumerator];
	NSString *modName;
	MEWeatherModule *weatherMod;
    while(modName = [itr nextObject])
	{
		weatherMod = [[MEPlug_inManager defaultManager] moduleObjectNamed:modname];
        if ([[weatherMod supportedKeys] containgsObject:property])
			[array addObject:modName];
	}

    return array;
}
*/
/*
- (id)objectForKey:(NSString *)key modules:(NSArray *)mods
{
    NSArray *thoseMods = [self modulesForNames:mods];

    NSEnumerator *weatherEnum = [thoseMods objectEnumerator];
    MEWeatherModule *gen;
    id obj;
 
    while(gen = [weatherEnum nextObject])
        if(obj = [gen objectForKey:key])
            return obj;

    return nil;
}
*/

/*- (NSString *)stringForKey:(NSString *)key modules:(NSArray *)mods
{
    if(![key hasPrefix:@"Forecast - "])
        return [self objectForKey:key modules:mods];
    else
        return [self forecastStringForKey:key newDay:([key isEqualToString:@"Forecast - Date"])];
}
*/
/*+ (NSString *)shortNameForKey:(NSString *)key
{
    if([key isEqualToString:@"Precipitation"])
        return @"Prec.";
    else if([key isEqualToString:@"Forecast"])
        return @"";
    else 
        return key;
}
*/
	
// KEEP THIS JOE! 8/04
/*    if([key hasPrefix:@"Temperature"] || 
       [key hasPrefix:@"Feels Like"] ||
       [key hasPrefix:@"Dew Point"] ||
       [key hasPrefix:@"Low"] ||
       [key hasPrefix:@"Hi"] ||
       [key hasPrefix:@"Wind Chill"] ||
       [key hasPrefix:@"Normal Low"] ||
       [key hasPrefix:@"Record Low"] ||
       [key hasPrefix:@"Normal Hi"] ||
       [key hasPrefix:@"Record Hi"])
    {
        BOOL metric;
        
        if([prefs useGlobalUnits])
            metric = [[prefs degreeUnits] isEqualToString:@"Celsius"];
        else
            metric = [units isEqualToString:@"Celsius"];
    
        if(metric)
            string = [NSString stringWithFormat:@"%d",(int)round(([string floatValue] - 32.0) * 5.0/9.0)];
            
        unichar degreeSignUTF8 = 0xB0; // could be 0xBA, too
		
		NSString *degreeSign = [NSString stringWithCharacters:&degreeSignUTF8 length:1];
        if(degrees)
        {
            if(metric)
                string = [NSString stringWithFormat:@"%@%@C",string,degreeSign];
            else
                string = [NSString stringWithFormat:@"%@%@F",string,degreeSign];
        }
        else
        {
            if(metric)
                string = [NSString stringWithFormat:@"%@%@",string,degreeSign];
            else
                string = [NSString stringWithFormat:@"%@%@",string,degreeSign];
        }
    }
    
    if([key hasPrefix:@"Visibility"] || [key hasPrefix:@"Clouds"])
    {
        
        if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Kilometers"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilometers"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mile"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1.6]];
                    [tokens replaceObjectAtIndex:i withObject:@"km"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Meters"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Meters"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mile"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1600]];
                    [tokens replaceObjectAtIndex:i withObject:@"m"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Feet"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Feet"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mile"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*5280]];
                    [tokens replaceObjectAtIndex:i withObject:@"ft"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
    }
    
    if([key hasPrefix:@"Pressure"])
    {
        if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Millibars"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Millibars"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"inch"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*33.864]];
                    if([[tokens objectAtIndex:i] hasSuffix:@"s"])
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"millibars",@"")];
                    else
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"millibar",@"")];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Kilopascals"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilopascals"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"inch"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*3.3864]];
                    if([[tokens objectAtIndex:i] hasSuffix:@"s"])
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"kPa",@"")];
                    else
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"kPa",@"")];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Hectopascals"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Hectopascals"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"inch"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*33.3864]];
                    if([[tokens objectAtIndex:i] hasSuffix:@"s"])
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"hPa",@"")];
                    else
                        [tokens replaceObjectAtIndex:i withObject:NSLocalizedString(@"hPa",@"")];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
    }
    
    if([key hasPrefix:@"Wind"])
    {
        if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Kilometers/Hour"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilometers/Hour"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1.6]];
                    [tokens replaceObjectAtIndex:i withObject:@"km/h"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Meters/Second"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Meters/Second"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1600/3600]];
                    [tokens replaceObjectAtIndex:i withObject:@"m/s"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Knots"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Knots"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*0.868976]];
                    [tokens replaceObjectAtIndex:i withObject:@"knots"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
    }
    
    return string;

}
*/


/*- (NSString *)forecastStringForKey:(NSString *)key units:(NSString *)units prefs:(MEPrefs *)prefs displayingDegrees:(BOOL)degrees modules:(NSArray *)mods
{
   return [self stringForKey:key units:units prefs:prefs displayingDegrees:degrees modules:mods];
}
*/

/*
@implementation MEWeatherForecastEnumerator

- (id)initWithForecastArrays:(NSMutableArray *)arrays
{
    self = [super init];
    if(self)
    {
        forecastArrays = [arrays retain];
        isFirst = YES;
        [self nextDay:NO];
    }
    return self;
}

- (void)dealloc
{
    [forecastArrays release]; // JRC - was autorelease 
    [super dealloc];
}

- (int)compareDay:(NSString *)day withDay:(NSString *)other
{
    if(!other)
	return NSOrderedAscending;
        
    if([day isEqualToString:other])
        return NSOrderedSame;
        
    //Priority:
    // 1 - Now/Today
    // 2 - Afternoon
    // 3 - Tonight/Overnight
    // 4 - Tomorrow
    // 5 - X (Monday, Tueday, Wednesday, ...)
    // 6 - X Night (Monday Night, Tuesday Night, ...)
    
    int dayScore = -1;
    int otherScore = -1;
    
    if([day isEqualToString:@"Now"] || [day isEqualToString:@"Today"])
        dayScore = 1;
    else if([day hasSuffix:@"fternoon"])
        dayScore = 2;
    else if([day isEqualToString:@"Tonight"] || [day isEqualToString:@"Overnight"])
        dayScore = 3;
    else if([day isEqualToString:@"Tomorrow"])
        dayScore = 4;
        
    if([other isEqualToString:@"Now"] || [other isEqualToString:@"Today"])
        otherScore = 1;
    else if([other hasSuffix:@"fternoon"])
        otherScore = 2;
    else if([other isEqualToString:@"Tonight"] || [other isEqualToString:@"Overnight"])
        otherScore = 3;
    else if([other isEqualToString:@"Tomorrow"])
        otherScore = 4;
        
    if(dayScore == -1 && otherScore == -1)
    {
        float dayPoints = -1;
        float otherPoints = -1;
        
        if([day hasPrefix:@"Monday"])
            dayPoints = 1;
        else if([day hasPrefix:@"Tuesday"])
            dayPoints = 2;
        else if([day hasPrefix:@"Wednesday"])
            dayPoints = 3;
        else if([day hasPrefix:@"Thursday"])
            dayPoints = 4;
        else if([day hasPrefix:@"Friday"])
            dayPoints = 5;
        else if([day hasPrefix:@"Saturday"])
            dayPoints = 6;
        else if([day hasPrefix:@"Sunday"])
            dayPoints = 7;
        if([day hasSuffix:@"ight"])
            dayPoints += 0.5;
            
        if([other hasPrefix:@"Monday"])
            otherPoints = 1;
        else if([other hasPrefix:@"Tuesday"])
            otherPoints = 2;
        else if([other hasPrefix:@"Wednesday"])
            otherPoints = 3;
        else if([other hasPrefix:@"Thursday"])
            otherPoints = 4;
        else if([other hasPrefix:@"Friday"])
            otherPoints = 5;
        else if([other hasPrefix:@"Saturday"])
            otherPoints = 6;
        else if([other hasPrefix:@"Sunday"])
            otherPoints = 7;
        if([other hasSuffix:@"ight"])
            otherPoints += 0.5;
            
        if(otherPoints >= 6 && dayPoints <= 2)
            return NSOrderedDescending;
        else if(dayPoints >= 6 && otherPoints <= 2)
            return NSOrderedAscending;
        else
        {
            if(otherPoints < dayPoints)
                return NSOrderedDescending;
            else if(dayPoints < otherPoints)
                return NSOrderedAscending;
            else
                return NSOrderedSame;
        }
    }
    else if(dayScore == -1)
        return NSOrderedDescending;    
    else if(otherScore == -1)
        return NSOrderedAscending;
    else
    {
        if(otherScore < dayScore)
            return NSOrderedDescending;
        else if(otherScore > dayScore)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }
    
        
    //Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    //Monday Night, Tuesday Night, Wednesday Night, Thursday Night, Friday Night, Saturday Night, Sunday Night
    //Afternoon, Tonight, Now, Today, Tomorrow
}

- (void)stripFirstLevel
{
    NSEnumerator *arrayEnum = [forecastArrays objectEnumerator];
    NSMutableArray *nextArray;
    
    while(nextArray = [arrayEnum nextObject])
    {
        if([nextArray count])
            [nextArray removeObjectAtIndex:0];
    }
}

- (void)nextDay:(BOOL)strip
{
    if(strip && !isFirst)
        [self stripFirstLevel];
        
    if(strip)
        isFirst = NO;

    //check all the first days and find which one comes first.
    //any one that comes later should have an NSNull placed at the front
    
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    NSMutableArray *nextArray;
    
    NSString *firstDate = nil;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id dict = [nextArray objectAtIndex:0];
            if(dict != [NSNull null])
            {
                int res = [self compareDay:[dict objectForKey:@"Forecast - Date"] withDay:firstDate];
                
                if(res == NSOrderedAscending)
                    firstDate = [dict objectForKey:@"Forecast - Date"];
            }
        }
    }
    
    forecastEnum = [forecastArrays objectEnumerator];
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id dict = [nextArray objectAtIndex:0];
            if(dict != [NSNull null])
            {
                int res = [self compareDay:[dict objectForKey:@"Forecast - Date"] withDay:firstDate];
                
                if(res == NSOrderedDescending)
                    [nextArray insertObject:[NSNull null] atIndex:0];
            }
        }
    }
}

- (void)nextDay
{
    [self nextDay:YES];
}

- (id)objectForKey:(NSString *)key
{
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    id nextArray;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id obj = [nextArray objectAtIndex:0];
            if(obj != [NSNull null])
            {
                id val = [obj objectForKey:key];
                if(val)
                    return val;
            }
        }
    }

    return nil;
}

- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)inDock
{
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    id nextArray;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id obj = [nextArray objectAtIndex:0];
            
            if(obj != [NSNull null])
            {
                id val = [obj objectForKey:key];
                MEWeatherModule *mod = [obj objectForKey:@"Weather Module"];
                
                if(val)
                {
                    id img = [mod imageForString:val givenKey:key inDock:inDock];
                    if(img)
                        return img;
                }
            }
        }
    }
    
    return nil;
}

@end
*/
