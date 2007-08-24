//
//  MEWeather.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEWeatherModule.h"
#import "MEPrefs.h"
#import "MECity.h"

@class MEWeatherForecastEnumerator;
@class MECity;

@interface MEWeather : NSObject 
{
	IBOutlet MEPrefs *prefs;

    NSMutableArray *weatherModuleNames;
	NSMutableDictionary *weatherModuleCodes;
	NSMutableDictionary *weatherModuleStates;
	
	NSLock *prepareDataLock;
	NSMutableDictionary *rawData;
	
    MEWeatherForecastEnumerator *forecastEnum;
}

+ (MEWeather *)weather;
- (void)addServerNamed:(NSString *)name withCode:(NSString *)code;

- (void)threadedPrepareNewServerData:(id)anArgument;
- (void)prepareNewServerDataForCity:(MECity *)city;

- (NSArray *)activeModuleNames;
- (NSArray *)inactiveModuleNames;
- (NSString *)codeForModuleNamed:(NSString *)name;

- (void)activateModuleNamed:(NSString *)serverName;
- (void)inactivateModuleNamed:(NSString *)servername;

- (NSString *)stringForKey:(NSString *)key;
- (NSString *)forecastStringForKey:(NSString *)key forDay:(int)dayNum;
- (NSImage *)imageForKey:(NSString *)key size:(int)size inDock:(BOOL)dock;
- (NSImage *)forecastImageForKey:(NSString *)key forDay:(int)dayNum size:(int)size inDock:(BOOL)dock;

- (NSString *)processConversionForValue:(NSString *)value key:(NSString *)key;
- (NSString *)labelForKey:(NSString *)key;
+ (NSArray *)unitsForKey:(NSString *)key;


@end

@interface MEWeatherForecastEnumerator : NSObject
{
    NSMutableArray *forecastArrays;
    BOOL isFirst;
}

- (id)initWithForecastArrays:(NSMutableArray *)arrays;
- (void)nextDay;
- (void)nextDay:(BOOL)strip;
- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)inDock;
- (id)objectForKey:(NSString *)key;

@end
