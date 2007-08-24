//
//  MEConstants.h
//  Meteorologist
//
//  Created by Joseph Crobak on 3/4/05.
//
//  Copyright (c) 2005 Joe Crobak and Meteorologist Group
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

@interface MEWeatherUnits : NSString {
	
}
@end

/* These are defined in MEWeatherItem.m */
extern MEWeatherUnits *MEFahrenheitUnits;
extern MEWeatherUnits *MECelsiusUnits;
extern MEWeatherUnits *MEFeetUnits;
extern MEWeatherUnits *MEMetersUnits;
extern MEWeatherUnits *MEMilesUnits;
extern MEWeatherUnits *MEKilometersUnits;
extern MEWeatherUnits *MEMPHUnits;
extern MEWeatherUnits *MEKPHUnits;
extern MEWeatherUnits *MEPercentUnits;
extern MEWeatherUnits *MEUnitsIncludedWithValue;
extern MEWeatherUnits *MENoUnits;
extern MEWeatherUnits *MEInchesPressureUnits;
extern MEWeatherUnits *MEMillibarsPressureUnits;
