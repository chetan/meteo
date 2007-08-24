//
//  MECity.h
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


#import <Foundation/Foundation.h>
#import "MEServerTableDataSource.h"

@interface MECity : NSObject 
{
    NSString                *cityName; // user defined city name    
	MEServerTableDataSource *serverTableData; // replacement for cityAndInfoCodes
    BOOL                     isActive;
	NSString                *customRadarImageURL;
	BOOL                     usesCustomRadarImage;

	NSImage                 *radarImage; // cached representation of the radar image
	
	// formerly of MEWeather.h
	NSLock *prepareDataLock;
	NSMutableDictionary *rawData;
}

- (id)initWithCityName:(NSString *) name;
+ (MECity *) defaultCity;

- (MEServerTableDataSource *) serverTableDataSource;
- (void) setCityName:(NSString *) name;
- (NSString *) cityName;
- (void) setActive:(BOOL)act;
- (BOOL) isActive;

- (void) setRadarImage:(NSImage *)anImage;
- (NSImage *) radarImage;
- (void) setUsesCustomRadarImage:(BOOL)newVal;
- (BOOL) usesCustomRadarImage;
- (void) setCustomRadarImageURL: (NSString *)newVal;
- (NSString *) customRadarImageURL;

- (void)updateWeatherReport;
- (void)threadedPrepareNewServerData:(id)arg;
- (void)prepareNewServerData;

-(int)maxDaysSupported;
-(NSString *)localizedForecastKeyForEnglishForecastKey:(NSString *)key;


- (NSString *)stringForKey:(NSString *)key;
- (NSString *)forecastStringForKey:(NSString *)key forDay:(int)dayNum;

- (NSImage *)imageForKey:(NSString *)key size:(int)size imageDir:(NSString *)localImagesPath;
- (NSImage *)forecastImageForDay:(int)dayNumber imageDir:(NSString *)localImagesPath;

// "private" methods
- (NSImage *)imageForFilename:(NSString *)filename size:(int)size imageDir:(NSString *)localImagesPath;

@end



@interface NSMutableArray (DuplicationAdditions)

- (id)duplicate;

@end
