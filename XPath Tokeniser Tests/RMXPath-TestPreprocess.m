//
// Copyright (c) 2013 Realmac Software Ltd
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

#import "RMXPath-TestPreprocess.h"

#import "RMXPath/RMXPath.h"

@implementation RMXPath_TestPreprocess

- (void)testPreprocessingIsIdempotentToUnprefixedNames {
	NSString *XPath = @"/root/grandparent/parent/child/grandchild";
	NSString *preprocessedXPath = RMFoundationXPathPreprocessQNameNamespaces(XPath, nil);
	
	STAssertEqualObjects(XPath, preprocessedXPath, @"an XPath without any prefixes should be left in place");
}

- (void)testPreprocessingIsIdempotentWhenRunTwice {
	NSDictionary *namespaceMap = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"urn:example:d", @"d",
								  @"urn:example:e", @"e",
								  nil];
	NSString *XPath = @"/d:child/e:grandchild";
	
	NSString *preprocessOnce = RMFoundationXPathPreprocessQNameNamespaces(XPath, namespaceMap);
	NSString *preprocessTwice = RMFoundationXPathPreprocessQNameNamespaces(preprocessOnce, namespaceMap);
	
	STAssertEqualObjects(preprocessOnce, preprocessTwice, @"RMFoundationXPathPreprocessQNameNamespaces should be idempotent if performed on the same XPath twice");
}

- (void)testPreprocessingMultiplePrefixesWhichShareASuffix {
	NSDictionary *namespaceMap = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"urn:example:b", @"cd",
								  nil];
	NSString *XPath = @"/abcd:parent/cd:child";
	
	NSString *preprocessXPath = RMFoundationXPathPreprocessQNameNamespaces(XPath, namespaceMap);
	
	NSString *expectedXPath = @"/abcd:parent/*[local-name() = 'child' and string(namespace-uri()) = 'urn:example:b']";
	
	STAssertEqualObjects(preprocessXPath, expectedXPath, @"prefixes that share a suffix cannot be preprocessed correctly");
}

@end
