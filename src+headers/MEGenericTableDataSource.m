//
//  MEGenericTableDataSource.m
//  Meteorologist
//
//  Created by Joseph Crobak on 15/11/2004.
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


#import "MEGenericTableDataSource.h"


@implementation MEGenericTableDataSource

-(id) init
{
	return [self initWithRowCount:0];
}

-(id) initWithRowCount: (int)rowCount
{
    int i;
	
    if (self = [super init])
    {
        _editable = NO;
		_selectable = YES;
		
        rowData = [[NSMutableArray alloc] initWithCapacity: rowCount];
        for (i=0; i < rowCount; i++)
        {
            [rowData addObject: [NSMutableDictionary dictionary]];
		}
    }
    return self;
}

- (id) initWithRowData: (NSMutableArray *)rData isEditable: (BOOL)ed isSelectable: (BOOL)se
{
	if (self = [super init])
	{
		_editable = ed;
		_selectable = se;
		
		rowData = [rData retain];
	}
	return self;
}

- (void) dealloc
{
	[rowData release];
	[super dealloc];
}

#pragma mark -

- (id) copyWithZone: (NSZone *)zone
{
	MEGenericTableDataSource *copy = [[[self class] allocWithZone: zone]
												  initWithRowData: [NSMutableArray arrayWithArray:rowData]
													   isEditable: _editable
													 isSelectable: _selectable];	
	return copy;
}


- (NSString *)dataSourceName
{
	return @"Generic";
}

- (BOOL)isEditable
{
    return _editable;
}

- (void)setEditable:(BOOL)b
{
    _editable = b;
}

- (BOOL)isSelectable
{
	return _selectable;
}

- (void)setSelectable:(BOOL)b
{
	_selectable = b;
}

#pragma mark -
- (void)setData: (NSDictionary *)someData forRow: (int)rowIndex
{
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
    
    [aRow addEntriesFromDictionary: someData];
}

- (NSDictionary *)dataForRow: (int)rowIndex
{
    NSDictionary *aRow;
	
    NS_DURING
        aRow = [rowData objectAtIndex: rowIndex];
    NS_HANDLER
        if ([[localException name] isEqual: @"NSRangeException"])
        {
            NSLog(@"Setting data out of bounds.");
            return nil;
        }
        else [localException raise];
    NS_ENDHANDLER
	
    return [NSDictionary dictionaryWithDictionary: aRow];
}

#pragma mark -

- (int)rowCount
{
    return [rowData count];
}

#pragma mark -

#pragma mark Table Data Source:
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [rowData count];
}

// Returns nil, handled by subclass
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex
{
	return nil;
}

// also must be handled by subclass
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn		   row:(int)rowIndex
{
	
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	return [self isSelectable];
}
#pragma mark -

#pragma mark -> For Drag and Drop
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    NSString *type = [tableView autosaveName];
	
    [pboard declareTypes:[NSArray arrayWithObjects:type,nil] owner:self];
    [pboard setData:[NSArchiver archivedDataWithRootObject:rows] forType:type];
    [pboard setString:[rows description] forType: NSStringPboardType];
    return YES;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSArray *selectedRows;
    NSEnumerator *rowEnum;
    NSNumber *aRow;
    
    if(row<0)
        return NO;
    
    selectedRows = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:[tableView autosaveName]]];
	
    rowEnum = [selectedRows objectEnumerator];
	
    while(aRow = [rowEnum nextObject])
    {
        int index = [aRow intValue];
        
        id obj = [[rowData objectAtIndex:index] retain];
        [rowData replaceObjectAtIndex:index withObject:[NSNull null]];
        
        [rowData insertObject:obj atIndex:row];
        [rowData removeObject:[NSNull null]];
		[obj release];
    }
    
//    if([[self lastObject] isMemberOfClass:[MECity class]])
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"MECityOrderChanged" object:nil];
    
    [tableView reloadData];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationMove;
}

#pragma mark -
- (void) insertRowAt:(int)rowIndex
{
    [self insertRowAt: rowIndex withData: [NSMutableDictionary dictionary]];
}

- (void) insertRowAt:(int)rowIndex withData:(NSDictionary *)someData
{
#ifdef DEBUG
	NSLog(@"Inserting at row: %i",rowIndex);
#endif
    [rowData insertObject: someData atIndex: rowIndex];
}

- (void) deleteRowAt:(int)rowIndex
{    
    [rowData removeObjectAtIndex: rowIndex];
}

- (void) deleteRows
{
	[rowData removeAllObjects];
}

@end
