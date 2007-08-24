//
//  MEPropertyDataSource.m
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


#import "MEPropertyDataSource.h"


@implementation MEPropertyDataSource

- (NSString *)dataSourceName
{
	return @"Property Data Source";
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
#pragma mark -

- (void)addDataToEnd: (NSDictionary*)someData
{
	[rowData addObject:[NSMutableDictionary dictionary]];
	[[rowData lastObject] addEntriesFromDictionary: someData];
}
#pragma mark Table Data Source:

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{	
	if ([aCell isMemberOfClass:[NSButtonCell class]])
	{
		[aCell setState:[[[self dataForRow:row] objectForKey:[aTableColumn identifier]] boolValue]];
	}
	
	[aCell setEnabled:[self isSelectable]];
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
    if ([[aTableColumn identifier] isEqualToString:@"servers"])
	{
		NSArray      *servers = [aRow objectForKey:[aTableColumn identifier]];
		NSEnumerator *itr = [servers objectEnumerator];
		NSString     *moduleName;
		NSString     *allServers = [NSString string];
		BOOL notFirst = NO;
		
		while (moduleName = [itr nextObject])
		{
			if (notFirst)
			{
				allServers = [allServers stringByAppendingFormat:@", %@",moduleName];
			}
			else
			{		
				allServers = moduleName;
				notFirst = YES;				
			}
		}
		return allServers;
	}
    return [aRow objectForKey: [aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn		   row:(int)rowIndex
{
    NSString *columnName;
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
	
	columnName = [aTableColumn identifier];
    
	if ([[aTableColumn identifier] isEqualToString:@"enabled"])
	{
		[aRow setObject:[NSNumber numberWithBool:![[aRow objectForKey:@"enabled"] boolValue]]
				 forKey:@"enabled"];
	}
    
	//[aRow setObject:anObject forKey: columnName];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualTo:@"enabled"])
		return YES;
    return NO;
}

@end
