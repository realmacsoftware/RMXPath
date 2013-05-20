//
// Copyright (C) 2013 Realmac Software Ltd
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject
// to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <TargetConditionals.h>

#import "RMXPath-Tests.h"

#import "RMXPath/RMXPath.h"

#import "RMXPath-TestsConstants.h"

@interface RMXPath_Tests ()
@property (retain, nonatomic) id document;
@end

@implementation RMXPath_Tests

@synthesize document=_document;

- (void)setUp
{
	NSURL *testDocumentLocation = [[NSBundle bundleWithIdentifier:RMXPathTestsBundleIdentifier] URLForResource:@"sample+ns" withExtension:@"xml"];
	STAssertNotNil(testDocumentLocation, @"sample XML document not included in bundle");
	
	NSError *testDocumentDataError = nil;
	NSData *testDocumentData = [NSData dataWithContentsOfURL:testDocumentLocation options:(NSDataReadingOptions)0 error:&testDocumentDataError];
	STAssertNotNil(testDocumentData, @"couldn't load test document data");
	
	NSError *testDocumentError = nil;
	NSXMLDocument *testDocument = [[NSXMLDocument alloc] initWithData:testDocumentData options:(NSUInteger)0 error:&testDocumentError];
	STAssertNotNil(testDocument, @"couldn't initialise XML document");
	
	[self setDocument:testDocument];
}

- (void)tearDown
{
	[self setDocument:nil];
}

#if 0

/*
	Note
	
	this test relies on bad practice and has been turned off
	
	it is only supported in the NSXML family, we haven't added this behaviour to other evaluators
 */

- (void)testXPathWithNamespacePrefixesEqualToThoseInTheDocument
{
	NSError *nodesError = nil;
	NSArray *nodes = [[self document] nodesForXPath:@"/catalog/book:reference" error:&nodesError];
	STAssertTrue((NSInteger)[nodes count] == (NSInteger)4, @"expected to find four reference books in the sample document");
}

#endif /* 0 */

- (void)testXPathWithNamespacePrefixesAfterPreprocessingTheXPath
{
	NSString *XPath = @"/a:catalog/b:reference";
	
	NSDictionary *XPathNamespaceMap = [NSDictionary dictionaryWithObjectsAndKeys:
									   @"http://realmacsoftware.com/namespaces/dts/catalog.xml", @"a",
									   @"http://realmacsoftware.com/namespaces/dts/book.xml", @"b",
									   nil];
	
	NSString *preprocessedXPath = RMFoundationXPathPreprocessQNameNamespaces(XPath, XPathNamespaceMap);
	
	NSError *nodesError = nil;
	NSArray *nodes = [[self document] nodesForXPath:preprocessedXPath error:&nodesError];
	STAssertTrue((NSInteger)[nodes count] == (NSInteger)4, @"expected to find four reference books in the sample document");
}

- (void)testXPathWithNamespacePrefixesInequalToThoseInTheDocument
{
	NSString *XPath = @"/alpha:catalog/bravo:reference";
	
	NSDictionary *XPathNamespaceMap = [NSDictionary dictionaryWithObjectsAndKeys:
									   @"http://realmacsoftware.com/namespaces/dts/catalog.xml", @"alpha",
									   @"http://realmacsoftware.com/namespaces/dts/book.xml", @"bravo",
									   nil];
	
	NSError *nodesError = nil;
	NSArray *nodes = [[self document] nodesForXPath:RMFoundationXPathPreprocessQNameNamespaces(XPath, XPathNamespaceMap) error:&nodesError];
	STAssertTrue((NSInteger)[nodes count] == (NSInteger)4, @"expected to find four reference books in the sample document");
}

@end
