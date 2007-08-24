//
//  MEGenericTableDataSource.h
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


#import <Cocoa/Cocoa.h>

@interface MEGenericTableDataSource : NSObject 
{
	NSMutableArray *rowData;
	BOOL _editable, _selectable;
}

- (id) initWithRowCount:(int)rowCount;
- (id) initWithRowData: (NSMutableArray *)rData isEditable: (BOOL)ed isSelectable: (BOOL)se;
- (int) rowCount;

- (id) copyWithZone: (NSZone *)zone;

- (NSString *) dataSourceName;

- (BOOL) isEditable;
- (void) setEditable: (BOOL)b;
- (BOOL) isSelectable;
- (void) setSelectable: (BOOL)b;

- (void)setData: (NSDictionary*)someData forRow: (int)rowIndex;
- (NSDictionary *)dataForRow: (int)rowIndex;

- (void) insertRowAt: (int)rowIndex;
- (void) insertRowAt: (int)rowIndex withData: (NSDictionary *)someData;
- (void) deleteRowAt: (int)rowIndex;
- (void) deleteRows;

// For Drag and Drop
- (BOOL) tableView: (NSTableView *)tableView writeRows: (NSArray*)rows toPasteboard: (NSPasteboard*)pboard;
- (NSDragOperation) tableView: (NSTableView*)tableView validateDrop: (id <NSDraggingInfo>)info proposedRow: (int)row proposedDropOperation: (NSTableViewDropOperation)operation;
- (BOOL) tableView: (NSTableView*)tableView acceptDrop: (id <NSDraggingInfo>)info row: (int)row dropOperation: (NSTableViewDropOperation)operation;
@end
