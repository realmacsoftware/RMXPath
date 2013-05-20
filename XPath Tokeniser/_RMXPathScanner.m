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

#import "_RMXPathScanner.h"

#import "_RMXPathToken.h"

#import "NSString+RMUnicodeAdditions.h"

#import "RMXPath-Macros.h"

@interface _RMXPathScanner ()
@property (readwrite, copy, nonatomic) NSString *string;
@property (retain, nonatomic) NSMutableArray *allowsWhitespaceCharactersStack;

- (NSScanner *)_makeScanner NS_RETURNS_RETAINED;

@property (retain, nonatomic) id candidateSectionInfo;

@property (readonly) BOOL insideCandidateScan;
@property (retain, nonatomic) NSMutableArray *currentCandidateScanTokens;

@property (readwrite, retain, nonatomic) NSArray *longestCurrentTokens;
@property (assign, nonatomic) NSUInteger longestCurrentTokensLength;
@property (retain, nonatomic) id longestCurrentTokensUserInfo;

@property (readwrite, retain, nonatomic) NSArray *cumulativeTokens;

- (BOOL)_substring:(NSString *)string isSubsetOfCharacterSet:(NSCharacterSet *)characterSet;
@end

@implementation _RMXPathScanner

@synthesize string=_string;
@synthesize scanLocation=_scanLocation;
@synthesize allowsWhitespaceCharactersStack=_allowsWhitespaceCharactersStack;

@synthesize candidateSectionInfo=_candidateSectionInfo;

@synthesize currentCandidateScanTokens=_currentCandidateScanTokens;

@synthesize longestCurrentTokens=_longestCurrentTokens, longestCurrentTokensLength=_longestCurrentTokensLength, longestCurrentTokensUserInfo=_longestCurrentTokensUserInfo;

@synthesize cumulativeTokens=_cumulativeTokens;

- (id)init {
	self = [super init];
	if (self == nil) return nil;
	
	_allowsWhitespaceCharactersStack = [[NSMutableArray alloc] init];
	
	_cumulativeTokens = [[NSMutableArray alloc] init];
	
	return self;
}

- (id)initWithString:(NSString *)string {
	self = [self init];
	if (self == nil) return nil;
	
	_string = [string copy];
	
	return self;
}

- (void)dealloc {
	[_string release];
	[_allowsWhitespaceCharactersStack release];
	
	[_candidateSectionInfo release];
	
	[_currentCandidateScanTokens release];
	
	[_longestCurrentTokens release];
	[_longestCurrentTokensUserInfo release];
	
	[_cumulativeTokens release];
	
	[super dealloc];
}

- (BOOL)isAtEnd {
	return ([self scanLocation] >= [[self string] length]);
}

- (void)_printRemainder {
	fprintf(stderr, "@\"%s\"", [[[self string] substringFromIndex:[self scanLocation]] UTF8String]);
}

typedef NS_ENUM(NSUInteger, _RMXPathScannerAllows) {
	_RMXPathScannerAllowsWhitespace = 1 << 0,
	_RMXPathScannerAllowsComments = 1 << 1,
	
	_RMXPathScannerAllowsAll = NSUIntegerMax,
};

- (void)pushAllowsWhitespaceCharacters:(BOOL)allowsWhitespaceCharacters {
	[[self allowsWhitespaceCharactersStack] addObject:[NSNumber numberWithInteger:(allowsWhitespaceCharacters ? _RMXPathScannerAllowsAll : 0)]];
}

- (void)popAllowsWhitespaceCharacters {
	NSParameterAssert([[self allowsWhitespaceCharactersStack] count] > 0);
	[[self allowsWhitespaceCharactersStack] removeLastObject];
}

- (NSUInteger)allowsWhitespaceCharacters {
	return [[[self allowsWhitespaceCharactersStack] lastObject] integerValue];
}

- (NSScanner *)_makeScanner {
	NSScanner *scanner = [[NSScanner alloc] initWithString:[self string]];
	[scanner setScanLocation:[self scanLocation]];
	[scanner setCharactersToBeSkipped:nil];
	return scanner;
}

- (void)startCandidateSection:(id)userInfo {
	[self setCandidateSectionInfo:userInfo];
}

- (void)measureCandidateScan:(BOOL (^)(_RMXPathScanner *, NSMutableArray *))scanBlock {
	NSParameterAssert([self candidateSectionInfo] != nil);
	NSParameterAssert(![self insideCandidateScan]);
	
	NSUInteger startScanLocation = [self scanLocation];
	
	NSMutableArray *currentCandidateScanTokens = [NSMutableArray array];
	
	[self setCurrentCandidateScanTokens:currentCandidateScanTokens];
	BOOL candidate = scanBlock(self, currentCandidateScanTokens);
	[self setCurrentCandidateScanTokens:nil];
	
	if (!candidate || [currentCandidateScanTokens count] == 0) {
		[self setScanLocation:startScanLocation];
		return;
	}
	
	NSUInteger endScanLocation = [self scanLocation];
	[self setScanLocation:startScanLocation];
	
	NSUInteger scanLength = (endScanLocation - startScanLocation);
	if (scanLength <= [self longestCurrentTokensLength]) {
		return;
	}
	
	[self setLongestCurrentTokens:[[currentCandidateScanTokens copy] autorelease]];
	[self setLongestCurrentTokensLength:scanLength];
	[self setLongestCurrentTokensUserInfo:[self candidateSectionInfo]];
}

- (void)endCandidateSection {
	[self setCandidateSectionInfo:nil];
}

- (id)commitCandidate {
	NSParameterAssert([self candidateSectionInfo] == nil);
	
	NSArray *longestCurrentTokens = [[[self longestCurrentTokens] retain] autorelease];
	if (longestCurrentTokens == nil) {
		return nil;
	}
	
	[(NSMutableArray *)_cumulativeTokens addObjectsFromArray:longestCurrentTokens];
	[self setLongestCurrentTokens:nil];
	
	[self setScanLocation:([self scanLocation] + [self longestCurrentTokensLength])];
	[self setLongestCurrentTokensLength:0];
	
	id longestCurrentTokensUserInfo = [[[self longestCurrentTokensUserInfo] retain] autorelease];
	NSParameterAssert(longestCurrentTokensUserInfo != nil);
	[self setLongestCurrentTokensUserInfo:nil];
	
	return longestCurrentTokensUserInfo;
}

- (NSArray *)cumulativeTokens {
	return [[_cumulativeTokens copy] autorelease];
}

#pragma mark -

- (BOOL)insideCandidateScan {
	return ([self currentCandidateScanTokens] != nil);
}

- (void)_assertCanScan {
	NSAssert([self candidateSectionInfo] != nil, @"must have a candidate section open before scanning");
	NSAssert([self insideCandidateScan], @"must be inside a candidate scan block before scanning");
}

#pragma mark -

- (_RMXPathToken *)scanCommentOpen {
	[self _assertCanScan];
	
	NSUInteger startScanLocation = [self scanLocation];
	
	[[self allowsWhitespaceCharactersStack] addObject:[NSNumber numberWithInteger:_RMXPathScannerAllowsWhitespace]];
	rm_scoped_block_t cleanupAllowsWhitespaceCharacterStack = ^ {
		[[self allowsWhitespaceCharactersStack] removeLastObject];
	};
	
	_RMXPathToken *commentStartToken = [[[_RMXPathTokenClass(CommentOpen) alloc] initWithString:@"(:"] autorelease];
	
	BOOL scan = [self scanString:[commentStartToken string] intoString:NULL];
	if (!scan) {
		[self setScanLocation:startScanLocation];
		return nil;
	}
	
	return commentStartToken;
}

static inline NSRange characterRangeForStartAndEndCharacter(NSInteger start, NSInteger end) {
	return NSMakeRange(start, (end - start) + 1);
}

+ (NSCharacterSet *)_commentCharacterSet {
	static NSCharacterSet *characterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		/*
			Note
			
			acceptable characters documented <http://www.w3.org/TR/REC-xml/#NT-Char>
		 */
		NSMutableCharacterSet *newCharacterSet = [[NSMutableCharacterSet alloc] init];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* #x9 */ 9, 9)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* #xA */ 10, 10)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* #xD */ 13, 13)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x20-#xD7FF] */ 32, 55295)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xE000-#xFFFD] */ 57344, 65533)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x10000-#x10FFFF] */ 65536, 1114111)];
		characterSet = newCharacterSet;
	});
	
	return characterSet;
}

- (NSArray *)scanExpressionComment {
	[self _assertCanScan];
	
	[[self allowsWhitespaceCharactersStack] addObject:[NSNumber numberWithInteger:0]];
	rm_scoped_block_t cleanupCharactersToBeSkipped = ^ {
		[[self allowsWhitespaceCharactersStack] removeLastObject];
	};
	
	NSMutableArray *tokens = [NSMutableArray array];
	_RMXPathToken *lastToken = nil;
	
	_RMXPathToken *commentCloseToken = [[[_RMXPathTokenClass(CommentClose) alloc] initWithString:@":)"] autorelease];
	
	NSString * (^matchChar)(void) = ^ NSString * (void) {
		NSString *scannedString = nil;
		BOOL scan = [self scanCharacterFromSet:[_RMXPathScanner _commentCharacterSet] intoString:&scannedString];
		if (!scan) {
			return nil;
		}
		
		return scannedString;
	};
	
	NSUInteger depth = 1;
	while (depth > 0) {
		// pop()
		if (
			[self scanString:[commentCloseToken string] intoString:NULL]
			) {
			depth--;
			lastToken = nil;
			
			[tokens addObject:commentCloseToken];
			continue;
		}
		
		// pushState()
		// -> EXPR_COMMENT
		_RMXPathToken *commentStartToken = [self scanCommentOpen];
		if (
			commentStartToken != nil
			) {
			depth++;
			lastToken = nil;
			
			[tokens addObject:commentStartToken];
			continue;
		}
		
		// maintain()
		NSString *character = matchChar();
		if (character != nil) {
			if (lastToken == nil) {
				lastToken = [[[_RMXPathTokenClass(CommentContent) alloc] initWithString:character] autorelease];
				[tokens addObject:lastToken];
			}
			else {
				[lastToken appendString:character];
			}
			continue;
		}
		
#if 0
		if (errorRef != NULL) {
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   NSLocalizedStringFromTableInBundle(@"XPath contains unterminated comment", nil, [NSBundle bundleWithIdentifier:RMFoundationBundleIdentifier], @"RMXPath tokenise unterminated comment error description"), NSLocalizedDescriptionKey,
									   nil];
			*errorRef = [NSError errorWithDomain:RMFoundationBundleIdentifier code:RMFoundationErrorCodeUnknown userInfo:errorInfo];
		}
#endif
		return nil;
	}
	
	return tokens;
}

#pragma mark -

- (void)_greedilyMatchAllEnabledWhitespace {
	[self _assertCanScan];
	
	NSUInteger allowWhitespaceEnables = [self allowsWhitespaceCharacters];
	BOOL scanWhitespace = ((allowWhitespaceEnables & _RMXPathScannerAllowsWhitespace) == _RMXPathScannerAllowsWhitespace);
	BOOL scanComments = ((allowWhitespaceEnables & _RMXPathScannerAllowsComments) == _RMXPathScannerAllowsComments);
	
	[[self allowsWhitespaceCharactersStack] addObject:[NSNumber numberWithInteger:0]];
	rm_scoped_block_t cleanupAllowsWhitespaceCharactersStack = ^ {
		[[self allowsWhitespaceCharactersStack] removeLastObject];
	};
	
	NSMutableArray *currentCandidateScanTokens = [self currentCandidateScanTokens];
	
	while (1) {
		NSUInteger startTerminalCount = [currentCandidateScanTokens count];
		
		if (scanWhitespace) {
			NSString *string = [self string];
			NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			
			NSUInteger scanLocation = [self scanLocation];
			
			while (scanLocation < [string length]) {
				NSRange candidateRange = [string rangeOfComposedCharacterSequenceAtIndex:scanLocation];
				
				NSString *substring = [string substringWithRange:candidateRange];
				if (![self _substring:substring isSubsetOfCharacterSet:characterSet]) {
					break;
				}
				
				scanLocation = NSMaxRange(candidateRange);
			}
			
			[self setScanLocation:scanLocation];
		}
		
		if (scanComments) {
			do {
				_RMXPathToken *commentStart = [self scanCommentOpen];
				if (commentStart == nil) {
					break;
				}
				
				NSArray *commentTokens = [self scanExpressionComment];
				if (commentTokens == nil) {
					break;
				}
				
				[currentCandidateScanTokens addObject:commentStart];
				[currentCandidateScanTokens addObjectsFromArray:commentTokens];
			} while (0);
		}
		
		if (startTerminalCount == [currentCandidateScanTokens count]) {
			break;
		}
	}
}

- (BOOL)scanString:(NSString *)string intoString:(NSString **)valueRef {
	[self _assertCanScan];
	
	[self _greedilyMatchAllEnabledWhitespace];
	
	NSScanner *scanner = [self _makeScanner];
	BOOL scan = [scanner scanString:string intoString:valueRef];
	if (!scan) {
		[scanner release];
		return NO;
	}
	
	[self setScanLocation:[scanner scanLocation]];
	[scanner release];
	
	return YES;
}

- (BOOL)scanDecimal:(NSDecimal *)decimalRef {
	[self _assertCanScan];
	
	[self _greedilyMatchAllEnabledWhitespace];
	
	NSScanner *scanner = [self _makeScanner];
	
	BOOL scan = [scanner scanDecimal:decimalRef];
	if (!scan) {
		[scanner release];
		return NO;
	}
	
	[self setScanLocation:[scanner scanLocation]];
	[scanner release];
	
	return YES;
}

- (BOOL)scanCharacterFromSet:(NSCharacterSet *)characterSet intoString:(NSString **)valueRef {
	[self _assertCanScan];
	
	[self _greedilyMatchAllEnabledWhitespace];
	
	NSUInteger startScanLocation = [self scanLocation];
	
	NSString *string = [self string];
	if (startScanLocation >= [string length]) {
		return NO;
	}
	
	/*
		Note
		
		NSString stores its data in UTF-16
	 */
	NSRange composedCharacterRange = [string rangeOfComposedCharacterSequenceAtIndex:startScanLocation];
	NSString *characterString = [string substringWithRange:composedCharacterRange];
	
	if (![self _substring:characterString isSubsetOfCharacterSet:characterSet]) {
		return NO;
	}
	
	[self setScanLocation:(startScanLocation + composedCharacterRange.length)];
	
	if (valueRef != NULL) {
		*valueRef = characterString;
	}
	
	return YES;
}

- (BOOL)_substring:(NSString *)string isSubsetOfCharacterSet:(NSCharacterSet *)characterSet {
	uint32_t *codepoints = NULL; size_t codepointsLength = 0;
	BOOL getCodepoints = [string getCodepoints:&codepoints length:&codepointsLength];
	if (!getCodepoints) {
		return NO;
	}
	
	BOOL allMembers = YES;
	for (NSUInteger idx = 0; idx < codepointsLength; idx++) {
		if ([characterSet characterIsMember:codepoints[idx]]) {
			continue;
		}
		
		allMembers = NO;
		break;
	}
	
	free(codepoints);
	
	return allMembers;
}

@end
