//
//  METestWeatherItem.m - My first unit test EVER!!!!
//  Meteorologist
//
//  Created by Joseph Crobak on 3/8/05.
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

#import "METestWeatherItem.h"
#import "MEWeatherItem.h"

@implementation METestWeatherItem

- (void) testTempConversion 
{
	
	// ------ English Base Units ------
	MEWeatherItem *currentTemp = [MEWeatherItem weatherItemWithBaseUnits:MEFahrenheitUnits
																   value:[NSString stringWithFormat:@"50%C",(unichar)0x00B0]];
	// englishValue
	shouldBeEqual ([currentTemp englishValueWithUnits:NO],([NSString stringWithFormat:@"50%C",(unichar)0x00B0]));
	shouldBeEqual ([currentTemp englishValueWithUnits:YES],([NSString stringWithFormat:@"50%CF",(unichar)0x00B0]));
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:NO],[currentTemp englishValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:YES],[currentTemp englishValueWithUnits:YES]);
		
	// metricValue
	shouldBeEqual ([currentTemp metricValueWithUnits:NO],([NSString stringWithFormat:@"10%C",(unichar)0x00B0])); // returns 0˚
	shouldBeEqual ([currentTemp metricValueWithUnits:YES],([NSString stringWithFormat:@"10%CC",(unichar)0x00B0])); // returns 0˚C
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:NO],[currentTemp metricValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:YES],[currentTemp metricValueWithUnits:YES]);
	
	shouldBeEqual ([currentTemp englishAndMetricValues],([NSString stringWithFormat:@"50%CF/10%CC",(unichar)0x00B0,(unichar)0x00B0])); // returns 50˚F/10˚C	
	// ------------------------------------
	
	// ------ Metric Base Units ------
	currentTemp = [MEWeatherItem weatherItemWithBaseUnits:MECelsiusUnits
													value:[NSString stringWithFormat:@"10%C",(unichar)0x00B0]];
	// englishValue
	shouldBeEqual ([currentTemp englishValueWithUnits:NO],([NSString stringWithFormat:@"50%C",(unichar)0x00B0]));
	shouldBeEqual ([currentTemp englishValueWithUnits:YES],([NSString stringWithFormat:@"50%CF",(unichar)0x00B0]));
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:NO],[currentTemp englishValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:YES],[currentTemp englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([currentTemp metricValueWithUnits:NO],([NSString stringWithFormat:@"10%C",(unichar)0x00B0])); // returns 0˚
	shouldBeEqual ([currentTemp metricValueWithUnits:YES],([NSString stringWithFormat:@"10%CC",(unichar)0x00B0])); // returns 0˚C
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:NO],[currentTemp metricValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:YES],[currentTemp metricValueWithUnits:YES]);
	
	shouldBeEqual ([currentTemp englishAndMetricValues],([NSString stringWithFormat:@"50%CF/10%CC",(unichar)0x00B0,(unichar)0x00B0])); // returns 50˚F/10˚C	
    // ------------------------------------	
	
	// ------ Testing in line conversion ------
	currentTemp = [MEWeatherItem weatherItemWithBaseUnits:MEFahrenheitUnits
													value:[NSString stringWithFormat:@"High in the 70s to lower 80s"]];
	// englishValue
	shouldBeEqual ([currentTemp englishValueWithUnits:NO],([NSString stringWithFormat:@"High in the 70s to lower 80s",(unichar)0x00B0,(unichar)0x00B0]));
	shouldBeEqual ([currentTemp englishValueWithUnits:YES],([NSString stringWithFormat:@"High in the 70%CFs to lower 80%CFs",(unichar)0x00B0,(unichar)0x00B0]));
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:NO],[currentTemp englishValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MEFahrenheitUnits showUnitsLabel:YES],[currentTemp englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([currentTemp metricValueWithUnits:NO],([NSString stringWithFormat:@"High in the 21%Cs to lower 27%Cs",(unichar)0x00B0,(unichar)0x00B0])); // returns 0˚
	shouldBeEqual ([currentTemp metricValueWithUnits:YES],([NSString stringWithFormat:@"High in the 21%CCs to lower 27%CCs",(unichar)0x00B0,(unichar)0x00B0])); // returns 0˚C
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:NO],[currentTemp metricValueWithUnits:NO]);
	shouldBeEqual ([currentTemp valueForUnits:MECelsiusUnits showUnitsLabel:YES],[currentTemp metricValueWithUnits:YES]);
	
	shouldBeEqual ([currentTemp englishAndMetricValues],([NSString stringWithFormat:@"High in the 70%CFs to lower 80%CFs/High in the 21%CCs to lower 27%CCs",(unichar)0x00B0,(unichar)0x00B0,(unichar)0x00B0,(unichar)0x00B0])); // returns 50˚F/10˚C	
	// ------------------------------------
	
}

-(void)testFeetAndMeters
{
	// ------ English Base Units ------
	MEWeatherItem *feet = [MEWeatherItem weatherItemWithBaseUnits:MEFeetUnits
															value:@"Overcast (OVC) : 3700"];
	
	// englishValue
	shouldBeEqual ([feet englishValueWithUnits:NO],@"Overcast (OVC) : 3700");
	shouldBeEqual ([feet englishValueWithUnits:YES],@"Overcast (OVC) : 3700ft");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:NO],[feet englishValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:YES],[feet englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([feet metricValueWithUnits:NO],@"Overcast (OVC) : 1128"); 
	shouldBeEqual ([feet metricValueWithUnits:YES],@"Overcast (OVC) : 1128m"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:NO],[feet metricValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:YES],[feet metricValueWithUnits:YES]);
	
	shouldBeEqual ([feet englishAndMetricValues],@"Overcast (OVC) : 3700ft/Overcast (OVC) : 1128m"); 
	// ------------------------------------
	
	// ------- No Numeric Value ------
	feet = [MEWeatherItem weatherItemWithBaseUnits:MEFeetUnits
											 value:@"Clear (CLR) :  -"];
	// englishValue
	shouldBeEqual ([feet englishValueWithUnits:NO],@"Clear (CLR) :  -");
	shouldBeEqual ([feet englishValueWithUnits:YES],@"Clear (CLR) :  -");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:NO],[feet englishValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:YES],[feet englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([feet metricValueWithUnits:NO],@"Clear (CLR) :  -"); 
	shouldBeEqual ([feet metricValueWithUnits:YES],@"Clear (CLR) :  -"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:NO],[feet metricValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:YES],[feet metricValueWithUnits:YES]);
	
	shouldBeEqual ([feet englishAndMetricValues],@"Clear (CLR) :  -"); 
	// ------------------------------------
	
	// ------ Metric Base Units ------
	feet = [MEWeatherItem weatherItemWithBaseUnits:MEMetersUnits
											 value:@"Overcast (OVC) : 1128"];
	
	// englishValue
	shouldBeEqual ([feet englishValueWithUnits:NO],@"Overcast (OVC) : 3701");
	shouldBeEqual ([feet englishValueWithUnits:YES],@"Overcast (OVC) : 3701ft");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:NO],[feet englishValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEFeetUnits showUnitsLabel:YES],[feet englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([feet metricValueWithUnits:NO],@"Overcast (OVC) : 1128"); 
	shouldBeEqual ([feet metricValueWithUnits:YES],@"Overcast (OVC) : 1128m"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:NO],[feet metricValueWithUnits:NO]);
	shouldBeEqual ([feet valueForUnits:MEMetersUnits showUnitsLabel:YES],[feet metricValueWithUnits:YES]);
	
	shouldBeEqual ([feet englishAndMetricValues],@"Overcast (OVC) : 3701ft/Overcast (OVC) : 1128m"); 
	// ------------------------------------
	
	
}

-(void) testMilesAndKilometers
{
	// ------ English Base Units ------
	MEWeatherItem *miles = [MEWeatherItem weatherItemWithBaseUnits:MEMilesUnits
															value:@"10.0"];
	
	// englishValue
	shouldBeEqual ([miles englishValueWithUnits:NO],@"10.0");
	shouldBeEqual ([miles englishValueWithUnits:YES],@"10mi");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEMilesUnits showUnitsLabel:NO],[miles englishValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEMilesUnits showUnitsLabel:YES],[miles englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([miles metricValueWithUnits:NO],@"16.1"); 
	shouldBeEqual ([miles metricValueWithUnits:YES],@"16.1km"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEKilometersUnits showUnitsLabel:NO],[miles metricValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEKilometersUnits showUnitsLabel:YES],[miles metricValueWithUnits:YES]);
	
	shouldBeEqual ([miles englishAndMetricValues],@"10mi/16.1km"); 
	// ------------------------------------
	
	// ------ Metric Base Units ------
	miles = [MEWeatherItem weatherItemWithBaseUnits:MEKilometersUnits
											 value:@"16.1"];
	
	// englishValue
	shouldBeEqual ([miles englishValueWithUnits:NO],@"10"); // doesn't look like 10.0 is possible
	shouldBeEqual ([miles englishValueWithUnits:YES],@"10mi");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEMilesUnits showUnitsLabel:NO],[miles englishValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEMilesUnits showUnitsLabel:YES],[miles englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([miles metricValueWithUnits:NO],@"16.1"); 
	shouldBeEqual ([miles metricValueWithUnits:YES],@"16.1km"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEKilometersUnits showUnitsLabel:NO],[miles metricValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEKilometersUnits showUnitsLabel:YES],[miles metricValueWithUnits:YES]);
	
	shouldBeEqual ([miles englishAndMetricValues],@"10mi/16.1km"); 
}

-(void) testMPHAndKPH
{
	// ------ English Base Units ------
	MEWeatherItem *miles = [MEWeatherItem weatherItemWithBaseUnits:MEMPHUnits
															 value:@"NE 5"];
	
	// englishValue
	shouldBeEqual ([miles englishValueWithUnits:NO],@"NE 5");
	shouldBeEqual ([miles englishValueWithUnits:YES],@"NE 5mph");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEMPHUnits showUnitsLabel:NO],[miles englishValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEMPHUnits showUnitsLabel:YES],[miles englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([miles metricValueWithUnits:NO],@"NE 8"); 
	shouldBeEqual ([miles metricValueWithUnits:YES],@"NE 8kph"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEKPHUnits showUnitsLabel:NO],[miles metricValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEKPHUnits showUnitsLabel:YES],[miles metricValueWithUnits:YES]);
	
	shouldBeEqual ([miles englishAndMetricValues],@"NE 5mph/NE 8kph"); 
	// ------------------------------------
	
	// ------ Metric Base Units ------
	miles = [MEWeatherItem weatherItemWithBaseUnits:MEKPHUnits
											  value:@"NE 8"];
	
	// englishValue
	shouldBeEqual ([miles englishValueWithUnits:NO],@"NE 5");
	shouldBeEqual ([miles englishValueWithUnits:YES],@"NE 5mph");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEMPHUnits showUnitsLabel:NO],[miles englishValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEMPHUnits showUnitsLabel:YES],[miles englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([miles metricValueWithUnits:NO],@"NE 8"); 
	shouldBeEqual ([miles metricValueWithUnits:YES],@"NE 8kph"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([miles valueForUnits:MEKPHUnits showUnitsLabel:NO],[miles metricValueWithUnits:NO]);
	shouldBeEqual ([miles valueForUnits:MEKPHUnits showUnitsLabel:YES],[miles metricValueWithUnits:YES]);
	
	shouldBeEqual ([miles englishAndMetricValues],@"NE 5mph/NE 8kph"); 
	// ------------------------------------
}

- (void)testPressureUnits
{
	// ------ English Base Units ------
	MEWeatherItem *weatherItem = [MEWeatherItem weatherItemWithBaseUnits:MEInchesPressureUnits
															 value:@"29.51"];
	
	// englishValue
	shouldBeEqual ([weatherItem englishValueWithUnits:NO],@"29.51");
	shouldBeEqual ([weatherItem englishValueWithUnits:YES],@"29.51in");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEInchesPressureUnits showUnitsLabel:NO],[weatherItem englishValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEInchesPressureUnits showUnitsLabel:YES],[weatherItem englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([weatherItem metricValueWithUnits:NO],@"999"); 
	shouldBeEqual ([weatherItem metricValueWithUnits:YES],@"999Mb"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEMillibarsPressureUnits showUnitsLabel:NO],[weatherItem metricValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEMillibarsPressureUnits showUnitsLabel:YES],[weatherItem metricValueWithUnits:YES]);
	
	shouldBeEqual ([weatherItem englishAndMetricValues],@"29.51in/999Mb"); 
	// ------------------------------------
	
	// ------ Metric Base Units ------
	weatherItem = [MEWeatherItem weatherItemWithBaseUnits:MEMillibarsPressureUnits
											  value:@"999"];
	
	// englishValue
	shouldBeEqual ([weatherItem englishValueWithUnits:NO],@"29.5"); // 29.50
	shouldBeEqual ([weatherItem englishValueWithUnits:YES],@"29.5in"); // 29.50
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEInchesPressureUnits showUnitsLabel:NO],[weatherItem englishValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEInchesPressureUnits showUnitsLabel:YES],[weatherItem englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([weatherItem metricValueWithUnits:NO],@"999"); 
	shouldBeEqual ([weatherItem metricValueWithUnits:YES],@"999Mb"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEMillibarsPressureUnits showUnitsLabel:NO],[weatherItem metricValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEMillibarsPressureUnits showUnitsLabel:YES],[weatherItem metricValueWithUnits:YES]);
	
	shouldBeEqual ([weatherItem englishAndMetricValues],@"29.5in/999Mb"); 
	// ------------------------------------
}

-(void)testPercentUnits
{
	MEWeatherItem *weatherItem = [MEWeatherItem weatherItemWithBaseUnits:MEPercentUnits
																   value:@"65%"];
	
	// englishValue
	shouldBeEqual ([weatherItem englishValueWithUnits:NO],@"65%");
	shouldBeEqual ([weatherItem englishValueWithUnits:YES],@"65%");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEPercentUnits showUnitsLabel:NO],[weatherItem englishValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEPercentUnits showUnitsLabel:YES],[weatherItem englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([weatherItem metricValueWithUnits:NO],@"65%"); 
	shouldBeEqual ([weatherItem metricValueWithUnits:YES],@"65%"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEPercentUnits showUnitsLabel:NO],[weatherItem metricValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEPercentUnits showUnitsLabel:YES],[weatherItem metricValueWithUnits:YES]);
	
	shouldBeEqual ([weatherItem englishAndMetricValues],@"65%"); 	
}

- (void)testUnitsIncludedWithValue
{
	MEWeatherItem *weatherItem = [MEWeatherItem weatherItemWithBaseUnits:MEUnitsIncludedWithValue
																   value:@"6:18 AM EST"];
	
	// englishValue
	shouldBeEqual ([weatherItem englishValueWithUnits:NO],@"6:18 AM EST");
	shouldBeEqual ([weatherItem englishValueWithUnits:YES],@"6:18 AM EST");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEUnitsIncludedWithValue showUnitsLabel:NO],[weatherItem englishValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEUnitsIncludedWithValue showUnitsLabel:YES],[weatherItem englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([weatherItem metricValueWithUnits:NO],@"6:18 AM EST"); 
	shouldBeEqual ([weatherItem metricValueWithUnits:YES],@"6:18 AM EST"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MEUnitsIncludedWithValue showUnitsLabel:NO],[weatherItem metricValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MEUnitsIncludedWithValue showUnitsLabel:YES],[weatherItem metricValueWithUnits:YES]);
	
	shouldBeEqual ([weatherItem englishAndMetricValues],@"6:18 AM EST"); 	
}

- (void)testNoUnits
{
	MEWeatherItem *weatherItem = [MEWeatherItem weatherItemWithBaseUnits:MENoUnits
																   value:@"Overcast"];
	
	// englishValue
	shouldBeEqual ([weatherItem englishValueWithUnits:NO],@"Overcast");
	shouldBeEqual ([weatherItem englishValueWithUnits:YES],@"Overcast");
	
	// englishValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MENoUnits showUnitsLabel:NO],[weatherItem englishValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MENoUnits showUnitsLabel:YES],[weatherItem englishValueWithUnits:YES]);
	
	// metricValue
	shouldBeEqual ([weatherItem metricValueWithUnits:NO],@"Overcast"); 
	shouldBeEqual ([weatherItem metricValueWithUnits:YES],@"Overcast"); 
	
	// metricValue vs. valueForUnits
	shouldBeEqual ([weatherItem valueForUnits:MENoUnits showUnitsLabel:NO],[weatherItem metricValueWithUnits:NO]);
	shouldBeEqual ([weatherItem valueForUnits:MENoUnits showUnitsLabel:YES],[weatherItem metricValueWithUnits:YES]);
	
	shouldBeEqual ([weatherItem englishAndMetricValues],@"Overcast"); 	
}
@end
