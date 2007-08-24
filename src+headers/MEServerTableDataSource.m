//
//  MEServerTableDataSource.m
//  Meteorologist
//
//  Created by Joseph Crobak on 09/11/2004.
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


#import "MEServerTableDataSource.h"
#import "MECityPreferencesModule.h"

@implementation MEServerTableDataSource

- (NSString *)dataSourceName
{
	return @"Server Table Data Source";
}


#pragma mark Archiving/Unarchiving
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:rowData forKey:@"rowData"];
	[encoder encodeObject:[NSNumber numberWithBool:_editable] forKey:@"editable"];
	[encoder encodeObject:[NSNumber numberWithBool:_selectable] forKey:@"selectable"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
		rowData = [[decoder decodeObjectForKey:@"rowData"] retain];
		_editable = [[decoder decodeObjectForKey:@"editable"] boolValue];
		_selectable = [[decoder decodeObjectForKey:@"selectable"] boolValue];				
    }
    return self;
}

#pragma mark Specific to Server Table Data Source:
- (NSArray *)activeModuleNames
{
	NSEnumerator   *itr = [rowData objectEnumerator];
	NSMutableArray *activeModuleNames = [NSMutableArray arrayWithCapacity:[self rowCount]];
	NSDictionary *aRow;
	while (aRow = [itr nextObject])
	{
		if ([[aRow objectForKey:@"enabled"] boolValue])
		{
			[activeModuleNames addObject:[aRow objectForKey:@"moduleName"]];
		}
	}
	return [[activeModuleNames retain] autorelease];
}

- (NSArray *)inactiveModuleNames
{
	NSEnumerator   *itr = [rowData objectEnumerator];
	NSMutableArray *inactiveModuleNames = [NSMutableArray arrayWithCapacity:[self rowCount]];
	NSDictionary *aRow;
	while (aRow = [itr nextObject])
	{
		if (![[aRow objectForKey:@"enabled"] boolValue] && ![[aRow objectForKey:@"code"] isEqualToString:@""])
		{
			[inactiveModuleNames addObject:[aRow objectForKey:@"moduleName"]];
		}
	}
	return [[inactiveModuleNames retain] autorelease];
}


#pragma mark Table Data Source:

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{	
	if ([aCell isMemberOfClass:[NSButtonCell class]])
	{
		[aCell setState:[[[self dataForRow:row] objectForKey:[aTableColumn identifier]] boolValue]];
		[aCell setEnabled:[[[MECityPreferencesModule sharedInstance] cities] count]];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex
{
    NSDictionary *aRow;
	
    NS_DURING
        aRow = [rowData objectAtIndex: rowIndex];
    NS_HANDLER
        if ([[localException name] isEqual: @"NSRangeException"])
        {
            return nil;
        }
        else [localException raise];
    NS_ENDHANDLER
    
	if ([[aTableColumn identifier] isEqualToString:@"code"] && [[aRow objectForKey: [aTableColumn identifier]] isEqualToString:@""])
		return @"????";
    return [aRow objectForKey: [aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn		   row:(int)rowIndex
{
    NSString *columnName= [aTableColumn identifier];;
    NSMutableDictionary *aRow;
	
	NS_DURING
		aRow = [rowData objectAtIndex: rowIndex];
	NS_HANDLER
		if ([[localException name] isEqual: @"NSRangeException"])
		{
			return;
		}
		else [localException raise];
	NS_ENDHANDLER
	
	if ([[aTableColumn identifier] isEqualToString:@"enabled"])
	{
		if ([[aRow objectForKey:@"enabled"] boolValue])
		{// they are unchecking (disabling)
			[aRow setObject:[NSNumber numberWithBool:NO] forKey:columnName];
			
			// let MECityPreferences know that we've changed the active servers!
			[[MECityPreferencesModule sharedInstance] activeServersChanged];
		}
		else
		{// they are checking (enabling)
			if ([[aRow objectForKey:@"code"] isEqualToString:@""])
			{// must perform a search.
				[[MECityPreferencesModule sharedInstance] displaySearchSheet:self];
			}
			else
			{// must enable, already has a city code though.
				[aRow setObject:[NSNumber numberWithBool:YES] forKey:columnName];
			}
		}
	}
    if ( [self isEditable] )
    {
        [aRow setObject:anObject forKey: columnName];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualTo:@"enabled"])
		return YES;
    return NO;
}

@end
