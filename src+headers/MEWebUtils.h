//
//  MEWebUtils.h
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
//
//  6/21/2004
//  JRC - The goal of these two classes is to provide functionality for downloading URLs and parsing HTML for
//        the important information.  All parsing is done based on NSDictionary's that are provided by weather.xml.
//		  Currently, "fetching" is implemented using NSURLRequests.  The plan is to migrate to the CURLHandler
//		  framework to download for the next version.
//
#import <Foundation/Foundation.h>
#import <CURLHandle/CURLHandle.h>
#import <CURLHandle/CURLHandle+extras.h>

@class CURLHandle;

@interface MEWebFetcher : NSObject <NSURLHandleClient>
{
	CURLHandle *mURLHandle;
	NSLock *downloadLock;
	NSLock *errorMsgLock;
	NSString *errorMsg;
}

+ (MEWebFetcher *)sharedInstance;
+ (MEWebFetcher *)webFetcher;

- (void) setError:(NSString *)msg;
- (NSString *) errorMessage;

- (void)fetchURLtoStringInBackground:(NSURL *)url;
- (void)cancelFetchURL;


- (NSString *)fetchURLtoString:(NSURL *)url;
- (NSString *)fetchURLtoString:(NSURL *)url withTimeout:(int)secs;
- (NSData *)fetchURLtoData:(NSURL *)url;
- (NSData *)fetchURLtoData:(NSURL *)url withTimeout:(int)secs;

@end

@interface MEURLStringProcessor : NSObject
{
}
+ (NSString *)makeStringURLable:(NSString *)URLString;
@end