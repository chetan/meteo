//
//  MEWeatherModule.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
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
//
//	03 Sep 2003	Rich Martin	changed some initWithContentsOfURL: messages to stringFromWebsite:spacesOnly:
//	12 Sep 2003	Rich Martin	added code for Heat Index data in wunderground.com's loadWeatherData
//	16 Sep 2003	Rich Martin	assert leading slash in 'code' for wunderground.com's weatherQueryURL
//

#import "MEWeatherModule.h"
#import "MEWeatherModuleParser.h"
#import "MEWebUtils.h" // MEWebFetcher

@implementation MEWeatherModule

- (id)initWithBundlePath:(NSString *)bundlePath
{
	self = [super init];
	
	return self;
}

+ (MEWeatherModule *)weatherModuleWithBundlePath:(NSString *)bundlePath
{
	return [[[self alloc] initWithBundlePath:bundlePath] autorelease];
}


+ (MEWeatherModule *)weatherModule
{
	return [[[self alloc] init] autorelease];
}


- (void)dealloc
{
	[moduleDict release];
    [super dealloc];
}


-(NSString *)sourceName
{
	if (moduleDict)
		return [moduleDict objectForKey:@"MEWeatherModuleName"];
	else
		return [NSString stringWithString:@"Generic"];
}

- (NSString *) searchURL
{
	return @"";
}

- (NSArray *)performCitySearchOnPageContents:(NSString *)pageContents pageURL:(NSString *)pageURL
{
	return nil;
}


- (NSArray *)supportedCurrentConditionItems
{
	return [NSArray array];
}

- (NSArray *)supportedForecastItems
{
	return [NSArray array];
}

- (NSString *)currentConditionItemNamed:(NSString *)name
{
	return @"";
}

- (NSString *)forecastItemNamed:(NSString *)name
{
	return @"";
}

- (NSString *)filenameForIconValue:(MEWeatherItem *)weatherItem
{
	return @"";
}


- (NSDictionary *)parseWeatherDataForCode:(NSString *)code
{
    return nil;
}

// Overloaded by child classes
- (NSArray *)performCitySearch:(NSString *)searchTerm
{
    return nil;
}

// JRC -I might want to rewrite these methods
/*- (id)objectForKey:(NSString *)key
{
    return [[[weatherData objectForKey:key] retain] autorelease]; // was copy];
}

- (NSString *)stringForKey:(NSString *)key
{

    return [[[weatherData objectForKey:key] retain] autorelease]; // was copy];
}

- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)dock
{
    return [self imageForString:[self stringForKey:key] givenKey:key inDock:dock];
}
*/

// Overloaded by child classes
- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    return nil;
}

+ (NSImage *)imageForFileName:(NSString *)name forDock:(BOOL)inDock
{
    NSString *primary = @"/Library/Application Support/Meteo/";
    NSString *secondary = [@"~/Library/Application Support/Meteo/" stringByExpandingTildeInPath];
    
    NSString *base = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:primary])
        base = primary;
    else
        base = secondary;

    if(!inDock)
        return [[[NSImage alloc] initWithContentsOfFile:
					[NSString stringWithFormat:@"%@Menu Bar Icons/%@",base,name]] autorelease];
    else
        return [[[NSImage alloc] initWithContentsOfFile:
					[NSString stringWithFormat:@"%@Dock Icons/Weather Status/%@",base,name]] autorelease];
}

@end

/*
@implementation MENWSCom

+ (NSString *)sourceName
{
    return @"National Weather Service";
}

+ (NSArray *)supportedKeys
{
    return [NSArray arrayWithObjects:@"Weather Image",
                                     @"Weather Link",
                                     @"Temperature",
                                     @"Forecast",
                                     @"Humidity",
                                     @"Wind",
                                     @"Pressure",
                                     @"Dew Point",
                                     @"Visibility",
                                     @"Last Update",
                                     @"Forecast - Date",
                                     @"Forecast - Forecast",
                                     @"Forecast - Hi",
                                     @"Forecast - Low",
                                     @"Wind Chill",
                                     @"Precipitation",
                                     @"Forecast - Icon",
                                     @"Forecast - Wind",
                                     @"Forecast - Precipitation",
                                     @"Hi",
                                     @"Low",
                                     @"Radar Image",
                                     @"Weather Alert",
                                     nil];
}

+ (NSArray *)supportedInfos
{
    return [NSArray arrayWithObject:@"United States"];
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
            [[[NSImage alloc] initWithContentsOfFile:[@"~/Library/Application Support/Meteo/Weather Status/Moon.tiff" stringByExpandingTildeInPath]]  autorelease];
        
        if(img)
            return img;
    }
    
    if([name hasSuffix:@"nfew"] || [name isEqualToString:@"hi_nclr"] || [name isEqualToString:@"hi_nmoclr"] || 
       [name hasSuffix:@"nskc"] || [name isEqualToString:@"sunnyn"])
        imageName = @"Moon.tiff";
    else if([name hasPrefix:@"nsct"] || [name isEqualToString:@"hi_nptcldy"] || [name isEqualToString:@"nhiclouds"] || 
            [name isEqualToString:@"pcloudyn"])
        imageName = @"Moon-Cloud-1.tiff";
    else if([name hasSuffix:@"nbkn"] || [name isEqualToString:@"hi_nmocldy"] || [name hasSuffix:@"mcloudyn"] || [name isEqualToString:@"tcu"])
        imageName = @"Moon-Cloud-2.tiff";
    else if([name hasSuffix:@"few"] || [name isEqualToString:@"br"] || [name isEqualToString:@"fair"] || 
            [name isEqualToString:@"hi_clr"] || [name hasSuffix:@"skc"] || [name hasPrefix:@"hot"] || 
            [name isEqualToString:@"sunny"])
        imageName = @"Sun.tiff";
    else if([name hasSuffix:@"sct"] || [name isEqualToString:@"hi_moclr"] || [name isEqualToString:@"hi_ptcldy"] || 
            [name isEqualToString:@"pcloudy"])
        imageName = @"Sun-Cloud-1.tiff";
    else if([name hasSuffix:@"bkn"] || [name isEqualToString:@"hi_mocldy"] || [name isEqualToString:@"mcloudy"])
        imageName = @"Sun-Cloud-2.tiff";
    else if([name hasSuffix:@"ovc"] || [name hasPrefix:@"cloudy"] || [name isEqualToString:@"fu"] || 
            [name isEqualToString:@"hiclouds"])
        imageName = @"Cloudy.tiff";
    else if([name hasPrefix:@"fog"] || [name hasPrefix:@"du"] || [name hasSuffix:@"fg"] ||
            [name isEqualToString:@"mist"] || [name isEqualToString:@"smoke"])
        imageName = @"Hazy.tiff";
    else if([name hasPrefix:@"ra"] || [name hasSuffix:@"drizzle"] || [name isEqualToString:@"freezingrain"] || 
            [name hasPrefix:@"fz"] || [name hasSuffix:@"shwrs"] || [name hasPrefix:@"nra"] || 
            [name isEqualToString:@"showers"] || [name hasPrefix:@"shra"] || [name isEqualToString:@"sleet"])
        imageName = @"Rain.tiff";
    else if([name isEqualToString:@"none"] || [name isEqualToString:@"na"])
        imageName = @"Unknow.tiff";
    else if([name hasSuffix:@"tsra"] || [name hasPrefix:@"ntsra"] || [name hasPrefix:@"tstorm"])
        imageName = @"Thunderstorm.tiff";
    else if([name isEqualToString:@"flurries"])
        imageName = @"Flurries.tiff";
    else if([name hasSuffix:@"sn"] || [name isEqualToString:@"blizzard"] || [name isEqualToString:@"blowingsnow"] ||
            [name hasSuffix:@"mix"] || [name hasPrefix:@"snow"])
        imageName = @"Snow.tiff";
    else if([name hasPrefix:@"cold"] || [name hasSuffix:@"wind"] || [name hasPrefix:@"wind"])
        imageName = @"Wind.tiff";
    else if([name isEqualToString:@"nsvrtsra"] || [name isEqualToString:@"hurr"] || [name hasSuffix:@"tor"] || 
            [name isEqualToString:@"wswatch"] || [name isEqualToString:@"wswarning"])
        imageName = @"Alert.tiff";
    else
        imageName = @"Unknown.tiff";
    
    if(string && !(img = imageForName(imageName,dock)))
    {
        if(dock)
            return nil;
    
        //NSLog(@"%@ : %@",name,imageName);
    
	NSData *dat = [[NSURL URLWithString:string] resourceDataUsingCache:YES];
        if(dat)
            img = [[[NSImage alloc] initWithData:dat] autorelease];
    }
    
    return img;
}


- (BOOL)loadWeatherData
{
#define NUM_NWS_FORECAST_ITEMS	8
    if(![super loadWeatherData])
    {
        [weatherData autorelease];
        weatherData = nil;
        return NO;
    }
    NSURL *url;
    //NSData *data;
    NSString *string;
    NSRange lastRange;
    int stringLength;
    NSString *temp;
    NSCalendarDate *d = [NSCalendarDate calendarDate];
    
    Class class = [self class];
    
    [super loadWeatherData];

	NSString *weatherQueryURL = [NSString stringWithFormat:@"http://www.crh.noaa.gov/forecasts/%@",code];
    //url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.crh.noaa.gov/data/forecasts/%@",code]];
    url = [NSURL URLWithString:weatherQueryURL];

    string = [[[NSString alloc] initWithContentsOfURL:url] autorelease];
    
    if(!string)
        return NO;
        
    stringLength = [string length];
    
    if(!stringLength)
        return NO;

    lastRange = NSMakeRange(0,stringLength);
    NSMutableDictionary *lastWeather = weatherData;
    weatherData = [[NSMutableDictionary alloc] initWithCapacity:0];
    [weatherData setObject:@"Today" forKey:@"Date"];
    
    [weatherData setObject:[url absoluteString] forKey:@"Weather Link"];

    //begin getting forecast forecast and forecast image
    int i;
    
    temp = [class getStringWithLeftBound:@"<tr valign=\"top\" align=\"center\">"
                  rightBound:@"<tr valign=\"top\" align=\"center\">"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
    
    NSMutableArray *forecastArray = [NSMutableArray array];
    NSMutableDictionary *forecastDict;
    
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        forecastDict = [NSMutableDictionary dictionary];
    
        temp = [class getStringWithLeftBound:@"<img src=\""
                      rightBound:@"\" alt"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            [forecastDict setObject:temp forKey:@"Forecast - Icon"];
            
            if(![weatherData objectForKey:@"Weather Image"])
                [weatherData setObject:temp forKey:@"Weather Image"];
        }
        
    
        temp = [class getStringWithLeftBound:@"<br>"
                      rightBound:@"</td>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            temp = [class replaceString:@"<BR>" withString:@" " forString:temp];

            if(temp)
            {
                [forecastDict setObject:temp forKey:@"Forecast - Forecast"];
            }
        }
        
        [forecastArray addObject:forecastDict];
    }
    //end getting forecast forecast
    [weatherData setObject:forecastArray forKey:@"Forecast Array"];
    
    
    //begin getting the hi/low forecast
    NSEnumerator *forecastEnumerator = [forecastArray objectEnumerator];
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        temp = [class getStringWithLeftBound:@"<td>"
                  rightBound:@"<"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            NSString *daKey = nil;
        
            if([temp hasPrefix:@"Hi"])
                daKey = @"Hi";
            else if([temp hasPrefix:@"Lo"])
                daKey = @"Low";
        
            if(daKey)
            {
                temp = [class getStringWithLeftBound:@">"
                    rightBound:@"&"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
    
                if(temp && lastRange.location)
                {
                    forecastDict = [forecastEnumerator nextObject];
                    [forecastDict setObject:temp forKey:[NSString stringWithFormat:@"Forecast - %@",daKey]];
                }
            }
        }
    }
    //end getting hi/low forecast

    
    temp = [class getStringWithLeftBound:@"</a>Hazardous weather condition(s):"
                  rightBound:@"<span class=\"warn\">"//@" <font " _RAM
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
                  
    if(temp)
    {
        NSRange tempRange = NSMakeRange(0,[temp length]);
        
        NSString *alertStr = [class getStringWithLeftBound:@"><a href=\""
                                    rightBound:@"\">"
                                    string:temp
                                    length:tempRange.length
                                    lastRange:&tempRange];
                                    
        if(alertStr)
        {
            
            NSString *loadedAlertString = [[[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:alertStr]] autorelease];
            
            //NSString *loadedAlertString = [[[NSString alloc] initWithData:[[NSURL URLWithString:alertStr] resourceDataUsingCache:NO] encoding:NSASCIIStringEncoding] autorelease];
            
            if(loadedAlertString)
            {
                alertStr = loadedAlertString;
                int alertStrLength = [alertStr length];
                tempRange = NSMakeRange(0,alertStrLength);
                NSMutableArray *alertArray = [NSMutableArray array];
                
                while(1)
                {
                    NSString *subStr = [class getStringWithLeftBound:@"<pre>"
                                            rightBound:@"$$"
                                            string:alertStr
                                            length:alertStrLength
                                            lastRange:&tempRange];
                                            
                    if(!subStr)
                        break;
                        
                    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t\f\v"];
                    subStr = [subStr stringByTrimmingCharactersInSet:set];
                    
                    subStr = [NSString stringWithFormat:@"(NWS): %@",subStr];
                    
                    if(subStr)
                    {
                        NSMutableDictionary *diction = [NSMutableDictionary dictionary];
                        [diction setObject:@"Weather Alert" forKey:@"title"];
                        [diction setObject:subStr forKey:@"description"];
                        [alertArray addObject:diction];
                    }
                }
                
                if([alertArray count])
                    [weatherData setObject:alertArray forKey:@"Weather Alert"];
            }
        
        }
    }
    
    //moving down the file
    temp = [class getStringWithLeftBound:@"Detailed Forecast"	// this won't be found _RAM
                  rightBound:@"br>"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
                  
    i = 0;
    
    forecastEnumerator = [forecastArray objectEnumerator];
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        NSString *date;
                      
        date = [class getStringWithLeftBound:@"<b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
                                                                          
        if(!date)
            break;
            
        if(i==0 && [date hasSuffix:@"ight"])
            i++;
            
        forecastDict = [forecastEnumerator nextObject];
        [forecastDict setObject:date forKey:@"Forecast - Date"];
        [forecastDict setObject:self forKey:@"Weather Module"];
        
        temp = [class getStringWithLeftBound:@" "
                      rightBound:@"<br>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
        
        temp = [class replaceString:@"\n" withString:@" " forString:temp];
        NSArray *components = [temp componentsSeparatedByString:@". "];
        NSEnumerator *compEnum = [components objectEnumerator];
        NSString *comp;
        
        comp = [compEnum nextObject];
        if(comp)
            [forecastDict setObject:comp forKey:@"Forecast - Forecast"];
        
        while(comp = [compEnum nextObject])
        {
            comp = [class stripSuffix:@"." forString:comp];
            NSArray *words = [comp componentsSeparatedByString:@" "];
            
            //now what?
            
            //precipitation is now by "percent"
            //hi temp is know by "highs" or "Highs"
            //low temp is known by "lows" or "Lows"
            //	hi and low can be combined in same line
            //wind is known by "winds"
            
            int index;
            char percent = '%';
            
            if((index = [words indexOfObject:@"percent"]) != NSNotFound && index > 0)
            {
                NSString *part = [words objectAtIndex:index-1];
               
                if(![part length])
                    part = [words objectAtIndex:index-2];
            
                NSString *percip = [NSString stringWithFormat:@"%@ %c", part, percent];
            
                [forecastDict setObject:percip forKey:@"Forecast - Precipitation"];
            }
            else if((index = [words indexOfObject:@"winds"]) != NSNotFound)
            {
                if((index = [words indexOfObject:@"to"]) != NSNotFound)
                {
                    NSMutableArray *compArray = [NSMutableArray arrayWithArray:words];
                    [compArray insertObject:@"mph" atIndex:index];
                    comp = [compArray componentsJoinedByString:@" "];
                }
            
                [forecastDict setObject:comp forKey:@"Forecast - Wind"];
            }
            else
            {
                words = [comp componentsSeparatedByString:@" and "];
                NSEnumerator *yaEnum = [words objectEnumerator];
                NSString *moreComps;
                
                while(moreComps = [yaEnum nextObject])
                {
                    words = [moreComps componentsSeparatedByString:@" "];
                    
                    if([words indexOfObject:@"highs"]!=NSNotFound || [words indexOfObject:@"Highs"]!=NSNotFound)
                    {
                        if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound ||

 (index = [words indexOfObject:@"middle"]) != NSNotFound)
                        {
                            if(index+1 < [words count])
                            {
                                NSString *candidate = [words objectAtIndex:index+1];
                                
                                // 30s, 20s, teens...
                                
                                candidate = [class stripSuffix:@"s" forString:candidate];
                                if([candidate isEqualToString:@"teen"])
                                    candidate = @"10";
                                    
                                if([candidate hasSuffix:@"0"])
                                {
                                    candidate = [class stripSuffix:@"0" forString:candidate];
                                        
                                    NSString *phrase = [words objectAtIndex:index];
                                    if([phrase hasPrefix:@"mid"])
                                        candidate = [NSString stringWithFormat:@"%@5",candidate];
                                    else if([phrase isEqualToString:@"near"])
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                    else if([phrase isEqualToString:@"upper"])
                                        candidate = [NSString stringWithFormat:@"%@8",candidate];
                                    else if([phrase isEqualToString:@"lower"])
                                        candidate = [NSString stringWithFormat:@"%@2",candidate];
                                    else
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                }
                            
                                if(candidate)
                                {
                                    if(![forecastDict objectForKey:@"Forecast - Hi"])
                                        [forecastDict setObject:candidate
                                                      forKey:@"Forecast - Hi"];
                                }
                            }
                        }
                                
                    }
                    else if([words indexOfObject:@"lows"]!=NSNotFound || [words indexOfObject:@"Lows"]!=NSNotFound)
                    {
                        if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound ||

 (index = [words indexOfObject:@"middle"]) != NSNotFound)
                        {
                            if(index+1 < [words count])
                            {
                                NSString *candidate = [words objectAtIndex:index+1];
                                
                                // 30s, 20s, teens...
                                
                                candidate = [class stripSuffix:@"s" forString:candidate];
                                if([candidate isEqualToString:@"teen"])
                                    candidate = @"10";
                                    
                                if([candidate hasSuffix:@"0"])
                                {
                                    candidate = [class stripSuffix:@"0" forString:candidate];
                                        
                                    NSString *phrase = [words objectAtIndex:index];
                                    if([phrase hasPrefix:@"mid"])
                                        candidate = [NSString stringWithFormat:@"%@5",candidate];
                                    else if([phrase isEqualToString:@"near"])
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                    else if([phrase isEqualToString:@"upper"])
                                        candidate = [NSString stringWithFormat:@"%@8",candidate];
                                    else if([phrase isEqualToString:@"lower"])
                                        candidate = [NSString stringWithFormat:@"%@2",candidate];
                                    else
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                }
                                    
                                if(candidate)
                                {
                                    if(![forecastDict objectForKey:@"Forecast - Low"])
                                        [forecastDict setObject:candidate
                                                      forKey:@"Forecast - Low"];
                                }
                            }
                        }
                                
                    }
                }
            }
        }
    }
    
    //get the current forecast
    temp = [class getStringWithLeftBound:@"<td class=\"big\" width=\"120\" align=\"center\">"
                  rightBound:@"<br><"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
    if(temp && ![temp hasPrefix:@"NA"])
        [weatherData setObject:temp forKey:@"Forecast"];
    //end getting current forecast
    
    
     //get the current temperature
    temp = [class getStringWithLeftBound:@">"
                  rightBound:@"&"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];                            
    if(temp && ![temp hasPrefix:@"NA"])
        [weatherData setObject:temp forKey:@"Temperature"];
    //end getting current temp

    
    temp = [class getStringWithLeftBound:@"<td><b>"
                  rightBound:@"</b>"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
    
    //get the current humidity
    if([temp isEqualToString:@"Humidity"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@"</td>"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Humidity"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current humidity
    
    //get the current wind
    if([temp isEqualToString:@"Wind Speed"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@" MPH"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:[NSString stringWithFormat:@"%@ mph",temp] forKey:@"Wind"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current wind
    
    //get the current pressure
    if([temp isEqualToString:@"Barometer"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@"</td>"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            temp = [class stripWhiteSpaceAtBeginningAndEnd:temp];
        
            if([temp hasPrefix:@"nowrap>"])
                temp = [temp substringFromIndex:7];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
                
            if([temp hasSuffix:@")"])
                temp = [NSString stringWithFormat:@"%@ inches",[[temp componentsSeparatedByString:@"&"] objectAtIndex:0]];
                
            if([temp hasSuffix:@"&quot;"])
                temp = [class stripSuffix:@"&quot;" forString:temp];
                
            [weatherData setObject:temp forKey:@"Pressure"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current pressure

    
    //get the current dew point
    if([temp isEqualToString:@"Dewpoint"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@"&"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if ([temp hasPrefix:@"nowrap>"])
                temp = [temp substringFromIndex:8];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Dew Point"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current dew point
    
    //get the current wind chill
    if([temp isEqualToString:@"Windchill"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@"&"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Wind Chill"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current wind chill
    
    //get the current visibility
    if([temp isEqualToString:@"Visibility"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
                    rightBound:@" mi"
                    string:string
                    length:stringLength
                    lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:[NSString stringWithFormat:@"%@ miles",temp] forKey:@"Visibility"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
                      rightBound:@"</b>"
                      string:string
                      length:stringLength
                      lastRange:&lastRange];
    }
    //end getting current visibility
    
    
    //get the radar image
    temp = [class getStringWithLeftBound:@"http://www.crh.noaa.gov/radar/latest/"
                  rightBound:@"/si.klot.shtml"
                  string:string
                  length:stringLength
                  lastRange:&lastRange];
                  
    if(temp)
        [weatherData setObject:[NSString stringWithFormat:@"http://www.crh.noaa.gov/radar/images/%@/SI.klot/latest.gif",temp] forKey:@"Radar Image"];
    
    d = [NSCalendarDate calendarDate];
    //[weatherData setObject:[d descriptionWithCalendarFormat:@"%a, %b %d %I:%M %p"] forKey:@"Last Load"];
    [weatherData setObject:[class dateInfoForCalendarDate:d]  forKey:@"Last Update"];
    
    if([weatherData count] > 5)
    {
        supplyingOldData = NO;
        [lastWeather autorelease];
    }
    else
    {
        supplyingOldData = YES;
		if (lastWeather != nil) {
			[weatherData autorelease];
			weatherData = lastWeather;
		}	// No previous weather data? We'll use what little we have. _RAM
    }
    
    return YES;
}

+ (NSArray *)perfromCitySearch:(NSString *)search info:(NSString *)information
{
    NSURL *url;
    //NSData *data;
    
    NSRange lastRange;
    NSString *string;
    int stringLength;
    NSString *temp;
    NSMutableArray *array = [NSMutableArray array];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    search = [self replaceString:@" " withString:@"%20" forString:search];
    
    url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.srh.noaa.gov/zipcity.php?inputstring=%@",search]];

    string = [[[NSString alloc] initWithContentsOfURL:url] autorelease];
    
    if(!string)
        return nil;
        
    stringLength = [string length];
    
    if(!stringLength)
        return nil;
    
    lastRange = NSMakeRange(1,stringLength-1);
    
    // Let's see if this resolved right away
    temp = [self getStringWithLeftBound:@"More than one"
                 rightBound:@"matched your submission"
                 string:string
                 length:stringLength
                 lastRange:&lastRange];
     
    
    //then we resolved right away
    if(!temp || !(lastRange.location))
    {
    
        lastRange = NSMakeRange(1,stringLength-1);
        
        //get the loc
        temp = [self getStringWithLeftBound:@"class=\"white1\">"
                     rightBound:@"<a href"
                     string:string
                     length:stringLength
                     lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            [dict setObject:temp forKey:@"city"];
            
            temp = [self getStringWithLeftBound:@"warnzone="
                         rightBound:@"&"
                         string:string
                         length:stringLength
                         lastRange:&lastRange];
            
            if(temp && lastRange.location)
            {
                NSString *TEMP = nil;
                    
                TEMP = [self getStringWithLeftBound:@"cal_place="
                             rightBound:@"&"
                             string:string
                             length:stringLength
                             lastRange:&lastRange];
                
                if([TEMP hasPrefix:@"1="])
                    TEMP = [TEMP substringFromIndex:2];
                                
                if(TEMP && lastRange.location)
                {
                    [dict setObject:[NSString stringWithFormat:@"%@-%@",temp,TEMP] forKey:@"code"];
                
                    if(information)
                        [dict setObject:information forKey:@"info"];
                
                    [array addObject:dict];
                    return array;
                }

            }
        }
        
        return [NSArray array];
    }

    // Moving down down down...
    temp = [self getStringWithLeftBound:@"<table cellspacing=\"2\" cellpadding=\"20\" border=\"0\">"
                 rightBound:@"<td>"
                 string:string
                 length:stringLength
                 lastRange:&lastRange];
    
    while(lastRange.location)
    {
        dict = [NSMutableDictionary dictionary];
    
        temp = [self getStringWithLeftBound:@"orecasts/"
                     rightBound:@".php"
                     string:string
                     length:stringLength
                     lastRange:&lastRange];
        if(!temp)
            break;
    
        NSString *TEMP = nil;
        TEMP = [self getStringWithLeftBound:@"ity="
                     rightBound:@">"
                     string:string
                     length:stringLength
                     lastRange:&lastRange];
            
        if(TEMP)
            [dict setObject:[NSString stringWithFormat:@"%@-%@",temp,TEMP] forKey:@"code"];
        else
            break;
            
        lastRange.location--;
        temp = [self getStringWithLeftBound:@">"
                     rightBound:@"</a>"
                     string:string
                     length:stringLength
                     lastRange:&lastRange];
        if(temp)
            [dict setObject:temp forKey:@"city"];
        else
            break;
            
        if(information)
            [dict setObject:information forKey:@"info"];
            
        [array addObject:dict];
    }
    
    return array;
}

@end */
