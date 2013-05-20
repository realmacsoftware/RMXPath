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

#import "RMXPath-TestTokeniseFull.h"

#import "RMXPath/RMXPath.h"

#import "_RMXPathToken.h"

#define _RMXPathTokenClassWithString(name, string) [[[_RMXPathTokenClass(name) alloc] initWithString:string] autorelease]

@implementation RMXPath_TestTokeniseFull

- (void)testTokeniseXPathWithNamespaces {
	NSString *XPath = @"/d:child/e:grandchild";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	STAssertNotNil(XPathTokens, @"XPath with namespaces should tokenise");
}

- (void)testTokeniseXPathWithNamespacesReplacedWithEquivalences {
	NSString *XPath = @"/*[local-name() = 'child' and string(namespace-uri()) = 'urn:example:d']/*[local-name() = 'grandchild' and string(namespace-uri()) = 'urn:example:e']";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	STAssertNotNil(XPathTokens, @"XPath with equivalences should tokenise");
}

- (void)testTokenisePoorlySpacedXPathOperatorThatWorksInLibxml2 {
	NSString *XPath = @"/root/parent/child[@title = 'title'andstring() = 'yes']";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	
	STAssertNotNil(XPathTokens, @"XPath with poor operator spacing should tokenise");
	
	NSArray *expectedTokenOrder = [NSArray arrayWithObjects:
								   _RMXPathTokenClassWithString(Operator,					@"/"),
								   _RMXPathTokenClassWithString(QName,						@"root"),
								   _RMXPathTokenClassWithString(Operator,					@"/"),
								   _RMXPathTokenClassWithString(QName,						@"parent"),
								   _RMXPathTokenClassWithString(Operator,					@"/"),
								   _RMXPathTokenClassWithString(QName,						@"child"),
								   _RMXPathTokenClassWithString(Operator,					@"["),
								   _RMXPathTokenClassWithString(,							@"@"),
								   _RMXPathTokenClassWithString(QName,						@"title"),
								   _RMXPathTokenClassWithString(Operator,					@"="),
								   _RMXPathTokenClassWithString(StringLiteralOpen,			@"'"),
								   _RMXPathTokenClassWithString(StringLiteralContent,		@"title"),
								   _RMXPathTokenClassWithString(StringLiteralClose,			@"'"),
								   _RMXPathTokenClassWithString(Operator,					@"and"),
								   _RMXPathTokenClassWithString(QName,						@"string"),
								   _RMXPathTokenClassWithString(,							@"("),
								   _RMXPathTokenClassWithString(,							@")"),
								   _RMXPathTokenClassWithString(Operator,					@"="),
								   _RMXPathTokenClassWithString(StringLiteralOpen,			@"'"),
								   _RMXPathTokenClassWithString(StringLiteralContent,		@"yes"),
								   _RMXPathTokenClassWithString(StringLiteralClose,			@"'"),
								   _RMXPathTokenClassWithString(Operator,					@"]"),
								   nil];
	
	STAssertTrue([XPathTokens count] == [expectedTokenOrder count], @"unexpected token count");
	
	STAssertEqualObjects([XPathTokens valueForKey:@"class"], [expectedTokenOrder valueForKey:@"class"], @"unexpected token order");
	STAssertEqualObjects([XPathTokens valueForKey:_RMXPathTokenStringKey], [expectedTokenOrder valueForKey:_RMXPathTokenStringKey], @"unexpected token order");
}

- (void)testTokeniseXPathFull1 {
	NSString *XPath = @"/atom:entry/atom:link[@rel = 'alternate']/@href";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(QName),					// atom:entry
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(QName),					// atom:link
										_RMXPathTokenClass(Operator),				// [
										_RMXPathTokenClass(),						// @
										_RMXPathTokenClass(QName),					// rel
										_RMXPathTokenClass(Operator),				// =
										_RMXPathTokenClass(StringLiteralOpen),		// '
										_RMXPathTokenClass(StringLiteralContent),	// alternate
										_RMXPathTokenClass(StringLiteralClose),		// '
										_RMXPathTokenClass(Operator),				// ]
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(),						// @
										_RMXPathTokenClass(QName),					// href
										nil];
	
	STAssertTrue([XPathTokens count] == [expectedTokenClassOrder count], @"unexpected token count");
	
	STAssertEqualObjects([XPathTokens valueForKey:@"class"], expectedTokenClassOrder, @"unexpected token order");
}

- (void)testTokeniseXPathFull2 {
	NSString *XPath = @"/rsp[@stat = 'ok']/person/@privacy";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(QName),					// rsp
										_RMXPathTokenClass(Operator),				// [
										_RMXPathTokenClass(),						// @
										_RMXPathTokenClass(QName),					// stat
										_RMXPathTokenClass(Operator),				// =
										_RMXPathTokenClass(StringLiteralOpen),		// '
										_RMXPathTokenClass(StringLiteralContent),	// ok
										_RMXPathTokenClass(StringLiteralClose),		// '
										_RMXPathTokenClass(Operator),				// ]
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(QName),					// person
										_RMXPathTokenClass(Operator),				// /
										_RMXPathTokenClass(),						// @
										_RMXPathTokenClass(QName),					// privacy
										nil];
	
	STAssertTrue([XPathTokens count] == [expectedTokenClassOrder count], @"unexpected token count");
	
	STAssertEqualObjects([XPathTokens valueForKey:@"class"], expectedTokenClassOrder, @"unexpected token order");
}

- (void)testTokeniseXPathFull3 {
	NSString *XPath = @"/status/entities/media/creative/expanded_url/text()";
	
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(QName),		// status
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(QName),		// entities
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(QName),		// media
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(QName),		// creative
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(QName),		// expanded_url
										_RMXPathTokenClass(Operator),	// /
										_RMXPathTokenClass(),			// text
										_RMXPathTokenClass(),			// (
										_RMXPathTokenClass(),			// )
										nil];
	
	STAssertTrue([XPathTokens count] == [expectedTokenClassOrder count], @"unexpected token count");
	
	STAssertEqualObjects([XPathTokens valueForKey:@"class"], expectedTokenClassOrder, @"unexpected token order");
}

@end
