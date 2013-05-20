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

@class _RMXPathToken;

@interface _RMXPathScanner : NSObject

- (id)initWithString:(NSString *)string;

@property (readonly, copy, nonatomic) NSString *string;

@property (assign, nonatomic) NSUInteger scanLocation;
@property (readonly, getter=isAtEnd, nonatomic) BOOL atEnd;

- (void)pushAllowsWhitespaceCharacters:(BOOL)allowsWhitespaceCharacters;
- (void)popAllowsWhitespaceCharacters;

- (void)startCandidateSection:(id)userInfo;
- (void)measureCandidateScan:(BOOL (^)(_RMXPathScanner *, NSMutableArray *))scanBlock;
- (void)endCandidateSection;

- (id)commitCandidate;

@property (readonly, retain, nonatomic) NSArray *cumulativeTokens;

/*
	Primitives
	
	These must be invoked inside a candidate scan block.
 */

- (_RMXPathToken *)scanCommentOpen;
- (NSArray *)scanExpressionComment;

/*
	Composites
	
	Support for comments anywhere there's whitespace is baked into this scanner.
	These must be invoked inside a candidate scan block as they may add comment nodes to the scan.
	
	If whitespace skipping is on when one of these methods is called, it may also append comment nodes to the current candidate scan.
 */

- (BOOL)scanString:(NSString *)string intoString:(NSString **)valueRef;
- (BOOL)scanDecimal:(NSDecimal *)decimalRef;
- (BOOL)scanCharacterFromSet:(NSCharacterSet *)characterSet intoString:(NSString **)valueRef;

@end
