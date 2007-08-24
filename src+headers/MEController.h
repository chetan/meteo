//
//  MEController.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//  Largely updated by Joe Crobak in November of 2004.
//
//  Major Portions Copyright (c) 2004 Joe Crobak
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
#import "MECity.h"
#import "MFAlertManager.h"
#import "IXSCNotificationManager.h"

@interface MEController : NSObject 
{
	NSCalendarDate *lastUpdate, *nextUpdate;
	
    NSStatusItem *statusItem;
    NSMenu *menu;
    NSFont *boldFont, *unboldFont;
    NSTimer *automaticUpdateTimer, *automaticRotateTimer;
    
    BOOL isInDock;
    BOOL isInMenubar;

//    IBOutlet NSTableView *cityTable;
//    IBOutlet NSButton *addCity;
//    IBOutlet NSButton *removeCity;
//    IBOutlet NSButton *editCity;
//    IBOutlet NSButton *updateMenu;
            
	MECity *mainCity;
    IBOutlet MFAlertManager *alertManager;
    
    IBOutlet NSProgressIndicator *downloadWindowProgress;
    IBOutlet NSWindow *downloadWindow;
    IBOutlet NSTextField *downloadWindowName;
    IBOutlet NSTextField *downloadWindowSize;
    IBOutlet NSImageView *downloadWindowImage;
    	
	// About Window
	IBOutlet NSWindow *aboutWindow;
	IBOutlet NSTextField *versionNumber;
	IBOutlet NSButton *meteoURLButton;
	IBOutlet NSButton *CURLHandleURLButton;
	IBOutlet NSButton *AGKitURLButton;
			
	
    NSTimer *menuBarLoadTimer;
	NSAutoreleasePool *menuBarLoadARP;
	
	// JRC
	NSMenuItem  *refreshMI,
				*showCityEditorMI,
				*citySwitcherMI,
				*preferencesMI,
				*quitMI;
				
	NSLock *menuDrawLock;
	NSLock *cityDownloadsPendingLock;
	
	int cityDownloadsPending;
	BOOL redrawOnly;
	
	NSString *localImagesPath;
	
	IXSCNotificationManager *systemConfigNotificationManager;
}

- (void)updateLocalImages;

- (void)showPreferencesWindow:(id)sender;
- (void)showAboutWindow:(id)sender;

- (void)reestablishAutomaticUpdateTimer;
- (void)reestablishAutomaticRotateTimer;
- (void)reestablishTimers;
- (void)downloadNewDataTimerFired;
- (void)rotateCitiesTimerFired;

- (void)tellCitiesToUpdateWeatherReports;

- (void)redrawMenu;
- (void)generateMenu;
- (void)addControlMenuItemsToMenu:(NSMenu *)aMenu;
- (void)addCurrentWeatherDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city;
- (void)addForecastDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city;
- (void)addCurrentAndForecastDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city;
- (void)addNonMainCitiesToMenu:(NSMenu*)theMenu;
- (NSString *)relativeDateStringForDate:(NSCalendarDate *)date;

- (void)dummy:(NSNotification *)notification;
- (NSMutableArray *)cities;
- (NSArray *)activeCities;

NSFont* fontWithMaxHeight(NSString *name, int maxHeight);

- (IBAction)URLButtonClick:(id)sender;
- (IBAction)refreshCallback:(id)sender;
- (void)startLoadingInMenuBar;
- (void)stopLoadingInMenuBar;
- (void)updateDock;
+ (NSMutableDictionary *)bestAttributesForString:(NSString *)string size:(NSSize)size fontName:(NSString *)fontName;

@end

@interface MEMenuItem : NSMenuItem
{
	NSString *link;
}

-(void)setLink:(NSString*)url;
-(NSString*)link;

@end;
