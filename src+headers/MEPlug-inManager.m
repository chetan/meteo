//
//  MEPlug-inManager.m
//  Meteorologist
//
//  Created by Joseph Crobak on Fri Jul 23 2004.
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


#import "MEPlug-inManager.h"


@implementation MEPlug_inManager

+(MEPlug_inManager *)defaultManager
{
	static MEPlug_inManager *sharedInstance;
	
	if (!sharedInstance)
		sharedInstance = [[MEPlug_inManager alloc] init];
		
	return sharedInstance;
}

-(void)discoverPlugIns
{
	Class weatherModuleClass;
	
	NSString *appSupport = @"Library/Application Support/Meteo/plugIns/";
	NSString *appPath    = [[NSBundle mainBundle] builtInPlugInsPath];
	NSString *userPath   = [[NSString stringWithString:NSHomeDirectory()] stringByAppendingPathComponent:appSupport];
	NSString *sysPath    = [@"/" stringByAppendingPathComponent:appSupport];
	NSArray *paths       = [NSArray arrayWithObjects:appPath,userPath,sysPath, nil];
	
	NSEnumerator *pathEnum = [paths objectEnumerator];
	NSString *path;
                        
	plugIns = [[NSMutableDictionary alloc] init];
                        
	while ( path = [pathEnum nextObject] ) 
	{
		//NSLog(@"checking path: %@",path);
		NSEnumerator *e = [[[NSFileManager defaultManager]
							 directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		
		while ( name = [e nextObject] )
			if ( [[name pathExtension] isEqualToString:@"plug-in"] ) 
			{
				NSBundle *plugin = [NSBundle bundleWithPath: [NSString stringWithFormat:@"%@/%@",path,name]];
				if ( weatherModuleClass = [plugin principalClass] )
					if ( [weatherModuleClass instancesRespondToSelector:@selector(parseWeatherDataForCode:)] ) 
					{
						NSString *moduleName = [[plugin infoDictionary]
												 objectForKey:@"MEWeatherModuleName"];
						[plugIns setObject:[weatherModuleClass 
												weatherModuleWithBundlePath:[path stringByAppendingPathComponent:name]]
												forKey:moduleName];
						NSLog(@"Plugin discovered: %@ (in: %@)",moduleName,path);
					}
			}
	}   
}

- (NSArray *)moduleNames
{
	return [plugIns allKeys];
}

- (MEWeatherModule *)moduleObjectNamed:(NSString *)moduleName
{
	return [plugIns objectForKey:moduleName];
}
@end
