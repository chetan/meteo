//
//  MEWeatherItem.m
//  Meteorologist
//
//  Created by Joseph Crobak on 2/24/05.
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

#import "MEAppearancePreferencesModule.h"
#import "MEWeatherItem.h"
#import "MEConstants.h"
#import <AGRegex/AGRegex.h>

/* extern'd in MEConstants.h */
MEWeatherUnits *MEFahrenheitUnits        = (MEWeatherUnits *)@"MEFahrenheitUnits";
MEWeatherUnits *MECelsiusUnits           = (MEWeatherUnits *)@"MECelsiusUnits";
MEWeatherUnits *MEFeetUnits              = (MEWeatherUnits *)@"MEFeetUnits";
MEWeatherUnits *MEMetersUnits            = (MEWeatherUnits *)@"MEMetersUnits";
MEWeatherUnits *MEMilesUnits             = (MEWeatherUnits *)@"MEMilesUnits";
MEWeatherUnits *MEKilometersUnits        = (MEWeatherUnits *)@"MEKilometersUnits";
MEWeatherUnits *MEMPHUnits               = (MEWeatherUnits *)@"MEMPHUnits";
MEWeatherUnits *MEKPHUnits               = (MEWeatherUnits *)@"MEKPHUnits";
MEWeatherUnits *MEPercentUnits           = (MEWeatherUnits *)@"MEPercentUnits";
MEWeatherUnits *MEUnitsIncludedWithValue = (MEWeatherUnits *)@"MEUnitsIncludedWithValue";
MEWeatherUnits *MENoUnits                = (MEWeatherUnits *)@"MENoUnits";
MEWeatherUnits *MEInchesPressureUnits    = (MEWeatherUnits *)@"MEInchesPressureUnits";
MEWeatherUnits *MEMillibarsPressureUnits = (MEWeatherUnits *)@"MEMillibarsPressureUnits";

@implementation MEWeatherItem

-(id)initWithBaseUnits:(MEWeatherUnits *)units value:(NSString *)value;
{
	self = [super init];
	if (self)
	{
		baseUnits = [units copy];
		baseValue = [value copy];
	}
	return self;
}

+(MEWeatherItem *)weatherItemWithBaseUnits:(MEWeatherUnits *)units value:(NSString *)value
{
	return [[[MEWeatherItem alloc] initWithBaseUnits:units value:value] autorelease];
}

+(NSDictionary *)unitsConvertorDict
{
	static NSDictionary *unitsConvertor;
	if (!unitsConvertor) // only want to make it once!
	{
		unitsConvertor = [[NSDictionary dictionaryWithObjectsAndKeys:
			//MEFahrenheitUnits  these two are special cases.  It takes an equation to convert, so they'll
			//MECelsiusUnits     be hard coded into the function
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				NSLocalizedString(@"Fahrenheit",@""),@"units",
				NSLocalizedString(@"F",@""),@"shortUnits",nil], // for MEFahrenheitUnits
			MEFahrenheitUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				NSLocalizedString(@"Celsius",@""),@"units",
				NSLocalizedString(@"C",@""),@"shortUnits",nil], // for MECelsiusUnits
			MECelsiusUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				[NSNumber numberWithFloat:0.3048],MEMetersUnits,
				NSLocalizedString(@"feet",@""),@"units",
				NSLocalizedString(@"ft",@""),@"shortUnits",nil], // for MEFeetUnits
			MEFeetUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				[NSNumber numberWithFloat:3.2808399],MEFeetUnits,
				NSLocalizedString(@"meters",@""),@"units",
				NSLocalizedString(@"m",@""),@"shortUnits",nil], // for MEMetersUnits
			MEMetersUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.1f",@"formatString",
				[NSNumber numberWithInt:1],@"precision",
				[NSNumber numberWithFloat:1.61],MEKilometersUnits,
				NSLocalizedString(@"miles",@""),@"units",
				NSLocalizedString(@"mi",@""),@"shortUnits",nil], // for MEMilesUnits
			MEMilesUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.1f",@"formatString",
				[NSNumber numberWithInt:1],@"precision",
				[NSNumber numberWithFloat:0.621],MEMilesUnits,
				NSLocalizedString(@"kilometers",@""),@"units",
				NSLocalizedString(@"km",@""),@"shortUnits",nil], // for MEKilometerUnits
			MEKilometersUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				[NSNumber numberWithFloat:1.61],MEKPHUnits,
				NSLocalizedString(@"miles per hour",@""),@"units",
				NSLocalizedString(@"mph",@""),@"shortUnits",nil], // for MEMPHUnits
			MEMPHUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				[NSNumber numberWithFloat:0.621],MEMPHUnits,
				NSLocalizedString(@"kilometers per hour",@""),@"units",
				NSLocalizedString(@"kph",@""),@"shortUnits",nil], // for MEKilometerUnits
			MEKPHUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				NSLocalizedString(@"%",@""),@"units",
				NSLocalizedString(@"%",@""),@"shortUnits",nil], // for MEPercentUnits
			MEPercentUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.2f",@"formatString",
				[NSNumber numberWithInt:2],@"precision",
				[NSNumber numberWithFloat:33.86],MEMillibarsPressureUnits,
				NSLocalizedString(@"inches",@""),@"units",
				NSLocalizedString(@"in",@""),@"shortUnits",nil], // for MEInchesPressureUnits,
			MEInchesPressureUnits,
			[NSDictionary dictionaryWithObjectsAndKeys: 
				@"%.0f",@"formatString",
				[NSNumber numberWithInt:0],@"precision",
				[NSNumber numberWithFloat:0.02953],MEInchesPressureUnits,
				NSLocalizedString(@"millibars",@""),@"units",
				NSLocalizedString(@"Mb",@""),@"shortUnits",nil], // for MEKilometerUnits
			MEMillibarsPressureUnits,
			nil, // for MEUnitsIncludedWithValue
			MEUnitsIncludedWithValue,
			nil, // for MENoUnits
			MENoUnits,
			nil] retain];
	}	
	return unitsConvertor;
}

#pragma mark -

-(NSString *)description
{
	BOOL units = YES;
	
	if (baseUnits == MEFahrenheitUnits || baseUnits == MECelsiusUnits)
	{
		if ([[MEAppearancePreferencesModule sharedInstance] showBothCF])
			return [self englishAndMetricValues];
		
		if ([[MEAppearancePreferencesModule sharedInstance] hideTempUnits])
			units = NO;
	}
	// show the units unless it is a temperature
	if (![[MEAppearancePreferencesModule sharedInstance] isMetric])
		return [self englishValueWithUnits:units];
	
	return [self metricValueWithUnits:units];
}

-(NSString *)descriptionWithoutUnits
{
	if (![[MEAppearancePreferencesModule sharedInstance] isMetric])
		return [self englishValueWithUnits:NO];
	
	return [self metricValueWithUnits:NO];
}


#pragma mark -


-(NSString *)englishAndMetricValues
{
	NSString *englishValue = [self englishValueWithUnits:YES];
	NSString *metricValue  = [self metricValueWithUnits:YES];
	
	if (![englishValue isEqualToString:metricValue])
		return [NSString stringWithFormat:@"%@/%@",englishValue,metricValue];
	return englishValue;
}

-(NSString *)englishValueWithUnits:(BOOL)includeUnits
{
	if ([baseUnits isEqualToString:MEFahrenheitUnits] ||
		[baseUnits isEqualToString:MECelsiusUnits])
		return [self valueForUnits:MEFahrenheitUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEFeetUnits] ||
		[baseUnits isEqualToString:MEMetersUnits])
		return [self valueForUnits:MEFeetUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEMilesUnits] ||
		[baseUnits isEqualToString:MEKilometersUnits])
		return [self valueForUnits:MEMilesUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEMPHUnits] ||
		[baseUnits isEqualToString:MEKPHUnits])
		return [self valueForUnits:MEMPHUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEInchesPressureUnits] ||
		[baseUnits isEqualToString:MEMillibarsPressureUnits])
		return [self valueForUnits:MEInchesPressureUnits showUnitsLabel:includeUnits];

	return [self valueForUnits:baseUnits showUnitsLabel:includeUnits];
}

-(NSString *)metricValueWithUnits:(BOOL)includeUnits
{
	if ([baseUnits isEqualToString:MEFahrenheitUnits] ||
		[baseUnits isEqualToString:MECelsiusUnits])
		return [self valueForUnits:MECelsiusUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEFeetUnits] ||
		[baseUnits isEqualToString:MEMetersUnits])
		return [self valueForUnits:MEMetersUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEMilesUnits] ||
		[baseUnits isEqualToString:MEKilometersUnits])
		return [self valueForUnits:MEKilometersUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEMPHUnits] ||
		[baseUnits isEqualToString:MEKPHUnits])
		return [self valueForUnits:MEKPHUnits showUnitsLabel:includeUnits];
	if ([baseUnits isEqualToString:MEInchesPressureUnits] ||
		[baseUnits isEqualToString:MEMillibarsPressureUnits])
		return [self valueForUnits:MEMillibarsPressureUnits showUnitsLabel:includeUnits];
	
	return [self valueForUnits:baseUnits showUnitsLabel:includeUnits];}

-(NSString *)valueForUnits:(MEWeatherUnits *)units showUnitsLabel:(BOOL)includeUnits
{
	NSDictionary *unitsConvertor = [MEWeatherItem unitsConvertorDict];
	NSString     *value          = [NSString string];
	AGRegex      *tempRegex      = [AGRegex regexWithPattern:[NSString stringWithFormat:@"[-+]?([0-9]*\\.)?[0-9]+%C?",(unichar)0x00B0]];
	AGRegex      *numberRegex    = [AGRegex regexWithPattern:@"[-+]?([0-9]*\\.)?[0-9]+"];
	NSString     *theUnits       = [NSString string];

	// Figure out what the units are
	if (includeUnits == YES && [[unitsConvertor objectForKey:units] objectForKey:@"shortUnits"])
	{
		theUnits = [[unitsConvertor objectForKey:units] objectForKey:@"shortUnits"];
	}
	
	// should apply to MEPercentUnits, MEUnitsIncludedWithValue, MENoUnits
	if ([baseUnits isEqualToString:MEUnitsIncludedWithValue] ||
		[baseUnits isEqualToString:MENoUnits] || [baseUnits isEqualToString:MEPercentUnits])
	{
		value = [baseValue copy];
	}
	else if ([baseUnits isEqualToString:units] && ([theUnits length] == 0 || [numberRegex findInString:baseValue] == nil))
	{
		value = [baseValue copy];
	}
	else if ([baseUnits isEqualToString:units] &&
			 ([baseUnits isEqualToString:MEFahrenheitUnits] || [baseUnits isEqualToString:MECelsiusUnits]))
	{
		// we need to add units, like below
		AGRegex *matchRegex;
		AGRegexMatch *match;
		int i;
		NSArray *allMatches = [tempRegex findAllInString:baseValue];
		value = [baseValue copy];
		if (allMatches && [allMatches count])
		{
			for (i=0; i<[allMatches count]; i++)
			{
				match = [allMatches objectAtIndex:i];
				matchRegex = [AGRegex regexWithPattern:[match group]];

				NSString *replaceString = [match group];
				// use power of agregex to do find/replace :-)
				if (![replaceString hasSuffix:[NSString stringWithFormat:@"%C",(unichar)0x00B0]])
					replaceString = [replaceString stringByAppendingFormat:@"%C",(unichar)0x00B0];
				if ([theUnits length] > 0)
					replaceString = [replaceString stringByAppendingString:theUnits];
				value = [matchRegex replaceWithString:replaceString
											 inString:value];
			}
		}
	}
	// temperature is a special case
	else if ([baseUnits isEqualToString:MEFahrenheitUnits] && 
			 [units isEqualToString:MECelsiusUnits])
	{
		AGRegex *matchRegex;
		AGRegexMatch *match;
		int i;
		float fahrenheitValue, celsiusValue;
		NSArray *allMatches = [tempRegex findAllInString:baseValue];
		value = [baseValue copy];
		if (allMatches && [allMatches count])
		{
			for (i=0; i<[allMatches count]; i++)
			{
				match = [allMatches objectAtIndex:i];
				matchRegex = [AGRegex regexWithPattern:[match group]];
				fahrenheitValue = [[match group] floatValue];
				celsiusValue = ((fahrenheitValue - 32) * 5.0 / 9.0); // convert the number
				
				NSDecimalNumber *newDecimalValue = [NSDecimalNumber decimalNumberWithString:
					[NSString stringWithFormat:@"%f",celsiusValue]]; // pack it into a NSDecimal
				NSDecimalNumberHandler *zeroPlaceRounder = // create a Handler to describe how to round
					[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
																		   scale:[[[unitsConvertor objectForKey:units] objectForKey:@"precision"] intValue]
																raiseOnExactness:NO
																 raiseOnOverflow:YES
																raiseOnUnderflow:YES
															 raiseOnDivideByZero:YES];
				NSString *replaceString = // use the NSDecimalNumber method to do the rounding
					[[newDecimalValue decimalNumberByRoundingAccordingToBehavior:zeroPlaceRounder] descriptionWithLocale:nil]; 
				// use power of agregex to do find/replace :-)
				replaceString = [replaceString stringByAppendingFormat:@"%C",(unichar)0x00B0];
				if ([theUnits length] > 0)
					replaceString = [replaceString stringByAppendingString:theUnits];
				value = [matchRegex replaceWithString:replaceString
											 inString:value];
			}
		}
	}
	else if ([baseUnits isEqualToString:MECelsiusUnits] && //temperature
			 [units  isEqualToString:MEFahrenheitUnits])
	{
		AGRegex *matchRegex;
		AGRegexMatch *match;
		int i;
		float fahrenheitValue, celsiusValue;
		NSArray *allMatches = [tempRegex findAllInString:baseValue];
		value = [baseValue copy];

		if (allMatches && [allMatches count])
		{
			for (i=0; i<[allMatches count]; i++)
			{
				match = [allMatches objectAtIndex:i];
				matchRegex = [AGRegex regexWithPattern:[match group]];
				celsiusValue = [[match group] floatValue];
				fahrenheitValue = 9.0 / 5.0 * celsiusValue + 32;
				
				NSDecimalNumber *newDecimalValue = [NSDecimalNumber decimalNumberWithString:
					[NSString stringWithFormat:@"%f",fahrenheitValue]]; // pack it into a NSDecimal
				NSDecimalNumberHandler *zeroPlaceRounder = // create a Handler to describe how to round
					[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
																		   scale:[[[unitsConvertor objectForKey:units] objectForKey:@"precision"] intValue]
																raiseOnExactness:NO
																 raiseOnOverflow:YES
																raiseOnUnderflow:YES
															 raiseOnDivideByZero:YES];
				NSString *replaceString = // use the NSDecimalNumber method to do the rounding
					[[newDecimalValue decimalNumberByRoundingAccordingToBehavior:zeroPlaceRounder] descriptionWithLocale:nil]; 
				// use power of agregex to do find/replace :-)
				replaceString = [replaceString stringByAppendingFormat:@"%C",(unichar)0x00B0];
				if ([theUnits length] > 0)
					replaceString = [replaceString stringByAppendingString:theUnits];
				value = [matchRegex replaceWithString:replaceString
											 inString:value];
			}
		}
	}
	else
	{
		NSNumber *conversionFactor = [[unitsConvertor objectForKey:baseUnits] // returns a dictionary
			objectForKey:units];
		value = [baseValue copy];

		if (conversionFactor || (conversionFactor = [NSNumber numberWithFloat:1]))  // if there was a conversion factor
		{
			AGRegex *matchRegex;
			AGRegexMatch *match;
			int i;
			float oldValue, newValue;
			NSArray *allMatches = [numberRegex findAllInString:baseValue];
			if (allMatches && [allMatches count])
			{
				for (i=0; i<[allMatches count]; i++)
				{
					match = [allMatches objectAtIndex:i];
//					NSLog(@"Match! %@",[match group]);
					oldValue = [[match group] floatValue];
					newValue = [conversionFactor floatValue] * oldValue;
//					NSLog(@"newValue = %.1f",newValue);
					matchRegex = [AGRegex regexWithPattern:[match group]];
					
					NSDecimalNumber *newDecimalValue = [NSDecimalNumber decimalNumberWithString:
						[NSString stringWithFormat:@"%f",newValue]]; // pack it into a NSDecimal
//					NSLog(@"newDecimalValue = %@",[newDecimalValue description]);
//					NSLog(@"precision = %i",[[[unitsConvertor objectForKey:units] objectForKey:@"precision"] intValue]);
					NSDecimalNumberHandler *zeroPlaceRounder = // create a Handler to describe how to round
						[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
																			   scale:[[[unitsConvertor objectForKey:units] objectForKey:@"precision"] intValue]
																	raiseOnExactness:NO
																	 raiseOnOverflow:YES
																	raiseOnUnderflow:YES
																 raiseOnDivideByZero:YES];
					NSString *replaceString = // use the NSDecimalNumber method to do the rounding
						[[newDecimalValue decimalNumberByRoundingAccordingToBehavior:zeroPlaceRounder] descriptionWithLocale:nil]; 
					// use power of agregex to do find/replace :-)
					if ([theUnits length] > 0)
						replaceString = [replaceString stringByAppendingString:theUnits];
					value = [matchRegex replaceWithString:replaceString
												 inString:value];
				}
			}
		}
	}
	
	if ([value length] == 0)
		value = [baseValue copy];
//	// Add the Units if necessary.
//	if (includeUnits == YES && [[unitsConvertor objectForKey:units] objectForKey:@"shortUnits"] &&
//		![value hasSuffix:[[unitsConvertor objectForKey:units] objectForKey:@"shortUnits"]])
//	{
//		value = [value stringByAppendingString:[[unitsConvertor objectForKey:units] objectForKey:@"shortUnits"]];
//	}
	return value;
}
@end
