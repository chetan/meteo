//
//  MECitySearchResultsTable.m
//  Meteorologist
//
//  Created by Joseph Crobak on 06/09/2004.
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


// Special Thanks to: Adam Vandenberg for the idea for this code.
// http://flangy.com/dev/osx/tableviewdemo/

#import "MECitySearchResultsTable.h"


@implementation MECitySearchResultsTable

- (NSString *)dataSourceName
{
	return @"City Search Results Table";
}

#pragma mark Table Data Source:

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
    
    return [aRow objectForKey: [aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn		   row:(int)rowIndex
{
    NSString *columnName;
    NSMutableDictionary *aRow;
    
    if ( [self isEditable] )
    {
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
        [aRow setObject:anObject forKey: columnName];
    }
}


@end
