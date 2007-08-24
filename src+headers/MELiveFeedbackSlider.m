//
//  MELiveFeedbackSlider.m
//  Meteorologist
//
//  Created by Joseph Crobak on 03/12/2004.
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

#import "MELiveFeedbackSlider.h"
#import "MEGeneralPreferencesModule.h"

@implementation MELiveFeedbackSlider

- (void)mouseDown:(NSEvent *)theEvent
{
	if ([sliderTextValue respondsToSelector:@selector(setHidden:)])
		[sliderTextValue setHidden:NO];	
	[super mouseDown:theEvent];
	if ([sliderTextValue respondsToSelector:@selector(setHidden:)])
		[sliderTextValue setHidden:YES];
	
	[[MEGeneralPreferencesModule sharedInstance] actionPerformed:self]; // saves changes
}

- (NSString *)stringValue
{
	int minutes = [self intValue];
	int hours = minutes / 60;
	minutes = minutes % 60;
	NSString *label = [NSString string];
	
	if (hours > 1)
	{
		label = [NSString stringWithFormat:@"%i hours",hours];
	}
	else if (hours)
	{
		label = [NSString stringWithFormat:@"%i hour",hours];
	}
	
	if (hours && minutes)
	{
		label = [label stringByAppendingString:@", "];
	}
	
	if (minutes > 1)
	{
		label = [label stringByAppendingFormat:@"%i minutes",minutes];
	}
	else if (minutes)
	{
		label = [label stringByAppendingFormat:@"%i minute",minutes];
	}
	
	return [[label retain] autorelease];
}

@end
