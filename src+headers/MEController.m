//
//  MEController.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//  Major Portions Copyright (c) 2004 Joe Crobak and Meteorologist Group
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


#import "MEController.h"
#import "MEWebUtils.h"
#import "MEPlug-inManager.h"
#import "NSPreferences.h"
#import "MSPreferences.h"
#import "MECityPreferencesModule.h"
#import "MEAppearancePreferencesModule.h"
#import "MEGeneralPreferencesModule.h"
#import "MEWeatherAlertsPreferencesModule.h"
//#import "IAGrayscaleFilter.h" // for grayscale conversion
#import <CURLHandle/CURLHandle.h> // curl "hello" and "goodbye"

const int ATTR_FONT_SIZE = 12;

@implementation MEController

- (id)init
{
	self = [super init];
	if(self)
	{
		menu                     = [[NSMenu alloc] init]; 
		menuDrawLock             = [[NSLock alloc] init];
		cityDownloadsPendingLock = [[NSLock alloc] init];
		cityDownloadsPending     = 0;
		redrawOnly               = NO;
		menuBarLoadTimer         = nil;
        statusItem               = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
		boldFont                 = [[[NSFontManager sharedFontManager] convertFont:[NSFont menuFontOfSize:ATTR_FONT_SIZE]
																	  toHaveTrait:NSBoldFontMask] retain];
		unboldFont               = [[NSFont menuFontOfSize:ATTR_FONT_SIZE] retain];
        [statusItem setHighlightMode:YES]; // status item highlights when clicked
		[statusItem setMenu:menu];
		
		mainCity = nil;

		[CURLHandle curlHelloSignature:@"XxXx" acceptAll:YES];	// to get CURLHandle registered for handling URLs

		[[MEPlug_inManager defaultManager] discoverPlugIns]; // loads Weather.com, Wunderground, etc.
		if ([[[MEPlug_inManager defaultManager] moduleNames] count] == 0)
		{
			// oops, no plugins found!  Tell user & quit!
			NSRunAlertPanel(NSLocalizedString(@"No Weather Plugins Found!",@""),
							NSLocalizedString(@"Meteorologist was unable to find any weather plugins.  Please reinstall Meteoroligst.\n\nMeteorologist will now quit.",@""),NSLocalizedString(@"OK",@""),nil,nil);
			[NSApp terminate:nil];
		}
		
		// sets up the preferences window //
		[NSPreferences setDefaultPreferencesClass:[MSPreferences class]]; 
		NSPreferences* prefs = [NSPreferences sharedPreferences];
		[prefs addPreferenceNamed:@"General"        owner:[MEGeneralPreferencesModule sharedInstance]];
		[prefs addPreferenceNamed:@"Cities"         owner:[MECityPreferencesModule sharedInstance]];
		[prefs addPreferenceNamed:@"Appearance"     owner:[MEAppearancePreferencesModule sharedInstance]];
		[prefs addPreferenceNamed:@"Weather Alerts" owner:[MEWeatherAlertsPreferencesModule sharedInstance]];
		
		// register for notifications //
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cityHasFinishedUpdatingWeather:) 
													 name:@"METhreadedServerDataAcquired" object:nil]; 
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tellCityToUpdateWeatherReport:) 
													 name:@"MECityUpdate" object:nil]; 
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reestablishAutomaticUpdateTimer)
													 name:@"MEReestablishAutoUpdateTimer" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reestablishAutomaticRotateTimer)
													 name:@"MEReestablishAutoRotateTimer" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redrawMenu) 
													 name:@"MERedrawMenu" object:nil]; 
		
		// register for Network Level System changes so we know when to update //
		systemConfigNotificationManager = [[IXSCNotificationManager alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(newNetworkConfiguration:) 
													 name:@"State:/Network/Global/IPv4" 
												   object:systemConfigNotificationManager];
	}
	return self;
}

- (void)awakeFromNib
{
	[[MEAppearancePreferencesModule sharedInstance] initializeFromDefaults];
    if([[MEAppearancePreferencesModule sharedInstance] isInMenu])
    {
		NSMutableDictionary *menuAttributes = [NSMutableDictionary dictionary];
		[menuAttributes setObject:[NSFont fontWithName:[[MEAppearancePreferencesModule sharedInstance] menuFontName]
												  size:[[MEAppearancePreferencesModule sharedInstance] menuFontSize]] 
						   forKey:NSFontAttributeName];
		[menuAttributes setObject:[[MEAppearancePreferencesModule sharedInstance] menuTextColor]
						   forKey:NSForegroundColorAttributeName];		
        [statusItem setTitle:@"Starting..."];
		[statusItem setAttributedTitle:[[[NSAttributedString alloc] initWithString:[statusItem title] attributes:menuAttributes] autorelease]];

		[statusItem setImage:[[[NSImage alloc] 
             initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16"
																	ofType:@"tiff"]] autorelease]];
		[menu addItemWithTitle:@"Please wait while Meteo fetches the weather" action:nil keyEquivalent:@""]; // un-selectable
		[self addControlMenuItemsToMenu:menu];
	}	
	
	// Setup about window
	NSString *thisVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; // Get the application bundle version
	if (versionNumber && thisVersion)
		[versionNumber setStringValue:thisVersion];
	
	if (meteoURLButton && [meteoURLButton respondsToSelector:@selector(setAttributedTitle:)])
	{
		NSDictionary *blueUnderlineAttributes = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor blueColor],NSForegroundColorAttributeName,
				[NSNumber numberWithInt:1],NSUnderlineStyleAttributeName,
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,nil];		
		
		[meteoURLButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:[meteoURLButton title]
																			attributes:blueUnderlineAttributes]
			autorelease]];
		[CURLHandleURLButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:[CURLHandleURLButton title]
																			attributes:blueUnderlineAttributes]
			autorelease]];
		[AGKitURLButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:[AGKitURLButton title]
																			attributes:blueUnderlineAttributes]
			autorelease]];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)not
{
	
	[self updateLocalImages]; // downloads images for the program if necessary.
	
	if ([NSApp isHidden]) // fixes a bug where Meteo wasn't selected if it was a hidden startup item
		[NSApp unhideWithoutActivation];

	// as of 2.0 got rid of option to have multiple meteos 
//	if ([[[[NSWorkspace sharedWorkspace] launchedApplications] 
//                    valueForKey:@"NSApplicationName"] containsObject:@"Meteorologist"])
//		[NSApp terminate:nil];
	
	[[MECityPreferencesModule sharedInstance] discoverCities];
	NSArray *cities = [[MECityPreferencesModule sharedInstance] cities];
	if([cities count] == 0)
	{
		[self showPreferencesWindow:nil];
		[[MECityPreferencesModule sharedInstance] addNewCity];
	}
	//[[MEAppearancePreferencesModule sharedInstance] initializeFromDefaults];
	[self generateMenu];
	[self reestablishTimers];
	[self tellCitiesToUpdateWeatherReports];
}

#pragma mark -

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#ifdef DEBUG
	NSLog(@"Meteo is terminating.");
#endif
	[CURLHandle curlGoodbye];	// to clean up CURL
}

- (void)updateLocalImages
{
    BOOL needRequest = YES;
	NSString     *xmlPath    = [[NSBundle mainBundle] pathForResource:@"meteo" ofType:@"xml"];
	NSDictionary *moduleDict = [NSDictionary dictionaryWithContentsOfFile:xmlPath];
	NSArray		 *imageArray = [moduleDict objectForKey:@"imageFiles"];
	
    NSEnumerator *imageEnum = [imageArray objectEnumerator];
    NSString *next;
    
    NSString *base             = @"http://heat-meteo.sourceforge.net/images/icons/";
    NSString *globalAppSupport = @"/Library/Application Support/Meteo/";
	NSString *userAppSupport   = [@"~/Library/Application Support/Meteo/" stringByExpandingTildeInPath];
	NSArray  *directories      = [NSArray arrayWithObjects:globalAppSupport,userAppSupport,nil];
	NSString *workingDirectory = globalAppSupport;
	NSEnumerator *itr          = [directories objectEnumerator];
    NSFileManager *man = [NSFileManager defaultManager];
 
	while(workingDirectory = [itr nextObject])
	{
		[man createDirectoryAtPath:workingDirectory attributes:nil];
		if([man fileExistsAtPath:workingDirectory]) // fails if user didn't have permission to create this directory.
			break;
	}
    
	itr = [directories objectEnumerator]; // reset
	while(workingDirectory = [itr nextObject])
	{
		[man createDirectoryAtPath:[NSString stringWithFormat:@"%@Menu Bar Icons",workingDirectory] attributes:nil];
		if([man fileExistsAtPath:workingDirectory]) // make sure we can create the new directory
			break;
	}
	if (workingDirectory)
		localImagesPath = [workingDirectory copy];
	// at this point we know we can write within "workingDirectory"
    [man createDirectoryAtPath:[NSString stringWithFormat:@"%@Dock Icons",workingDirectory] attributes:nil];
    [man createDirectoryAtPath:[NSString stringWithFormat:@"%@Dock Icons/Moon Phase",workingDirectory] attributes:nil];
    [man createDirectoryAtPath:[NSString stringWithFormat:@"%@Dock Icons/Television",workingDirectory] attributes:nil];
    [man createDirectoryAtPath:[NSString stringWithFormat:@"%@Dock Icons/Temperature",workingDirectory] attributes:nil];
    [man createDirectoryAtPath:[NSString stringWithFormat:@"%@Dock Icons/Weather Status",workingDirectory] attributes:nil];
    
    BOOL runAgain = NO;
    
    while(next = [imageEnum nextObject])
    {
        if(![man fileExistsAtPath:[NSString stringWithFormat:@"%@%@",workingDirectory,next]])
        {
            if(needRequest)
            {
                [NSApp activateIgnoringOtherApps:YES];
				
                int res = NSRunAlertPanel(@"You're missing some local icons!",
										  @"The icons for Meteorologist are no longer stored inside of Meteo - now they reside in /Library/Application Support/Meteo.  Would you like Meteo to go and fetch these icons now off my server?",
										  @"Yes",
										  @"Later",
										  nil);
                if(!res)
                    return;
                else
                {
                    [downloadWindowProgress setUsesThreadedAnimation:YES];
                    [downloadWindowProgress setDoubleValue:0];
                    [downloadWindow center];
                    [downloadWindow makeKeyAndOrderFront:nil];
                    needRequest = NO;
                }
            }
            
            NSString *imgStr = [NSString stringWithFormat:@"%@%@",base,next];
            imgStr = [[imgStr componentsSeparatedByString:@" "] componentsJoinedByString:@"%20"];
            NSData *dat = [[MEWebFetcher sharedInstance] fetchURLtoData:[NSURL URLWithString:imgStr] 
															withTimeout:5];
            
            if(dat)
            {
                [downloadWindowName setStringValue:
					[NSString stringWithFormat:@"Image Name: %@",[next lastPathComponent]]];
                [downloadWindowName display];
                
                [downloadWindowSize setStringValue:
					[NSString stringWithFormat:@"Image Size: %d (bytes)",[dat length]]];
                [downloadWindowSize display];
				
                [downloadWindowImage setImage:[[[NSImage alloc] initWithData:dat] autorelease]];
                [downloadWindowImage display];
                
                if(![dat writeToFile:[NSString stringWithFormat:@"%@%@",workingDirectory,next] atomically:NO])
                    dat = nil;
			}
            else // this might be repetitive
            {
                //error message
                runAgain = NSRunAlertPanel(@"Download Error!",[NSString stringWithFormat:@"There seems to be a problem downloading %@.  Make sure that your internet connection is active and that the folder /Library/Application Support/Meteo is writable.  Would you like to try downloading again?",next],@"Yes",@"Later",nil);
                
                break;
            }
        }
        
        [downloadWindowProgress incrementBy:100.0/[imageArray count]];
        [downloadWindowProgress display];
    }
    
    [downloadWindowProgress setDoubleValue:100.0];
    [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:2.0]];
    [downloadWindow orderOut:nil];
    
    if(runAgain)
    {
        [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:1.0]];
        [self updateLocalImages];
    }
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return menu;
}

#pragma mark IBActions

- (void)showPreferencesWindow:(id)sender
{
  	[[NSPreferences sharedPreferences] showPreferencesPanel];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)showAboutWindow:(id)sender
{
	if (aboutWindow)
	{
		[aboutWindow makeKeyAndOrderFront:nil];
		NSLog(@"About..");	
	}
}

// called by the Refresh MenuItem and the Update Now button
- (IBAction)refreshCallback:(id)sender
{
	NSLog(@"Refresh Callback");

	[self reestablishAutomaticUpdateTimer]; // stops the current timer if it is "waiting."
	[self tellCitiesToUpdateWeatherReports]; // threaded, calls posts notification to generateMenu
}


#pragma mark Load/Rotate Timers

- (void)reestablishAutomaticUpdateTimer
{
	int minTillUpdate;

	if (automaticUpdateTimer)
	{
		[automaticUpdateTimer invalidate];
		[automaticUpdateTimer release];
		automaticUpdateTimer = nil;
	}
	
	if([[MEGeneralPreferencesModule sharedInstance] updatesAutomatically])
    {
		minTillUpdate = [[MEGeneralPreferencesModule sharedInstance] automaticUpdateTime];
		NSCalendarDate *now = [NSCalendarDate calendarDate];
		if (nextUpdate)
			[nextUpdate release];
		nextUpdate = [[now dateByAddingYears:0 months:0 days:0 hours:0 minutes:minTillUpdate seconds:0] retain];
#ifdef DEBUG
		NSLog(@"Next update: %@",nextUpdate);
#endif
        automaticUpdateTimer     = [[NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
																	 target: self
																   selector:@selector(downloadNewDataTimerFired) 
																   userInfo:nil 
																	repeats:YES] retain];
    }
}

- (void)reestablishAutomaticRotateTimer
{
	int minTillUpdate;

	if (automaticRotateTimer)
	{
		[automaticRotateTimer invalidate];		
		[automaticRotateTimer release];	
		automaticRotateTimer = nil;
	}
	
	if([[MEGeneralPreferencesModule sharedInstance] rotatesAutomatically])
    {
        minTillUpdate = [[MEGeneralPreferencesModule sharedInstance] automaticRotateTime];
        automaticRotateTimer = [[NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
																 target: self
															   selector:@selector(rotateCitiesTimerFired) 
															   userInfo:nil 
																repeats:YES] retain];
    }
}

- (void)reestablishTimers
{
	[self reestablishAutomaticUpdateTimer];
	[self reestablishAutomaticRotateTimer];
}

#pragma mark Timer callbacks

- (void)downloadNewDataTimerFired
{
//	NSCalendarDate *now = [NSCalendarDate calendarDate];
//	NSLog(@"- (void)downloadNewDataTimerFired at %@",now);

	[self tellCitiesToUpdateWeatherReports];// threaded, posts notification to generateMenu
}

- (void)rotateCitiesTimerFired
{
//	NSLog(@"- (void)rotateCitiesTimerFired");

	// choose a new main city
	NSArray *theActiveCities = [self activeCities];
	NSMutableArray *theCities = [self cities];
	MECity  *aCity;
	
	if([theActiveCities count] > 0)
	{
		while (YES)
		{
			// remove the first city and place it at the end of the array
			aCity = [theCities objectAtIndex:0];
			[aCity retain];
			[theCities removeObjectAtIndex:0]; 
			[theCities addObject:aCity];

			// if it was an active city, then break.  otherwise, loop until we find an activeCity
			if ([aCity isActive])
			{			
				[aCity release];
				break;
			}
			[aCity release];
		}		
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"MECityOrderingChanged" object:nil];

	[self redrawMenu];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MEAutoRotateComplete" object:nil];
}

#pragma mark Menu Drawing Methods
- (void)noteNewServerData:(NSNotification*)not
{
	[self generateMenu];
}

// this method is called by appearance prefs whenever a change is made (through a notification)
//   it redraws the menu using stale radar image data (redrawOnly variable lets it know).
- (void)redrawMenu
{
	redrawOnly = YES;
	[self generateMenu];
	redrawOnly = NO;
}

- (NSString *)statusItemTitleForCurrentState 
{
	//NSString *statusItemTitle;
	int activeCities = [[self activeCities] count];
	
	//--------------- NO Active Cities ---------------        
    if(activeCities == 0) {		
		return @"No Weather";
	}
	else {
		return @"";
	}
	return @"";
}

- (NSImage *)statusItemImageForCurrentState
{
	NSImage *theCityImage = nil;
	int activeCities = [[self activeCities] count];
	
	if([[MEAppearancePreferencesModule sharedInstance] displayIcon] && mainCity)
	{
		// JRC - here is where the menu icon is determined
		theCityImage = [mainCity imageForKey:@"Weather Image"
											 size:16
										 imageDir:localImagesPath];
		if (theCityImage)
			return theCityImage;
	} // if there was an error loading the weather image, then cityImage could be nil still

	if((![[MEAppearancePreferencesModule sharedInstance] displayCityName] && 
	    ![[MEAppearancePreferencesModule sharedInstance] displayTemp] && 
	    ![[MEAppearancePreferencesModule sharedInstance] displayIcon]) ||
	   ([[MEAppearancePreferencesModule sharedInstance] displayIcon] && theCityImage == nil) ||
	   (activeCities == 0))
	{
		theCityImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16" ofType:@"tiff"]] autorelease];
	}
	return theCityImage; // might be nil
}

- (void)generateMenu
{
	[menuDrawLock lock];
	
	// check to see if there was an error downloading.
	if (![[[MEWebFetcher sharedInstance] errorMessage] isEqualToString:@"none"] && // there was an error downloading.
		statusItem && ![[statusItem title] isEqualToString:@"Starting..."] && // if starting, must draw menu first time
		[[self activeCities] count] > 0) // first run this loop was being entered accidentally
	{
		if ([menu numberOfItems] > 0) // then the menu already exists in some form.
		{
			NSString *errorTitle = @"Unable to connect to weather servers.";
			if ([menu indexOfItemWithTitle:errorTitle] == -1) // error message not yet in menu
			{
				NSMenuItem *errorMI = [[[NSMenuItem alloc] initWithTitle:errorTitle
																  action:NULL
														   keyEquivalent:@""] autorelease];
				[menu insertItem:[NSMenuItem separatorItem] atIndex:0];
				[menu insertItem:errorMI atIndex:0];
			}
			
			// i'd also like to put a "?" overtop of the status item image
			NSString *quesMark = @"?";
			NSImage *currImg   = [statusItem image];
			if (currImg == nil)
			{
				currImg = [[[NSImage alloc] 
                      initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16"
																			 ofType:@"tiff"]] autorelease];
				[statusItem setImage:currImg];
				if (!currImg)
					currImg = [NSImage imageNamed:@"meteo"];
			}
			
			NSImage *newImg    = [[NSImage alloc] initWithSize:[currImg size]];
			NSFont *displayFont = [NSFont fontWithName:@"Arial Black" size:20];
			if (!displayFont)
				displayFont = [NSFont boldSystemFontOfSize:22];
//			NSDictionary *displayAttributes = [NSDictionary dictionaryWithObject:displayFont forKey:NSFontAttributeName];
			NSMutableAttributedString *attrMenuItemTitle = [[NSMutableAttributedString alloc] 
																initWithString:quesMark];
			[attrMenuItemTitle addAttribute:NSFontAttributeName value:displayFont range:NSMakeRange(0,[quesMark length])];

			// convert old image to grayscale
//			IAGrayscaleFilter *filter = [[IAGrayscaleFilter alloc] init];
//			newImg = [[filter filterImage:currImg] retain];
			
			[newImg setFlipped:YES];
			[newImg lockFocus];
			
			[currImg compositeToPoint:NSMakePoint(0, [currImg size].height)
							operation:NSCompositeSourceOver];
			[attrMenuItemTitle drawAtPoint:NSMakePoint(([currImg size].width - [attrMenuItemTitle size].width) / 2.0, 
													   ([currImg size].height - [attrMenuItemTitle size].height) / 2.0)];
			
			[newImg unlockFocus];
			[statusItem setImage:newImg];
			
//			[filter release];
			[attrMenuItemTitle release];
			[newImg release];
		}
		[menuDrawLock unlock];
		return;
	}
	
	// successfully downloaded weather data, so redraw
	[menu release];     
	menu = [[NSMenu alloc] init];// easiest way to "clear" the menu
	[menu setAutoenablesItems:YES];
    
    NSString *statusTitle = nil;
    NSImage  *theCityImage = nil;
//    NSString *linkString = nil;
       
    NSMutableDictionary *menuAttributes = [NSMutableDictionary dictionary];
    [menuAttributes setObject:[NSFont fontWithName:[[MEAppearancePreferencesModule sharedInstance] menuFontName]
											  size:[[MEAppearancePreferencesModule sharedInstance] menuFontSize]] 
					   forKey:NSFontAttributeName];
    [menuAttributes setObject:[[MEAppearancePreferencesModule sharedInstance] menuTextColor]
					   forKey:NSForegroundColorAttributeName];
    
	int activeCities = [[self activeCities] count];

//--------------- NO Active Cities ---------------        
    if(activeCities == 0)
    {
        [menu addItemWithTitle:NSLocalizedString(@"No Active Cities",@"") 
						action:nil
				 keyEquivalent:@""];
        
        if([[MEAppearancePreferencesModule sharedInstance] isInMenu])
        {
            statusTitle = nil;
        
            if([[MEAppearancePreferencesModule sharedInstance] displayCityName])
                statusTitle = NSLocalizedString(@"No Weather",@"");
            else
                statusTitle = @"";

			theCityImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16" ofType:@"tiff"]] autorelease];
			
			[statusItem setAttributedTitle:[[[NSAttributedString alloc] initWithString:statusTitle attributes:menuAttributes] autorelease]];
			[statusItem setImage:theCityImage]; // JRC set/unset image (if the image is nil, then its unset)
			[statusItem setMenu:menu];
        }
        
        if([[MEAppearancePreferencesModule sharedInstance] isInDock])
        {
            NSImage *theCityImage = [NSImage imageNamed:@"meteo"];
            [NSApp setApplicationIconImage:theCityImage];
        }
    }
//-----------------------------------------------
    else // there is at least one active city
    {
		mainCity = [[self activeCities] objectAtIndex:0];
        MECity *city = mainCity;
		
	//--------------- City Name appearing at top of the Menu ---------------        
		MEMenuItem *theCityItem = [[[MEMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Weather for \"%@\"",[city cityName]]
															  action:NULL 
													   keyEquivalent:@""] autorelease];
//        linkString = [city stringForKey:@"Weather Link"];
//		
//        if(linkString)
//        {
//            [theCityItem setLink:linkString];
//            [theCityItem setAction:@selector(launchURL:)];
//        }
		[menu addItem:theCityItem];

	//----------------------------------------------------------------------
		[self addCurrentAndForecastDataToMenu:menu forCity:city];
        
		[self addNonMainCitiesToMenu:menu];

	//------------------ Determine what the Status Item will look like.---------------------
        if([[MEAppearancePreferencesModule sharedInstance] isInMenu])
        {
            statusTitle = [NSString string];
        
            if([[MEAppearancePreferencesModule sharedInstance] displayCityName])
                statusTitle = [city cityName];
                
            if([[MEAppearancePreferencesModule sharedInstance] displayTemp])
            {
                NSString *temp = [city stringForKey:@"Temperature"];
				
                if(temp)
                {
                    if([statusTitle length] > 0)
                        statusTitle = [NSString stringWithFormat:@"%@ %@",statusTitle,temp];
                    else
                        statusTitle = temp;
                }
            }
                
            if([[MEAppearancePreferencesModule sharedInstance] displayIcon])
			{
                 // JRC - here is where the menu icon is determined
                theCityImage = [city imageForKey:@"Weather Image"
											size:16
										imageDir:localImagesPath];
			}
            else
                theCityImage = nil;
                                                                        
            if(![[MEAppearancePreferencesModule sharedInstance] displayCityName] && 
			   ![[MEAppearancePreferencesModule sharedInstance] displayTemp] && 
			   ![[MEAppearancePreferencesModule sharedInstance] displayIcon])
            {
                theCityImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16" ofType:@"tiff"]] autorelease];
				if (!theCityImage)
					statusTitle = @"Meteo";
            }
			
			if(([[statusItem title] isEqualToString:@""] || ![statusItem title]) && ![statusItem image])
			{
				if([[MEAppearancePreferencesModule sharedInstance] displayCityName])
					statusTitle = NSLocalizedString(@"No Weather",@"");
				else
					statusTitle = @"";
				theCityImage=nil;
			}
			else if ([[MEAppearancePreferencesModule sharedInstance] displayIcon] && theCityImage == nil) 
			{
				theCityImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meteo16x16" ofType:@"tiff"]] autorelease];
			}
			
			[statusItem setAttributedTitle:[[[NSAttributedString alloc] initWithString:statusTitle attributes:menuAttributes] autorelease]];
			[statusItem setImage:theCityImage]; // JRC set/unset image (if the image is nil, then its unset)
			[statusItem setMenu:menu];
        }
	//------------------------------------------------------------------------------
       
        if([[MEAppearancePreferencesModule sharedInstance] isInDock])
        {
            [self updateDock];
        }
    }

    // now add Last Update
	NSString   *lastUpdateStr = [self relativeDateStringForDate:lastUpdate];
	NSMenuItem *lastUpdateMI;
	
	if (lastUpdateStr)
		lastUpdateStr = [NSString stringWithFormat:NSLocalizedString(@"Last Update: %@",@""),lastUpdateStr];
	else
		lastUpdateStr = NSLocalizedString(@"Last Update: Never",@"");
	
	lastUpdateMI  = [[[NSMenuItem alloc] initWithTitle:lastUpdateStr 
												action:NULL
										 keyEquivalent:@""] autorelease];
	
	if ([lastUpdateMI respondsToSelector:@selector(setAttributedTitle:)])
	{
		NSMutableAttributedString *attrLastUpdateStr = [[[NSMutableAttributedString alloc] 
															initWithString:lastUpdateStr
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:unboldFont,NSFontAttributeName,nil]] autorelease];
		[lastUpdateMI setAttributedTitle:attrLastUpdateStr];
		
	}
	[menu addItem:[NSMenuItem separatorItem]];		
	[menu addItem:lastUpdateMI];
	
	if ([[MEGeneralPreferencesModule sharedInstance] showNextUpdateTime])
	{
		NSString   *nextUpdateStr = [self relativeDateStringForDate:nextUpdate];
		NSMenuItem *nextUpdateMI;
		if (nextUpdateStr)
		{
			nextUpdateStr = [NSString stringWithFormat:@"Next Update: %@",nextUpdateStr];
			
			nextUpdateMI = [[[NSMenuItem alloc] initWithTitle:nextUpdateStr 
													   action:NULL
												keyEquivalent:@""] autorelease];
			
			if ([nextUpdateMI respondsToSelector:@selector(setAttributedTitle:)])
			{
				NSMutableAttributedString *attrNextUpdateStr = [[[NSMutableAttributedString alloc] 
															initWithString:nextUpdateStr
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:unboldFont,NSFontAttributeName,nil]] autorelease];
				[nextUpdateMI setAttributedTitle:attrNextUpdateStr];
			}
			[menu addItem:nextUpdateMI];
		}
	}
	// Now add Refresh, Preferences, and Quit
	[self addControlMenuItemsToMenu:menu];
    
	[menuDrawLock unlock];
}

- (void)addControlMenuItemsToMenu:(NSMenu *)aMenu
{
	NSMenuItem *aboutMI;
	refreshMI = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Refresh",@"") 
											action:@selector(refreshCallback:) 
									 keyEquivalent:@""] autorelease];
	
    preferencesMI = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Preferences...",@"") 
												action:@selector(showPreferencesWindow:) 
										 keyEquivalent:@""] autorelease];
	
	aboutMI = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"About...",@"")
										  action:@selector(showAboutWindow:)
								   keyEquivalent:@""] autorelease];
	
    quitMI = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quit",@"") 
										 action:@selector(terminate:) 
								  keyEquivalent:@""] autorelease];

	if ([self activeCities] > 0)
		[refreshMI setTarget:self];    
	else
		[refreshMI setTarget:nil]; // disables MenuItem

	[preferencesMI setTarget:self];
	[aboutMI setTarget:self];
	[quitMI setTarget:NSApp];	
	
	[aMenu addItem:[NSMenuItem separatorItem]];
	[aMenu addItem:refreshMI];
	[aMenu addItem:preferencesMI];
	[aMenu addItem:aboutMI];	
	[aMenu addItem:[NSMenuItem separatorItem]];	
	[aMenu addItem:quitMI];
}

#pragma mark -

- (void)addString:(NSString *)string toMenu:(NSMenu *)theMenu withCharacterWidth:(int)width
{
	NSMenuItem *newMI = [[[NSMenuItem alloc] initWithTitle:string action:@selector(dummy:) keyEquivalent:@""] autorelease];
	[newMI setTarget:self];
	[theMenu addItem:newMI];
	return;
	
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSEnumerator *compEnum = [components objectEnumerator];
    
    NSString *subStr = nil;
    NSString *spaceStr = nil;
    NSString *sub;
    int count = -1;
    
    int subWidth = width;
    
    while(sub = [compEnum nextObject])
    {
        count+=[sub length]+1;
        
        if(count < subWidth)
        {
            if(!subStr)
                subStr = sub;
            else
                subStr = [NSString stringWithFormat:@"%@ %@",subStr,sub];
        }
        else
        {
            if(spaceStr)
                subStr = [NSString stringWithFormat:@"%@%@",spaceStr,subStr];
        
            if(subStr)
                [[theMenu addItemWithTitle:subStr action:@selector(dummy:) keyEquivalent:@""] setTarget:self];
            
            if(!spaceStr)
            {
                float numWidth = [[components objectAtIndex:0] sizeWithAttributes:nil].width;
                
                spaceStr = @" ";
                while([spaceStr sizeWithAttributes:nil].width < numWidth)
                {
                    spaceStr = [NSString stringWithFormat:@"%@ ",spaceStr];
                    subWidth--;
                }
                
                subWidth-=2;
            }
            
            subStr = sub;
            count = [sub length];
        }
    }
    
    if(subStr)
    {
        if(spaceStr)
                subStr = [NSString stringWithFormat:@"%@%@",spaceStr,subStr];
    
        [[theMenu addItemWithTitle:subStr action:@selector(dummy:) keyEquivalent:@""] setTarget:self];
    }
}

#pragma mark -

// for OS versions >=  10.3 (those that support -[NSMenuItem setAttributedTitle])
- (void)addCurrentWeatherDataToMenuGTE10_3:(NSMenu *)theMenu forCity:(MECity *)city
{
	NSArray					   *weatherProperties = [[MEAppearancePreferencesModule sharedInstance] activeProperties];
	NSEnumerator			   *itr				  = [weatherProperties objectEnumerator];
	NSString				   *nextProp;
	id							nextVal;	
	NSMutableAttributedString  *attrMenuItemTitle;	
	float						headIndent = 0;
	
	NSAssert([[[[NSMenuItem alloc] init] autorelease] respondsToSelector:@selector(setAttributedTitle:)],@"addForecastDataToMenu10_3 improperly");
	
//	NSLog(@"%@: %@",[city cityName],weatherProperties);
	
	// preprocess to determine where to place tabs.
	while (nextProp = [itr nextObject])
	{
		NSAttributedString *label = [[[NSAttributedString alloc] 
										initWithString:[NSString stringWithFormat:@"%@:",nextProp]
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:boldFont,NSFontAttributeName,nil]] autorelease];
		if (label)
			headIndent = MAX(headIndent,[label size].width);
	}
	
	
	itr = [weatherProperties objectEnumerator]; // reset
	
	while (nextProp = [itr nextObject])
	{
		NSMutableParagraphStyle *NPStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[NPStyle setTabStops:[NSArray array]]; // delete default tabs

		if (!nextProp) 
		{			
			NSLog(@"The weather report for city: %@ was missing the attribute: %@",[city cityName],nextProp);
			continue;
		}
		
		nextVal = [city stringForKey:nextProp];
		
		if([nextProp isEqualToString:@"Weather Alert"])
		{
			NSLog(@"Inside weather alert case (MEController)");
			if(nextVal) 
			{
				//[alertManager addCity:city];
				// Add "Weather Alerts ->" to theMenu (wAlertMI)
				NSMenuItem *wAlertMI = [[[NSMenuItem alloc] initWithTitle:@"Weather Alerts" action:NULL keyEquivalent:@""] autorelease];
				
				// setup attributed title
				attrMenuItemTitle = [[[NSMutableAttributedString alloc] 
                                        initWithString:@"\tWeather Alerts:"] autorelease];
				// two tabs
				[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSRightTabStopType location:headIndent+25] autorelease]];
				[attrMenuItemTitle addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0,16)]; // length of "Weather Alerts:"
				[attrMenuItemTitle addAttribute:NSParagraphStyleAttributeName value:NPStyle range:NSMakeRange(0,[attrMenuItemTitle length])];
				
				[wAlertMI setAttributedTitle:attrMenuItemTitle];
				[theMenu addItem:wAlertMI];
				
				// create and attach a new Menu for wAlertMI
				NSMenu *anotherSub = [[[NSMenu alloc] init] autorelease];				
				[wAlertMI setSubmenu:anotherSub];
				
				// the weather alert is an array of dictionaries with keys: title, description 
				NSEnumerator *arrayEnum = [nextVal objectEnumerator];
				NSDictionary *nextDict;
				
				while(nextDict = [arrayEnum nextObject])
				{					
					NSString *alertTitle     = [nextDict objectForKey:@"title"];
					NSString *alertDesc      = [nextDict objectForKey:@"description"];
					NSString *alertURLString = [nextDict objectForKey:@"url"];
					
					MEMenuItem *alertMI = [[[MEMenuItem alloc] initWithTitle:alertTitle
																	  action:NULL
															   keyEquivalent:@""] autorelease];
					
					[alertMI setLink:alertURLString];
					[alertMI setAction:@selector(launchURL:)];
					
					[anotherSub addItem:alertMI];
					
					[alertManager createAlertForCity:city 
										   withTitle:alertTitle
									 withDescription:alertDesc
									   withURLString:alertURLString];
				} //while	
				[alertManager addCity:city];
			} // nextVal != nil
			else
			{
				[alertManager removeCity:city];
			}
		} // @end: nextProp == "Weather Alert"
		else if([nextProp isEqualToString:@"Radar Image"] && nextVal != nil)
		{
			NSImage *radarImage;
			if (redrawOnly) // do not need to re-download the radar image
			{
				radarImage = [city radarImage];
			}
			else
			{
				if ([city usesCustomRadarImage] && [city customRadarImageURL])
					nextVal = [city customRadarImageURL];
				NSData *imageData = [[MEWebFetcher sharedInstance] fetchURLtoData:[NSURL URLWithString:[nextVal description]]];
				if(imageData)
				{
					radarImage = [[[NSImage alloc] initWithData:imageData] autorelease];
					[city setRadarImage:radarImage];
				}
			}

			if(radarImage)
			{				
				// create and add "Radar Image ->" to theMenu 
				NSMenuItem *radarImgMI = [[NSMenuItem alloc] initWithTitle:@"Radar Image:" action:NULL keyEquivalent:@""];
				[radarImgMI setTarget:nil];
				
				// setup attributed title
				attrMenuItemTitle = [[[NSMutableAttributedString alloc] 
									initWithString:@"\tRadar Image:"] autorelease];
				// one tab
				[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSRightTabStopType location:headIndent+25] autorelease]];
				[attrMenuItemTitle addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0,[attrMenuItemTitle length])]; // length of "Radar Image"
				[attrMenuItemTitle addAttribute:NSParagraphStyleAttributeName value:NPStyle range:NSMakeRange(0,[attrMenuItemTitle length])];
				
				[radarImgMI setAttributedTitle:attrMenuItemTitle];

				[theMenu addItem:radarImgMI];
				
				NSMenu *radarImgSub = [[[NSMenu alloc] init] autorelease];
				[radarImgMI setSubmenu:radarImgSub];
				
				NSMenuItem *imgMI = [[[NSMenuItem alloc] initWithTitle:@"" action:@selector(dummy:) keyEquivalent:@""] autorelease];
				[imgMI setTarget:self];
				[imgMI setImage:radarImage];
				
				[radarImgSub addItem:imgMI];					
			}
		} // @end: nextProp == "Radar Image" && nextValue != nil
		else if (nextVal != nil)
		{
			NSString *nextTitle = [NSString stringWithFormat:@"\t%@:\t%@",nextProp,nextVal];
			NSMenuItem *nextMI  = [[[NSMenuItem alloc] initWithTitle:nextTitle 
															   action:@selector(dummy:) 
														keyEquivalent:@""] autorelease];
			
			// setup attributed title
			attrMenuItemTitle = [[[NSMutableAttributedString alloc] 
                                        initWithString:nextTitle] autorelease];
			// two tabs
			[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSRightTabStopType location:headIndent+25] autorelease]];
			[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:headIndent+35] autorelease]];
			[attrMenuItemTitle addAttribute:NSFontAttributeName value:boldFont
									  range:NSMakeRange(0,[nextProp length]+2)]; 
			[attrMenuItemTitle addAttribute:NSFontAttributeName value:unboldFont 
									  range:NSMakeRange([nextProp length]+2,[attrMenuItemTitle length]-([nextProp length]+2))]; // rest of it
			[attrMenuItemTitle addAttribute:NSParagraphStyleAttributeName value:NPStyle range:NSMakeRange(0,[attrMenuItemTitle length])];
			
			[nextMI setAttributedTitle:attrMenuItemTitle];
			[theMenu addItem:nextMI];
			
		//	[self addString:nextTitle toMenu:theMenu withCharacterWidth:75];
		} // nextVal != nil
		else
		{
#ifdef NSDEBUG
			NSLog(@"nextVal was nil for property: %@",nextProp);
#endif
		}
	} // nextAttribute = [itr nextObject]	
}

// for OS versions <  10.3 (those that don't support -[NSMenuItem setAttributedTitle])
- (void)addCurrentWeatherDataToMenuLT10_3:(NSMenu *)theMenu forCity:(MECity *)city
{
	NSArray		 *weatherProperties = [[MEAppearancePreferencesModule sharedInstance] activeProperties];
	NSEnumerator *itr = [weatherProperties objectEnumerator];
	NSString     *nextProp;
	id			  nextVal;	
	
	while (nextProp = [itr nextObject])
	{
		if (!nextProp) 
		{			
			NSLog(@"The weather report for city: %@ was missing the attribute: %@",[city cityName],nextProp);
			continue;
		}
			
		nextVal = [city stringForKey:nextProp];
		
		if([nextProp isEqualToString:@"Weather Alert"])
		{
			if(!nextVal) // update the alertManager information for this city
				[alertManager removeCity:city];
			else
			{
				[alertManager addCity:[NSArray arrayWithObjects:city,nextVal/*,prefsController*/,nil]];
				// Add "Weather Alerts ->" to theMenu (wAlertMI)
				NSMenuItem *wAlertMI = [[[NSMenuItem alloc] initWithTitle:@"Weather Alerts" action:NULL keyEquivalent:@""] autorelease];
				[theMenu addItem:wAlertMI];
				
				// create and attach a new Menu for wAlertMI
				NSMenu *anotherSub = [[[NSMenu alloc] init] autorelease];				
				[wAlertMI setSubmenu:anotherSub];
				
				// the weather alert is an array of dictionaries with keys: title, description 
				NSEnumerator *arrayEnum = [nextVal objectEnumerator];
				NSDictionary *nextDict;
				
				int i = 0;
				return;
				while(nextDict = [arrayEnum nextObject])
				{
					NSString *dictTitle = [nextDict objectForKey:@"title"];
					NSString *dictDesc = [nextDict objectForKey:@"description"];
					
					if((dictDesc!=nil || dictTitle!=nil) && i!=0)
						[self addString:@"" toMenu:anotherSub withCharacterWidth:75];
					
					if(dictTitle)
						[self addString:dictTitle toMenu:anotherSub withCharacterWidth:75];
					else
						NSLog(@"Weather Alert was missing key: \"title\"");
					if(dictDesc)
						[self addString:dictDesc toMenu:anotherSub withCharacterWidth:75];
					else
						NSLog(@"Weather Alert was missing key: \"description\"");
					
					i++;
				} //while				
			} // nextVal != nil
		} // nextProp == "Weather Alert"
		else if([nextProp isEqualToString:@"Radar Image"] && nextVal != nil)
		{
			NSImage *radarImage;
			if (redrawOnly) // do not need to re-download the radar image
			{
				radarImage = [city radarImage];
			}
			else
			{
				if ([city usesCustomRadarImage] && [city customRadarImageURL])
					nextVal = [city customRadarImageURL];
				NSData *imageData = [[MEWebFetcher sharedInstance] fetchURLtoData:[NSURL URLWithString:[nextVal description]]];
				if (imageData)
				{
					radarImage = [[[NSImage alloc] initWithData:imageData] autorelease];
					[city setRadarImage:radarImage];
				}
			}
			if(radarImage)
			{				
				// create and add "Radar Image ->" to theMenu 
				NSMenuItem *radarImgMI = [[NSMenuItem alloc] initWithTitle:@"Radar Image" action:NULL keyEquivalent:@""];
				[radarImgMI setTarget:nil];
				[theMenu addItem:radarImgMI];
				
				NSMenu *radarImgSub = [[[NSMenu alloc] init] autorelease];
				[radarImgMI setSubmenu:radarImgSub];
				
				NSMenuItem *imgMI = [[[NSMenuItem alloc] initWithTitle:@"" action:@selector(dummy:) keyEquivalent:@""] autorelease];
				[imgMI setTarget:self];
				[imgMI setImage:radarImage];
				
				[radarImgSub addItem:imgMI];					
			}
		} // nextProp == "Radar Image" && nextValue != nil
		else if (nextVal != nil)
		{
			NSString *nextTitle = [NSString stringWithFormat:@"%@: %@",nextProp,nextVal];
			[self addString:nextTitle toMenu:theMenu withCharacterWidth:75];
		} // nextVal != nil
		else
		{
			//NSLog(@"nextVal was nil for property: %@",nextProp);
		}
	} // nextAttribute = [itr nextObject]
}

- (void)addCurrentWeatherDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city
{
	if ([[[[NSMenuItem alloc] init] autorelease] respondsToSelector:@selector(setAttributedTitle:)])
		[self addCurrentWeatherDataToMenuGTE10_3:theMenu forCity:city];
	else
		[self addCurrentWeatherDataToMenuLT10_3:theMenu forCity:city];			
}

#pragma mark -
- (void)addForecastDataForCity:(MECity *)city dayNumber:(int)dayNum toMenu:(NSMenu *)theMenu tabIndent:(float)maxPropertyLabelWidth
{
	NSArray      *forecastProperties = [[MEAppearancePreferencesModule sharedInstance] activeForecastProperties];
	NSEnumerator *itr = [forecastProperties objectEnumerator];
	NSString     *nextProp;

	NSDictionary *optionsDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSUTF8StringEncoding],@"CharacterEncoding",nil];
	
	NSString *fontFace = [unboldFont fontName];

	NSString *html = [NSString stringWithFormat:@"<font face='%@'><table width=300 border=0 cellpadding=1 cellspacing=0>",fontFace];
	
	while (nextProp = [itr nextObject])
	{
		NSString *propertyVal = [[city forecastStringForKey:nextProp forDay:dayNum] description];
		if (propertyVal && [propertyVal length] > 0)
		{
			html = [html stringByAppendingFormat:@"<tr><td align='right' valign='top' width=%i><b>%@:</b></td><td align='left' valign='top'>%@</td></tr>",
				[[NSNumber numberWithFloat:maxPropertyLabelWidth] intValue],nextProp,propertyVal];
		}
	}
	html = [html stringByAppendingString:@"</table></font>"];
	NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithHTML:[html dataUsingEncoding:NSUTF8StringEncoding]
																		   options:optionsDict
																documentAttributes:nil];
	NSMenuItem *dayMenuItem = [[NSMenuItem alloc] initWithTitle:@"dummy"
														 action:NULL
												  keyEquivalent:@""];
	[dayMenuItem setAttributedTitle:attributedTitle];
	[theMenu addItem:dayMenuItem];
				
	// clean up memory //
	[attributedTitle release];
	[dayMenuItem release];
}



#pragma mark -

// for OS versions >=  10.3 (those that support -[NSMenuItem setAttributedTitle])
- (void)addForecastDataToMenuGTE10_3:(NSMenu *)theMenu forCity:(MECity *)city
{
	NSAssert([[[[NSMenuItem alloc] init] autorelease] respondsToSelector:@selector(setAttributedTitle:)],@"addForecastDataToMenu10_3 improperly invoked");
	
	// Start of Method //
	
	// -- Determine the maximum property label with from forecastProperties array //
	NSArray      *forecastProperties = [[MEAppearancePreferencesModule sharedInstance] activeForecastProperties];
	NSEnumerator *itr = [forecastProperties objectEnumerator];
	NSString     *nextProp;
	float         maxPropertyLabelWidth = 0; // important var, calculated below
	
	while (nextProp = [itr nextObject])
	{
		NSAttributedString *label = [[NSAttributedString alloc]
			initWithString:[NSString stringWithFormat:@"%@:",nextProp]
				attributes:[NSDictionary dictionaryWithObjectsAndKeys:boldFont,NSFontAttributeName,nil]];
		
		if (label)
		{
			maxPropertyLabelWidth = MAX(maxPropertyLabelWidth,[label size].width);
			[label release];
		}
	}
	
	int numDays = MIN([[MEAppearancePreferencesModule sharedInstance] numberOfDaysInForecast],[city maxDaysSupported]);
	
	//NSLog(@"number of days: %i",numDays);
	
	// -- Determine the maximum "Day" width //
	// -- Determine the maximum "low" width //
	// -- Determine the maximum "high" width //
	float maxDayNameWidth = 0;
	float maxLowWidth = 0;
	float maxHighWidth = 0;
	
	NSString *localizedDayNameKey = [city localizedForecastKeyForEnglishForecastKey:@"Day"];
	NSString *localizedLowKey     = [city localizedForecastKeyForEnglishForecastKey:@"Low"];
	NSString *localizedHighKey    = [city localizedForecastKeyForEnglishForecastKey:@"High"];

	int i;
	for (i=0; i<numDays; i++)
	{	
		NSAttributedString *dayName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",[[city forecastStringForKey:localizedDayNameKey 
																																		forDay:i] description]]
																	  attributes:[NSDictionary dictionaryWithObjectsAndKeys:boldFont,NSFontAttributeName,nil]];
		NSAttributedString *low     = [[NSAttributedString alloc] initWithString:[[city forecastStringForKey:localizedLowKey forDay:i] description]];
		NSAttributedString *high    = [[NSAttributedString alloc] initWithString:[[city forecastStringForKey:localizedHighKey forDay:i] description]];
		
		if (dayName != nil)
			maxDayNameWidth = MAX(maxDayNameWidth, [dayName size].width);
		if (low != nil)
			maxLowWidth     = MAX(maxLowWidth, [low size].width);
		if (high != nil)
			maxHighWidth    = MAX(maxHighWidth, [high size].width);
		
		// free up memory
		[dayName release];
		[low release];
		[high release];			
	}
	
	// make the menu items //
	float tabPadding = 10;
	NSMutableParagraphStyle *NPStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];	
	[NPStyle setTabStops:[NSArray array]]; // delete default tabs
	[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxDayNameWidth + tabPadding] autorelease]];
	[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxDayNameWidth + tabPadding + maxHighWidth + tabPadding] autorelease]];
	[NPStyle setLineBreakMode:NSLineBreakByWordWrapping];
	
	for (i=0; i<numDays; i++) 
	{
		NSString *dayName  = [[city forecastStringForKey:localizedDayNameKey forDay:i] description];
		NSString *high     = [[city forecastStringForKey:localizedHighKey forDay:i] description];
		NSString *low      = [[city forecastStringForKey:localizedLowKey forDay:i] description];
		if (dayName == nil)
			dayName = @"";
		if (high == nil)
			high = @"";
		if (low == nil)
			low = @"";
		
		NSString *plainTitle = [NSString stringWithFormat:@"%@:\t%@\t%@",dayName,high,low];
		
		plainTitle = [plainTitle stringByTrimmingCharactersInSet:[NSCharacterSet illegalCharacterSet]];
		NSMutableAttributedString *dayMenuTitle = [[NSMutableAttributedString alloc] initWithString:plainTitle
																						 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																							 NPStyle,NSParagraphStyleAttributeName,nil]];
		[dayMenuTitle addAttribute:NSFontAttributeName value:boldFont 
							 range:NSMakeRange(0,[dayName length]+2)];
		
		NSMenuItem *dayMenuItem = [[NSMenuItem alloc] initWithTitle:plainTitle
															 action:NULL
													  keyEquivalent:@""];
		[dayMenuItem setAttributedTitle:dayMenuTitle];
		
		// add image for this day //
		NSImage *icon = [city forecastImageForDay:i imageDir:localImagesPath];
		if (icon)
		{
			[dayMenuItem setImage:icon];
		}
		
		[theMenu addItem:dayMenuItem];
		
		// build up submenu and link it //
		NSMenu *dayForecastMenu = [[NSMenu alloc] init];
		
		[self addForecastDataForCity:city dayNumber:i toMenu:dayForecastMenu tabIndent:maxPropertyLabelWidth];
		
		[dayMenuItem setSubmenu:dayForecastMenu];
		
		// free up allocated memory //
		[dayForecastMenu release];
		[dayMenuItem release];
		[dayMenuTitle release];
	}
}

// for OS versions <  10.3 (those that don't support -[NSMenuItem setAttributedTitle])
- (void)addForecastDataToMenuLT10_3:(NSMenu *)theMenu forCity:(MECity *)city
{

	NSArray      *forecastProperties = [[MEAppearancePreferencesModule sharedInstance] activeForecastProperties];
	NSEnumerator *itr = [forecastProperties objectEnumerator];
	NSString     *nextProp;
	
	NSString        *date;
	NSString        *menuItemTitle;
	
	NSString *localizedDayNameKey = [city localizedForecastKeyForEnglishForecastKey:@"Day"];
	NSString *localizedLowKey     = [city localizedForecastKeyForEnglishForecastKey:@"Low"];
	NSString *localizedHighKey    = [city localizedForecastKeyForEnglishForecastKey:@"High"];
	
	int i;
	int numDays = MIN([[MEAppearancePreferencesModule sharedInstance] numberOfDaysInForecast],[city maxDaysSupported]);
	
	for (i=0; i < numDays; i++)
	{            
		NSString *dayName = [city forecastStringForKey:localizedDayNameKey forDay:i];
		NSString *low     = [city forecastStringForKey:localizedLowKey forDay:i];
		NSString *high    = [city forecastStringForKey:localizedHighKey forDay:i];
		if (dayName == nil)
			dayName = @"";
		if (high == nil)
			high = @"";
		if (low == nil)
			low = @"";
		
		NSString *plainTitle = [NSString stringWithFormat:@"%@: %@/%@",dayName,high,low];
		plainTitle = [plainTitle stringByTrimmingCharactersInSet:[NSCharacterSet illegalCharacterSet]];

		if (date && dayName)
			menuItemTitle = [NSString stringWithFormat:@"%@, %@",dayName,date];

		NSMenuItem *dayMenuItem = [[NSMenuItem alloc] initWithTitle:plainTitle
															 action:NULL
													  keyEquivalent:@""];
		
		// add image for this day //
		NSImage *icon = [city forecastImageForDay:i imageDir:localImagesPath];
		if (icon)
		{
			[dayMenuItem setImage:icon];
		}
		
		[theMenu addItem:dayMenuItem];
		
		// build up submenu and link it //
		NSMenu *dayForecastMenu = [[NSMenu alloc] init];
		
		while (nextProp = [itr nextObject])
		{
			NSString *propertyVal = [[city forecastStringForKey:nextProp forDay:i] description];
			if (propertyVal && [propertyVal length] > 0)
			{
				NSString *menuTitle = [NSString stringWithFormat:@"%@: %@",nextProp,propertyVal];
				NSMenuItem *propMenuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
																	  action:NULL
															   keyEquivalent:@""];
				[dayForecastMenu addItem:propMenuItem];
			}
		}
		
		[dayMenuItem setSubmenu:dayForecastMenu];
	} // for      
}
- (void)addForecastDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city
{
	if ([[[[NSMenuItem alloc] init] autorelease] respondsToSelector:@selector(setAttributedTitle:)])
		[self addForecastDataToMenuGTE10_3:theMenu forCity:city];
	else
		[self addForecastDataToMenuLT10_3:theMenu forCity:city];			
}

#pragma mark -

// called-by: threadedGenerateMenu:
- (void)addCurrentAndForecastDataToMenu:(NSMenu *)theMenu forCity:(MECity *)city
{
	NSMenuItem	*item;
    NSMenu		*tempMenu = theMenu;

	if (![[[MEWebFetcher sharedInstance] errorMessage] isEqualToString:@"none"]) // only first time
		return;
    if([[MEAppearancePreferencesModule sharedInstance] displayCurrentConditionsInSubMenu])
    {
		item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Current Conditions",@"") 
													   action:NULL 
												keyEquivalent:@""] autorelease];
        NSMenu *subMenu = [[[NSMenu alloc] init] autorelease];
		
		[theMenu addItem:item];
        [item setSubmenu:subMenu];
        
        tempMenu = subMenu;
    }
	[self addCurrentWeatherDataToMenu:tempMenu forCity:city];
	if ([[MEAppearancePreferencesModule sharedInstance] displayCurrentConditionsInSubMenu] && ([tempMenu numberOfItems] == 0))
	{
		[item setSubmenu:nil]; // might be a memory leak?
	}
	
	if([[MEAppearancePreferencesModule sharedInstance] extendedForecastIsEnabled])
    {
        tempMenu = theMenu;
            
        if([[MEAppearancePreferencesModule sharedInstance] displayExtendedForecastInSubMenu])
        {
            item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Extended Forecast",@"") 
														   action:NULL
													keyEquivalent:@""] autorelease];
            NSMenu *subMenu = [[[NSMenu alloc] init] autorelease];
			
			[theMenu addItem:item];
			[item setSubmenu:subMenu];
            
            tempMenu = subMenu;
        }
		else
		{
//			[theMenu addItem:[NSMenuItem separatorItem]];
			NSMenuItem *forecastLabel = [[[NSMenuItem alloc] initWithTitle:@"Forecast:"
																	action:NULL
															 keyEquivalent:@""] autorelease];
			[theMenu addItem:forecastLabel];
		}
        [self addForecastDataToMenu:tempMenu forCity:city];
		if ([[MEAppearancePreferencesModule sharedInstance] displayExtendedForecastInSubMenu] && 
			([tempMenu numberOfItems] == 0))
		{
			[item setSubmenu:nil]; // might be a memory leak?
		}
    } // [[MEAppearancePreferencesModule sharedInstance] ]
}

- (void)addNonMainCitiesToMenu:(NSMenu*)theMenu
{
    
	NSArray *activeCities = [self activeCities];
	NSEnumerator *cityEnum = [activeCities objectEnumerator];
	MECity *city;
	NSString *linkString;
	
	if ([activeCities count] > 1)
		[theMenu addItem:[NSMenuItem separatorItem]];
	
	while(city = [cityEnum nextObject])
	{
		if(city == mainCity)
			continue;
        
		NSString *temp = [city stringForKey:@"Temperature"];
				
		if(temp)
			temp = [NSString stringWithFormat:@"%@ %@",[city cityName],temp];
		else
			temp = [city cityName];
        
		MEMenuItem *theCityItem = [[[MEMenuItem alloc] initWithTitle:temp
															  action:NULL
													   keyEquivalent:@""] autorelease];
		[theMenu addItem:theCityItem];
		
		NSMenu *subMenu = [[NSMenu alloc] init]; // submenu for the city
		[theCityItem setSubmenu:subMenu]; // Cityname --> subMenu
		
		linkString = [city stringForKey:@"Weather Link"];
		
		if(linkString)
		{
			[theCityItem setLink:linkString];
			[theCityItem setAction:@selector(launchURL:)];
		}
		
		[theCityItem setImage:[city imageForKey:@"Weather Image"
										   size:16
									  imageDir:localImagesPath]];
		
		[self addCurrentAndForecastDataToMenu:subMenu forCity:city];
		[subMenu release];
	}
}

#pragma mark -

- (NSString *)relativeDateStringForDate:(NSCalendarDate *)date
{
	if (!date)
		return nil;
	NSUserDefaults *theDefault = [NSUserDefaults standardUserDefaults];
	int today                  = [[NSCalendarDate calendarDate] dayOfCommonEra];
	int dateDay                = [date dayOfCommonEra];
	NSString *dayName;
	NSString *timeOfDay = [date descriptionWithCalendarFormat:@"%I:%M %p" timeZone:nil locale:nil];
	
	if(dateDay==today)
		dayName = [[[theDefault stringArrayForKey:@"NSThisDayDesignations"] objectAtIndex:0] capitalizedString];
	else if(dateDay==(today+1))
		dayName = [[[theDefault stringArrayForKey:@"NSNextDayDesignations"] objectAtIndex:0] capitalizedString];
	else if(dateDay==(today-1))
		dayName = [[[theDefault stringArrayForKey:@"NSPriorDayDesignations"] objectAtIndex:0] capitalizedString];
	else
		dayName = [lastUpdate descriptionWithCalendarFormat:@"%a, %b %e, %y" timeZone:nil locale:nil];
	
	return [NSString stringWithFormat:@"%@ %@",dayName,timeOfDay];
}

#pragma mark Menu Callbacks
- (void)dummy:(id) sender
{
	return;
}

- (IBAction)URLButtonClick:(id)sender
{
	if ([sender respondsToSelector:@selector(title)])
	{
		NSString *url = [(NSButton *)sender title];
		if (url && [url hasPrefix:@"http:"])
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		else
			NSLog(@"Tried to visit bad url %@.",sender);
	}
}

- (void)launchURL:(id)sender
{
	if ([sender respondsToSelector:@selector(link)])
	{
		NSString *url = [sender link];
		if (url)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		else
			NSLog(@"Tried to visit nil link");
	}
}


#pragma mark -
- (NSMutableArray *)cities
{
	return [[MECityPreferencesModule sharedInstance] cities];
}

- (NSArray *)activeCities
{
    NSArray			*cities			= [self cities];
    NSMutableArray	*activeCities	= [NSMutableArray array];
    NSEnumerator	*cityEnum		= [cities objectEnumerator];
    MECity			*nextCity;
    
    while(nextCity = [cityEnum nextObject])
        if([nextCity isActive])
            [activeCities addObject:nextCity];
            
    return [[activeCities retain] autorelease];
}

NSFont* fontWithMaxHeight(NSString *name, int maxHeight)
{
    int i = 1;
    NSFont *font = [NSFont fontWithName:name size:1];
    
    while([font ascender] - [font descender] < maxHeight)
    {
        i++;
        font = [NSFont fontWithName:name size:i];
    }
    
    return [NSFont fontWithName:name size:i-1];
}

#pragma mark Fetching weather data

- (void)newNetworkConfiguration:(NSNotification *)aNot
{
	NSLog(@"Meteo has detected a change in the IPv4 settings and will try to reload the weather data.");
	[self tellCitiesToUpdateWeatherReports];
}

- (void)tellCityToUpdateWeatherReport:(NSNotification *)aNot
{
	MECity *aCity;
	if (aCity = [[aNot userInfo] objectForKey:@"city"])
	{
		[aCity updateWeatherReport];
		[cityDownloadsPendingLock lock];
		if (cityDownloadsPending == 0)
			[self startLoadingInMenuBar];
			//[NSThread detachNewThreadSelector:@selector(startLoadingInMenuBar) toTarget:self withObject:nil];
		cityDownloadsPending++;
		[cityDownloadsPendingLock unlock];		
	}
}

- (void)tellCitiesToUpdateWeatherReports
{
	NSArray *activeCities = [self activeCities];
	
	if (activeCities && ([activeCities count] > 0))
	{
		NSEnumerator *cityEnum = [activeCities objectEnumerator];
		MECity *nextCity;

		//NSLog(@"Telling %d active cities to update their weather reports.",[activeCities count]);

		[cityDownloadsPendingLock lock];
		if (cityDownloadsPending == 0)
			[self startLoadingInMenuBar];
//			[NSThread detachNewThreadSelector:@selector(startLoadingInMenuBar) toTarget:self withObject:nil];
		[cityDownloadsPendingLock unlock];

		while(nextCity = [cityEnum nextObject])
		{
			[nextCity updateWeatherReport];
			
			[cityDownloadsPendingLock lock];
			cityDownloadsPending++;
			[cityDownloadsPendingLock unlock];
		}
			
		// save this "date" for the "Last Update:" time
		if (lastUpdate)
			[lastUpdate release];
		lastUpdate = [[NSCalendarDate calendarDate] retain];
	}
	else
	{
		[self generateMenu];
	}
}

- (void) cityHasFinishedUpdatingWeather:(NSNotification *)aNot
{
	[cityDownloadsPendingLock lock];
	cityDownloadsPending--;
	if (cityDownloadsPending <= 0)
	{
		cityDownloadsPending = 0;
		//[self performSelectorOnMainThread:@selector(generateMenu) withObject:nil waitUntilDone:YES];
		[self generateMenu];
		[self performSelectorOnMainThread:@selector(stopLoadingInMenuBar) withObject:nil waitUntilDone:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MEAutoUpdateComplete" object:nil];
		[statusItem setImage:[self statusItemImageForCurrentState]];
	}
	[cityDownloadsPendingLock unlock];
}

#pragma mark Animated "Loading" methods

- (void)startLoadingInMenuBar
{
	if ((!menuBarLoadTimer || ![menuBarLoadTimer isValid]) && // prevents the timer for going off twice
		([[MEGeneralPreferencesModule sharedInstance] animateUpdates])) // only update if the user wants to
	{
		menuBarLoadTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 
															target:self 
														  selector:@selector(loadNextInMenuBar) 
														  userInfo:nil 
														   repeats:YES] retain];
	}

	if (refreshMI)
		[refreshMI setAction:NULL]; // deactivate
}

- (void)stopLoadingInMenuBar
{
    if(menuBarLoadTimer!=nil && [menuBarLoadTimer isValid])
	{
        [menuBarLoadTimer invalidate];
		[menuBarLoadTimer release];	
		menuBarLoadTimer = nil;
	}
	if (refreshMI)
		[refreshMI setAction:@selector(refreshCallback:)];
}

- (void)loadNextInMenuBar
{
	static int num = 1;
    NSImage *img   = nil;
    NSString *loc  = [NSString stringWithFormat:@"/Library/Application Support/Meteo/Menu Bar Icons/Loading-%d.tiff",num];
    
    img = [[[NSImage alloc] initWithContentsOfFile:loc] autorelease];
        
    if(!img)
        [[[NSImage alloc] initWithContentsOfFile:[[NSString stringWithFormat:@"~%@",loc] stringByExpandingTildeInPath]] autorelease];
        
    [statusItem setImage:img];
    
	num++;
    if(num == 9)
        num = 1;
	
	if (![NSThread isMultiThreaded])
	{ // this is a hack.  it quits loading if the app isn't threaded.
		// I'm assuming that the program is only threaded when it is
		// downloading from the weather servers.
		// I hope it doesn't cause much of a performance hit.
		[self stopLoadingInMenuBar];
		[self generateMenu];		
		return;
	}
}

#pragma mark -
- (void)updateDock
{
    //here's what needs to go on in the dock:

    NSArray *activeCities = [self activeCities];
    MECity *city;
    NSImage *pic;
    
    if([activeCities count])
        city = [activeCities objectAtIndex:0];
    else
        city = nil;
    
    pic = [city imageForKey:@"Weather Image"
					   size:128
				   imageDir:localImagesPath];
    if(!pic)
    {
        pic = [NSImage imageNamed:@"Unknown.tiff"];
        [pic setScalesWhenResized:YES];
        [pic setSize:NSMakeSize(128,128)];
    }

    NSString *forc = [city stringForKey:@"Date"];

        
    NSImage *tvImage = nil;
    NSImage *moonImage = nil;
    
    if([forc hasSuffix:@"ight"])
    {
        tvImage = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@%@",localImagesPath,@"Dock Icons/Television/Television-Night.tiff"]] autorelease];
        
        moonImage = [city imageForKey:@"Moon Phase"
								 size:128
							imageDir:localImagesPath];
    }
    else
    {
        tvImage = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@%@",localImagesPath,@"Dock Icons/Television/Television-Day.tiff"]] autorelease];
    }
                            

    NSImage *image   = [[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];
    NSImage *tempPic = [[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];

    NSString *temp = [[city stringForKey:@"Temperature"] description];
	temp = [NSString stringWithFormat:@"%i",[temp intValue]];
    if(!temp)
        temp = @"N/A";
        
    NSImage *tempBar;
    int theTemperature = [temp intValue];

    int i = theTemperature/10;
    
    if(i > 9)
        i = 9;
    if(i < 1)
        i = 1;
        
    tempBar = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@Dock Icons/Temperature/Temperature-%d.tiff",localImagesPath,i]] autorelease];

	NSMutableDictionary *attr = [MEController bestAttributesForString:temp size:NSMakeSize(36,36) fontName:[[MEAppearancePreferencesModule sharedInstance] dockFontName]];
    
    NSSize size;
    float x,y;
    
    if([[MEAppearancePreferencesModule sharedInstance] displayTemp] && temp)
    {
        size = [temp sizeWithAttributes:attr];

        x = 128 - (40 + 8) + ((36 - size.width)/2);
        y = 8 + ((36 - size.height)/2);
    
        [tempPic lockFocus];
        [attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        [temp drawAtPoint:NSMakePoint(x,y) withAttributes:attr];
        [tempPic unlockFocus];
    }
    
    [image lockFocus];
    if(tvImage) 
        [tvImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[[MEAppearancePreferencesModule sharedInstance] imageOpacity]];
    if(moonImage)
        [moonImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[[MEAppearancePreferencesModule sharedInstance] imageOpacity]];
    if(pic) 
        [pic compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[[MEAppearancePreferencesModule sharedInstance] imageOpacity]];
    if(tempBar)
        [tempBar compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[[MEAppearancePreferencesModule sharedInstance] imageOpacity]];
    if([[MEAppearancePreferencesModule sharedInstance] displayTemp]) 
        [tempPic compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
    [image unlockFocus];
    
    [NSApp setApplicationIconImage:image];
}

+ (NSMutableDictionary *)bestAttributesForString:(NSString *)string size:(NSSize)size fontName:(NSString *)fontName
{
    NSFont *font = [NSFont fontWithName:fontName size:1];
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    NSMutableDictionary *atr = [NSMutableDictionary dictionary];
    NSSize aSize;
    int i = 1;
    
    [style setAlignment:NSCenterTextAlignment];
    [atr setObject:font forKey:NSFontAttributeName];
    [atr setObject:style forKey:NSParagraphStyleAttributeName];
    
    while(1)
    {
        aSize = [string sizeWithAttributes:atr];
        if(aSize.width>size.width || aSize.height>size.height)
        {
            i--;
            font = [NSFont fontWithName:fontName size:i];
            [atr setObject:font forKey:NSFontAttributeName];
            break;
        }
        else
        {
            i++;
            font = [NSFont fontWithName:fontName size:i];
            [atr setObject:font forKey:NSFontAttributeName];
        }
    }
    
    return atr;
}

@end

@implementation MEMenuItem : NSMenuItem

-(void)dealloc
{
	if (link)
		[link release];
	
	[super dealloc];
}

-(void)setLink:(NSString*)url
{
	if (link)
		[link release];
	link = [url retain];
}
-(NSString*)link
{
	return link;
}

@end

// depreciated in 2.0 to fix a memory leak
//@implementation NSString (LinkAdditions)

//- (void)openLink:(id)sender
//{
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self]];
//}

//@end
