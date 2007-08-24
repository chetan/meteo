//
//  MEAppearancePreferences.m
//  Meteorologist
//
//  Created by Joseph Crobak on 08/11/2004.
//  Copyright 2004 Meteo Group. All rights reserved.
//

#import "MEAppearancePreferences.h"


@implementation MEAppearancePreferences
- (id)init 
{
	self = [super init];
	if (self)
	{

	}
	return self;
}


#pragma mark - Inheritted from NSPreferefenceModule -
/**
* Image to display in the preferences toolbar
 * 32x30 pixels (72 DPI) TIFF
 */
- (NSImage *) imageForPreferenceNamed:(NSString *)_name 
{
	return [[[NSImage imageNamed:@"MECityPreferences"] retain] autorelease];
}

/**
* Override to return the name of the relevant nib
 */
- (NSString *) preferencesNibName 
{
	return @"MEAppearancePreferences";
}

- (BOOL) hasChangesPending
{
	return NO;
}

- (BOOL) isResizeable {
	return NO;
}

- (void) initializeFromDefaults 
{

}

- (BOOL)moduleCanBeRemoved 
{	
	return YES;
}

- (BOOL)preferencesWindowShouldClose
{	
	return YES;
}

@end
