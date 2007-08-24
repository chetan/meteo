//
//  NSUserDefaults+MEColorSupport.h
//  Meteorologist
//
//  Created by Joseph Crobak on 5/18/05.
//  Copyright 2005 Meteorologist Group. All rights reserved.
//

// This code is taken from the Apple NSUserDefaults Documentation

#import <Foundation/Foundation.h>

@interface NSUserDefaults(myColorSupport)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey;
- (NSColor *)colorForKey:(NSString *)aKey;

@end
