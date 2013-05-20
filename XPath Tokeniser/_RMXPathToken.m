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

#import "_RMXPathToken.h"

NSString *const _RMXPathTokenStringKey = @"string";
NSString *const _RMXPathTokenSerialisedRepresentationKey = @"serialisedRepresentation";

@interface NSObject ()
- (NSString *)debugDescription;
@end

@interface _RMXPathToken ()
@property (readwrite, copy, nonatomic) NSString *string;
@end

@implementation _RMXPathToken

@synthesize string=_string;

- (id)initWithString:(NSString *)string {
	self = [self init];
	if (self == nil) return nil;
	
	_string = [string copy];
	
	return self;
}

- (void)dealloc {
	[_string release];
	
	[super dealloc];
}

- (NSString *)debugDescription {
	return [[super debugDescription] stringByAppendingFormat:@" @\"%@\"", [self string]];
}

- (void)appendString:(NSString *)string {
	[self setString:[[self string] stringByAppendingString:string]];
}

- (NSString *)serialisedRepresentation {
	return [self string];
}

@end

#define _RMXPathTokenClassDefine(name) \
@implementation _RMXPathToken ## name @end

_RMXPathTokenClassDefine(CommentOpen);
_RMXPathTokenClassDefine(CommentClose);
_RMXPathTokenClassDefine(CommentContent);

_RMXPathTokenClassDefine(DecimalLiteral);
_RMXPathTokenClassDefine(DoubleLiteral);
_RMXPathTokenClassDefine(IntegerLiteral);
_RMXPathTokenClassDefine(NotNumber);

_RMXPathTokenClassDefine(StringLiteralOpen);
_RMXPathTokenClassDefine(StringLiteralClose);
_RMXPathTokenClassDefine(StringLiteralContent);

_RMXPathTokenClassDefine(Operator);

_RMXPathTokenClassDefine(Wildcard);
_RMXPathTokenClassDefine(QName);

#pragma mark -

@implementation _RMXPathToken__LookAhead__

@synthesize negative=_negative;
@synthesize allowsPrecedingWhitespace=_allowsPrecedingWhitespace;

@end
