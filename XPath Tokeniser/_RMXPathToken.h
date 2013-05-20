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

#import <Foundation/Foundation.h>

@interface _RMXPathToken : NSObject

- (id)initWithString:(NSString *)string;

extern NSString *const _RMXPathTokenStringKey;
@property (readonly, copy, nonatomic) NSString *string;

- (void)appendString:(NSString *)string;

extern NSString *const _RMXPathTokenSerialisedRepresentationKey;
- (NSString *)serialisedRepresentation;

@end

#pragma mark -

#define _RMXPathTokenClassDeclare(name) \
@interface _RMXPathToken ## name : _RMXPathToken @end

_RMXPathTokenClassDeclare(CommentOpen);
_RMXPathTokenClassDeclare(CommentClose);
_RMXPathTokenClassDeclare(CommentContent);

_RMXPathTokenClassDeclare(DecimalLiteral);
_RMXPathTokenClassDeclare(DoubleLiteral);
_RMXPathTokenClassDeclare(IntegerLiteral);
_RMXPathTokenClassDeclare(NotNumber);

_RMXPathTokenClassDeclare(StringLiteralOpen);
_RMXPathTokenClassDeclare(StringLiteralClose);
_RMXPathTokenClassDeclare(StringLiteralContent);

_RMXPathTokenClassDeclare(Operator);

_RMXPathTokenClassDeclare(Wildcard);
_RMXPathTokenClassDeclare(QName);

@interface _RMXPathToken__LookAhead__ : _RMXPathToken
@property (assign, getter=isNegative, nonatomic) BOOL negative;
@property (assign, nonatomic) BOOL allowsPrecedingWhitespace;
@end

#pragma mark -

#define _RMXPathTokenClass(name) [_RMXPathToken ## name class]
