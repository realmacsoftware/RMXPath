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

#import "RMXPath-TestTokeniseExcerpts.h"

#import "RMXPath/RMXPath.h"

#import "_RMXPathToken.h"

@implementation RMXPath_TestTokeniseExcerpts

- (void)_assertTokensAreExpected:(NSArray *)XPathTokens expectedTokenClassOrder:(NSArray *)expectedTokenClassOrder {
	STAssertTrue([XPathTokens count] == [expectedTokenClassOrder count], ([NSString stringWithFormat:@"nested comment should yield %lu tokens", (unsigned long)[expectedTokenClassOrder count]]));
	STAssertEqualObjects([XPathTokens valueForKey:@"class"], expectedTokenClassOrder, @"unexpected token ordering");
}

- (void)testTokeniseEmpty {
	NSString *XPath = @""; 
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"empty string should pass tokenisation");
	STAssertTrue([XPathTokens count] == 0, @"empty string should yield 0 tokens");
}

- (void)testTokeniseComment {
	NSString *XPath = @"(: comment :)"; 
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"simple comments should pass tokenisation");

	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseCommentNotClosed {
	NSString *XPath = @"(: comment"; 
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	STAssertNil(XPathTokens, @"unclosed comment should fail tokenisation");
	STAssertNotNil(XPathTokensError, @"unclosed comment tokenisation should return an error byref");
}

- (void)testTokeniseCommentWithNestedComment {
	NSString *XPath = @"(: comment-outer-1 (: comment-inner :) comment-outer-2 :)";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"nested comments should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseCommentWithNestedCommentNotClosed {
	NSString *XPath = @"(: comment-outer-1 (: comment-inner :)";
	NSError *XPathTokensError = nil;
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, &XPathTokensError);
	STAssertNil(XPathTokens, @"nested comments should pass tokenisation");
	STAssertNotNil(XPathTokensError, @"unclosed nested comments tokenisation should return an error byref");
}

- (void)testTokeniseUnprefixedNodeName {
	NSString *XPath = @"root";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"unprefixed node name should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokenisePrefixedNodeName {
	NSString *XPath = @"a:root";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"prefixed node name should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseUnprefixedAttributeName {
	NSString *XPath = @"@attr";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"unprefixed attribute name should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokenisePrefixedAttributeName {
	NSString *XPath = @"@a:attr";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"prefixed attribute name should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseSimpleNamePath {
	NSString *XPath = @"/root/parent/child";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"simple path should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseSimpleNamePathWithHeaderComment {
	NSString *XPath = @"(: comment :) /root/parent/child";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"header comment with simple path should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseSimpleNamePathWithTrailerComment {
	/*
		Note
		
		this test fails because `child (' is tokenised as <QName "("> when it should be tokenised as <QName CommentOpen CommentContent CommentClose>
		
		we need to expand the whitespace handling to support comments and token matchers of the form <* "("> need a negative lookahead assertion that excludes open parenthesis followed by a colon without whitespace
	 */
	NSString *XPath = @"/root/child (: comment :)";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"simple path with trailer comment should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokenisePathologicalFunctionWithCommentBetweenQNameAndFunctionInvocation {
	/*
		Note
		
		comments are valid anywhere whitespace is valid
		
		this case doesn't actually validate in the NSXML XQuery parser, but we should support tokenising it
		
		theoretically we could apply a strip comments transform that would allow such an XPath to pass NSXML XQuery validation
		
		to ensure consistent tokenisation when whitespace or comments are in play, this should tokenise to <"document-node" "(:" " comment " ":)" "(" ")">
	 */
	NSString *XPath = @"document-node (: comment :) ()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"pathological function with comment between QName and function invocation should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokenisePathologicalFunctionWithCommentBetweenQNameAndFunctionInvocationNoWhitespace {
	/*
		Note
		
		comments are valid anywhere whitespace is valid
		
		this case doesn't actually validate in the NSXML XQuery parser, but we should support tokenising it
		
		theoretically we could apply a strip comments transform that would allow such an XPath to pass NSXML XQuery validation
		
		to ensure consistent tokenisation when whitespace or comments are in play, this should tokenise to <"document-node" "(:" " comment " ":)" "(" ")">
	 */
	NSString *XPath = @"document-node(:comment:)()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"pathological function with comment between QName and function invocation should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokenisePathologicalFunctionWithCommentBetweenQNameAndFunctionInvocationNoWhitespace2 {
	NSString *XPath = @"document-node(:comment:)(:comment:)()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"pathological function with two comments between QName and function invocation should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseMultiplePaths {
	NSString *XPath = @"(: comment :) /root, /root/child, /root/child/grandchild";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"header comment with multiple paths separated by commas should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(CommentOpen),
										_RMXPathTokenClass(CommentContent),
										_RMXPathTokenClass(CommentClose),
										
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseFunction {
	/*
		Note
		
		to ensure consistent tokenisation when whitespace or comments are in play, this should tokenise to <"text" "(" ")">
	 */
	NSString *XPath = @"text()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"simple function should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseSimpleNamePathWithFunction {
	NSString *XPath = @"/root/text()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"simple path with function should pass tokenisation");

	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(Operator),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseStringLiteralWithSingleQuotes {
	NSString *XPath = @"'text'";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"single quoted string literal should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(StringLiteralOpen),
										_RMXPathTokenClass(StringLiteralContent),
										_RMXPathTokenClass(StringLiteralClose),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseStringLiteralWithDoubleQuotes {
	NSString *XPath = @"\"text\"";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"double quoted string literal should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(StringLiteralOpen),
										_RMXPathTokenClass(StringLiteralContent),
										_RMXPathTokenClass(StringLiteralClose),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

- (void)testTokeniseQNameWithMinus {
	NSString *XPath = @"local-name()";
	NSArray *XPathTokens = RMFoundationXPathTokenise(XPath, NULL);
	STAssertNotNil(XPathTokens, @"QName with minus in name should pass tokenisation");
	
	NSArray *expectedTokenClassOrder = [NSArray arrayWithObjects:
										_RMXPathTokenClass(QName),
										_RMXPathTokenClass(),
										_RMXPathTokenClass(),
										nil];
	[self _assertTokensAreExpected:XPathTokens expectedTokenClassOrder:expectedTokenClassOrder];
}

@end
