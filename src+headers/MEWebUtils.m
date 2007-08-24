//
//  MEWebUtils.m
//  Meteorologist
//
//  Created by Joseph Crobak on Thu Jun 17 2004.
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

#import "MEWebUtils.h"
#import "MEStringSearcher.h"
#import "NSPreferences.h"

#define DEFAULT_TIMEOUT 60

NSString *MEWebUtilsBackgroundDownloadFinished = @"MEWebUtilsBackgroundDownloadFinished";

@implementation MEWebFetcher

- (id)init
{
    self = [super init];
	if (self)
	{
		downloadLock = [[NSLock alloc] init];
		errorMsgLock = [[NSLock alloc] init];
		errorMsg = [NSString string];
	}
	return self;
}

- (void)dealloc
{
	[downloadLock release];
	[errorMsgLock release];
	if (errorMsg)
		[errorMsg release];
	[super dealloc];
}

+ (MEWebFetcher *)sharedInstance
{
	static MEWebFetcher *sharedInstance = nil;
	if (!sharedInstance)
		sharedInstance = [[self alloc] init];
	return sharedInstance;
}

+ (MEWebFetcher *)webFetcher
{
	return [[[MEWebFetcher alloc] init] autorelease];
}

#pragma mark Error Message Methods
- (void) setError:(NSString *)msg
{
	[errorMsgLock lock];
	if (errorMsg)
		[errorMsg release];
	errorMsg = [msg retain];
	[errorMsgLock unlock];
}

- (NSString *) errorMessage
{
	[errorMsgLock lock];
	NSString *msg = [[errorMsg retain] autorelease];
	[errorMsgLock unlock];
	
	return msg;
}

#pragma mark Loading in Background

- (void)fetchURLtoStringInBackground:(NSURL *)url
{
	[downloadLock lock];
	if (mURLHandle != nil)
		[mURLHandle release];
	mURLHandle = [[CURLHandle alloc] initWithURL:url cached:NO];
	
	[mURLHandle setFailsOnError:YES];	   // fail on >= 300 code
	[mURLHandle setFollowsRedirects:YES];  // Follow Location: headers in HTML docs.
	[mURLHandle setUserAgent: @"Mozilla/4.5 (compatible; OmniWeb/4.0.5; Mac_PowerPC)"];
	[mURLHandle setConnectionTimeout:DEFAULT_TIMEOUT];
	[mURLHandle setAcceptCompression:YES];  // This could be the source of a major speed-up!
	
	
	[mURLHandle addClient:self];
	
	NSLog(@"Loading in background: %@",url);
	[mURLHandle loadInBackground];
}

- (void)cancelFetchURL
{
	NSLog(@"canceling fetch url");
	if (mURLHandle && ([mURLHandle status] == NSURLHandleLoadInProgress))
	{
		[mURLHandle cancelLoadInBackground];
		[mURLHandle release];
		mURLHandle = nil; 
	}
}

#pragma mark Loading in Foreground

/* @parameters:
				url  is a valid NSURL
   @result:
				returns the result of calling fetchURLtoString:withTimeout: passing DEFAULT_TIMEOUT				
*/
- (NSString *)fetchURLtoString:(NSURL *)url 
{
	return [self fetchURLtoString:url withTimeout:DEFAULT_TIMEOUT];
}

/* @parameters:
				url   is a valid NSURL
				secs  is the number of seconds before the request for url will be given up.
   @result:
				returns the data associated with the url.  Returns nil if there was an error.				
*/
- (NSString *)fetchURLtoString:(NSURL *)url withTimeout:(int)secs
{
	NSData *urlData     = [self fetchURLtoData:url withTimeout:secs];
	if (urlData)
		return [[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding] autorelease];
	return nil;
}

#pragma mark -
/* @parameters:
				url  is a valid NSURL
   @result:
				returns the result of calling fetchURLtoData:withTimeout: passing DEFAULT_TIMEOUT				
*/
- (NSData *)fetchURLtoData:(NSURL *)url
{
	return [self fetchURLtoData:url withTimeout:DEFAULT_TIMEOUT];
}

/* @parameters:
				url   is a valid NSURL
				secs  is the number of seconds before the request for url will be given up.
   @result:
				returns the data associated with the url.  Returns nil if there was an error.				
*/
- (NSData *)fetchURLtoData:(NSURL *)url withTimeout:(int)secs 
{
	NSData *data; // data from the website
	[downloadLock lock];
	mURLHandle = (CURLHandle *)[url URLHandleUsingCache:NO];
	
	[mURLHandle setFailsOnError:YES];	   // fail on >= 300 code
	[mURLHandle setFollowsRedirects:YES];  // Follow Location: headers in HTML docs.
	[mURLHandle setUserAgent: @"Mozilla/4.5 (compatible; OmniWeb/4.0.5; Mac_PowerPC)"];
	[mURLHandle setConnectionTimeout:secs];
	[mURLHandle setAcceptCompression:YES];  // This could be the source of a major speed-up!
	
	data = [mURLHandle resourceData];
	if (!data)
	{
		NSLog(@"Download failed. Reason: %@ (%@)",[mURLHandle failureReason],[mURLHandle curlError]);
		[[MEWebFetcher sharedInstance] setError:[mURLHandle curlError]];
		[downloadLock unlock];
		return nil;
	}
	
	[[MEWebFetcher sharedInstance] setError:@"none"];
	[downloadLock unlock];
	return [[data retain] autorelease];
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{

}

- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{

}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender
{
	if (mURLHandle && (mURLHandle == sender))
	{
		NSLog(@"Finished downloading in background");
		NSData   *urlData = [mURLHandle resourceData];
		NSString *string  = [[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding] autorelease];
		NSString *url     = [[mURLHandle url] absoluteString];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MEWebUtilsBackgroundDownloadFinished 
															object:self
														  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  string,@"string",
															  url,@"url",nil]];
		
		[mURLHandle removeClient:self];
		[mURLHandle release];
		mURLHandle = nil;
	}
}

- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{

}

- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{
	if (mURLHandle && (mURLHandle == sender))
	{
		NSRunAlertPanel(reason,@"There was a connection error while trying to fetch some data from the Internet.  It might be on the other end, but it is a good idea to check your internet connection anyway.",@"OK",nil,nil);
		[mURLHandle release];
		mURLHandle = nil;
	}
}
@end

@implementation MEURLStringProcessor

+ (NSString *)makeStringURLable:(NSString *)URLString
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)URLString,NULL,NULL,kCFStringEncodingUTF8);
}

@end