//
//  NSUserDefaults+MEColorSupport.m
//  Meteorologist
//
//  Created by Joseph Crobak on 5/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NSUserDefaults+MEColorSupport.h"

@implementation NSUserDefaults(myColorSupport)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey
{
    NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
    [self setObject:theData forKey:aKey];
}

- (NSColor *)colorForKey:(NSString *)aKey
{
    NSColor *theColor=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
        theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
    return theColor;
}

@end