//
//  MFAlertManager.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Fri Mar 14 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MFAlertManager.h"
#import "MEWeatherAlertsPreferencesModule.h"

@implementation MFAlertManager

- (id)init
{
    self = [super init];
    if(self)
	{
        alertingCities = [[NSMutableArray array] retain];
    
		player = [[MFSongPlayer alloc] init];
		emailer = [[MFEmailer alloc] init];
	}
	return self;
}

- (void)createAlertForCity:(MECity *)city withTitle:(NSString *)title withDescription:(NSString *)description withURLString:(NSString *)urlString
{
	if(![alertingCities containsObject:city])
    {
        //[alertingCities addObject:city];
		MEWeatherAlertsPreferencesModule *alertPrefs = [MEWeatherAlertsPreferencesModule sharedInstance];
		if([alertPrefs alertEmailEnabled])
		{
			[emailer emailMessage:[NSString stringWithFormat:@"%@\n%@",title,description] toAccount:[alertPrefs alertEmailAddress]];
		}
		//song
		if([alertPrefs alertSongEnabled])
		{
			[player playSong:[alertPrefs song]];
		}
		//bounce
		if([alertPrefs bounceDockEnabled])
		{
			[NSApp deactivate];
			[NSApp requestUserAttention:NSCriticalRequest];
		}
		
		if(YES)
		{
			[displayer appendMessage:[NSString stringWithFormat:@"%@\n%@",title,description]];
			//display a text view with this info
		}
	}
}

- (void)addCity:(MECity *)city
{
	[alertingCities addObject:city];
}

- (void)addCity:(MECity *)city alertOptions:(int)options email:(NSString *)email song:(NSString *)song warning:(NSArray *)warn
{
    if(![alertingCities containsObject:city])
    {
        [alertingCities addObject:city];
        
        NSString *warnMsg = @"False Alarm, no warning. Sorry for the interruption";	// Needs localization _RAM

        NSEnumerator *warnEnum = [warn objectEnumerator];
        NSDictionary *dict;
        
        while(dict = [warnEnum nextObject])
        {
            NSString *temp;
            warnMsg = [NSString stringWithFormat:@"Warnings for %@:\n\n",[city cityName]];
            
            //if(temp = [dict objectForKey:@"title"])
                //warnMsg = [NSString stringWithFormat:@"%@%@\n",warnMsg,temp];
                
            if(temp = [dict objectForKey:@"description"])
                warnMsg = [NSString stringWithFormat:@"%@%@\n",warnMsg,temp];
                
            warnMsg = [NSString stringWithFormat:@"%@\n",warnMsg];
        }
        
        //email
        if(options & 1)
        {
            [emailer emailMessage:warnMsg toAccount:email];
        }
        //beep
        if(options & 2)
        {
           // [beeper beginBeeping];
        }
        //song
        if(options & 4)
        {
//            if(![player playSong:song])
//                [beeper beginBeeping];
        }
        //bounce
        if(options & 8)
        {
            [NSApp deactivate];
            [NSApp requestUserAttention:NSCriticalRequest];
        }
        
        if(options)
        {
            [displayer appendMessage:warnMsg];
            //display a text view with this info
        }
    }
}

- (void)removeCity:(MECity *)city
{
    [alertingCities removeObjectIdenticalTo:city];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [self kill:nil];
}

- (IBAction)kill:(id)sender
{
    [player kill];
}

@end

@implementation MFSongPlayer

- (id)init
{
    self = [super init];
    if(self)
    {
        killer = nil;
    }
    return self;
}

- (BOOL)playSong:(NSString *)path
{
    if(!song)
    {
        song = [[NSSound soundNamed:path] retain];
        [song play];

        killer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(kill) userInfo:nil repeats:NO];
    }
    
    return (song != nil);
}

- (void)kill
{
    if(song)
    {
        [song stop];
		[song release];
		song = nil;
	}
    
    if(killer && [killer isValid])
        [killer invalidate];
    
    [killer release];
	killer = nil;
}

@end


@implementation MFMessageDisplay

- (void)appendMessage:(NSString *)msg
{
    [NSApp activateIgnoringOtherApps:YES];
    [[message window] makeKeyAndOrderFront:nil];
    [message setEditable:YES];
    [message setSelectedRange:NSMakeRange([[message string] length],0)];
    [message insertText:[NSString stringWithFormat:@"%@\n\n\n",msg]];
    [message setEditable:NO];
}

- (IBAction)clearLog:(id)sender
{
    [message setString:@""];
}

@end


@implementation MFEmailer

- (void)emailMessage:(NSString *)msg toAccount:(NSString *)email
{
    [NSMailDelivery deliverMessage:msg subject:@"Weather Alert" to:email];
}

@end