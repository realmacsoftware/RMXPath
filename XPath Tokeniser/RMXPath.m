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

#import "RMXPath.h"

#import "_RMXPathToken.h"
#import "_RMXPathScanner.h"

#import "RMXPath-Macros.h"
#import "RMXPath-Constants.h"

#pragma mark - Matchers

static NSString * (^matchString)(_RMXPathScanner *, NSString *) = ^ NSString * (_RMXPathScanner *scanner, NSString *string) {
	NSString *scannedString = nil;
	BOOL scan = [scanner scanString:string intoString:&scannedString];
	if (!scan) {
		return nil;
	}
	
	return scannedString;
};

static NSString * (^matchCharFromCharacterSet)(_RMXPathScanner *, NSCharacterSet *) = ^ NSString * (_RMXPathScanner *scanner, NSCharacterSet *characterSet) {
	NSString *scannedString = nil;
	BOOL scan = [scanner scanCharacterFromSet:characterSet intoString:&scannedString];
	if (!scan) {
		return nil;
	}
	
	return scannedString;
};

static NSRange (^characterRangeForStartAndEndCharacter)(NSInteger, NSInteger) = ^ NSRange (NSInteger start, NSInteger end) {
	return NSMakeRange(start, (end - start) + 1);
};

static BOOL (^matchComposedTerminalsWithVariableLengthWhitespaceSeparation)(_RMXPathScanner *, NSArray *, NSMutableArray *) = ^ BOOL (_RMXPathScanner *scanner, NSArray *terminalTokens, NSMutableArray *matchedTerminals) {
	NSUInteger startScanLocation = [scanner scanLocation];
	
	for (_RMXPathToken *currentTerminalToken in terminalTokens) {
		if ([currentTerminalToken isKindOfClass:[_RMXPathTokenClass(__LookAhead__) class]]) {
			_RMXPathToken__LookAhead__ *lookAheadToken = (id)currentTerminalToken;
			
			[scanner pushAllowsWhitespaceCharacters:[lookAheadToken allowsPrecedingWhitespace]];
			rm_scoped_block_t cleanupCharactersToBeSkipped = ^ {
				[scanner popAllowsWhitespaceCharacters];
			};
			
			BOOL scanTerminal = [scanner scanString:[lookAheadToken string] intoString:NULL];
			if (scanTerminal == [lookAheadToken isNegative]) {
				[scanner setScanLocation:startScanLocation];
				return NO;
			}
			
			continue;
		}
		
		if ([currentTerminalToken isKindOfClass:_RMXPathTokenClass()]) {
			BOOL scanTerminal = [scanner scanString:[currentTerminalToken string] intoString:NULL];
			if (!scanTerminal) {
				[scanner setScanLocation:startScanLocation];
				return NO;
			}
			
			[matchedTerminals addObject:currentTerminalToken];
			continue;
		}
		
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s, unknown terminal class (%@)", __PRETTY_FUNCTION__, [currentTerminalToken class]] userInfo:nil];
		return NO;
	}
	
	return ([scanner scanLocation] > startScanLocation);
};

/*
	<http://www.w3.org/TR/REC-xml/#NT-Name>
 */

static NSCharacterSet * (^nameStartCharCharacterSet)(void) = ^ NSCharacterSet * (void) {
	static NSCharacterSet *characterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		NSMutableCharacterSet *newCharacterSet = [[NSMutableCharacterSet alloc] init];
		[newCharacterSet addCharactersInString:@":"];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter('A', 'Z')];
		[newCharacterSet addCharactersInString:@"_"];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter('a', 'z')];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xC0-#xD6] */ 192, 214)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xD8-#xF6] */ 216, 246)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xF8-#x2FF] */ 248, 255)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x370-#x37D] */ 880, 893)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x37F-#x1FFF] */ 895, 8191)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x200C-#x200D] */ 8204, 8205)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x2070-#x218F] */ 8304, 8639)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x2C00-#x2FEF] */ 11264, 12271)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x3001-#xD7FF] */ 12289, 55295)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xF900-#xFDCF] */ 63744, 64975)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#xFDF0-#xFFFD] */ 65008, 65533)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x10000-#xEFFFF] */ 65536, 983039)];
		characterSet = newCharacterSet;
	});
	
	return characterSet;
};

static NSCharacterSet * (^nameCharCharacterSet)(void) = ^ NSCharacterSet * (void) {
	static NSCharacterSet *characterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		NSMutableCharacterSet *newCharacterSet = [[NSMutableCharacterSet alloc] init];
		[newCharacterSet formUnionWithCharacterSet:nameStartCharCharacterSet()];
		[newCharacterSet addCharactersInString:@"-.0123456789"];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* #xB7 */ 183, 183)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x0300-#x036F] */ 768, 879)];
		[newCharacterSet addCharactersInRange:characterRangeForStartAndEndCharacter(/* [#x203F-#x2040] */ 8255, 8256)];
		characterSet = newCharacterSet;
	});
	
	return characterSet;
};

static NSString * (^matchNameWithStartAndBodyCharacter)(_RMXPathScanner *, NSCharacterSet *, NSCharacterSet *) = ^ NSString * (_RMXPathScanner *scanner, NSCharacterSet *startCharacterSet, NSCharacterSet *bodyCharacter) {
	NSMutableString *string = [NSMutableString string];
	
	NSString *startCharacter = matchCharFromCharacterSet(scanner, startCharacterSet);
	if (startCharacter == nil) {
		return NO;
	}
	[string appendString:startCharacter];
	
	[scanner pushAllowsWhitespaceCharacters:NO];
	rm_scoped_block_t cleanupCharactersToBeSkipped = ^ {
		[scanner popAllowsWhitespaceCharacters];
	};
	
	while (1) {
		NSString *bodyString = matchCharFromCharacterSet(scanner, bodyCharacter);
		if (bodyString == nil) {
			break;
		}
		[string appendString:bodyString];
	}
	
	return string;
};

__unused static NSString * (^matchName)(_RMXPathScanner *) = ^ NSString * (_RMXPathScanner *scanner) {
	return matchNameWithStartAndBodyCharacter(scanner, nameStartCharCharacterSet(), nameCharCharacterSet());
};

static NSString * (^matchNCName)(_RMXPathScanner *scanner) = ^ NSString * (_RMXPathScanner *scanner) {
	static NSCharacterSet *ncNameStartCharCharacterSet = nil;
	static NSCharacterSet *ncNameCharCharacterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		NSMutableCharacterSet *newNcNameStartCharCharacterSet = [nameStartCharCharacterSet() mutableCopy];
		[newNcNameStartCharCharacterSet removeCharactersInString:@":"];
		ncNameStartCharCharacterSet = newNcNameStartCharCharacterSet;
		
		NSMutableCharacterSet *newNcNameCharCharacterSet = [nameCharCharacterSet() mutableCopy];
		[newNcNameCharCharacterSet removeCharactersInString:@":"];
		ncNameCharCharacterSet = newNcNameCharCharacterSet;
	});
	
	return matchNameWithStartAndBodyCharacter(scanner, ncNameStartCharCharacterSet, ncNameCharCharacterSet);
};

static NSString * (^matchPrefixedName)(_RMXPathScanner *) = ^ NSString * (_RMXPathScanner *scanner) {
	NSUInteger startScanLocation = [scanner scanLocation];
	
	NSString *prefix = matchNCName(scanner);
	if (prefix == nil) {
		return nil;
	}
	
	[scanner pushAllowsWhitespaceCharacters:NO];
	rm_scoped_block_t cleanupCharactersToBeSkipped = ^ {
		[scanner popAllowsWhitespaceCharacters];
	};
	
	NSString *separator = matchString(scanner, @":");
	if (separator == nil) {
		[scanner setScanLocation:startScanLocation];
		return NO;
	}
	
	NSString *suffix = matchNCName(scanner);
	if (suffix == nil) {
		[scanner setScanLocation:startScanLocation];
		return NO;
	}
	
	return [[NSArray arrayWithObjects:prefix, separator, suffix, nil] componentsJoinedByString:@""];
};

static NSString * (^matchUnprefixedName)(_RMXPathScanner *) = ^ NSString * (_RMXPathScanner *scanner) {
	return matchNCName(scanner);
};

static NSString * (^matchQName)(_RMXPathScanner *) = ^ NSString * (_RMXPathScanner *scanner) {
	NSString *string = nil;
	if (string == nil) {
		string = matchPrefixedName(scanner);
	}
	if (string == nil) {
		string = matchUnprefixedName(scanner);
	}
	return string;
};

static NSString * (^matchWildcard)(_RMXPathScanner *) = ^ NSString * (_RMXPathScanner *scanner) {
	/*
		Note
		
		are we sure that all these are wildcards and not multipliers?
	 */
	return matchString(scanner, @"*");
};

static NSArray * (^matchQuotedStringLiteral)(_RMXPathScanner *, NSString *, NSCharacterSet *) = ^ NSArray * (_RMXPathScanner *scanner, NSString *quoteCharacter, NSCharacterSet *exceptQuoteCharCharacterSet) {
	NSCParameterAssert([quoteCharacter length] == 1);
	NSCParameterAssert(![exceptQuoteCharCharacterSet characterIsMember:[quoteCharacter characterAtIndex:0]]);
	
	NSMutableArray *stringLiteralTokens = [NSMutableArray array];
	
	NSUInteger startScanLocation = [scanner scanLocation];
	
	NSString *startCharacter = matchString(scanner, quoteCharacter);
	if (startCharacter == nil) {
		return nil;
	}
	_RMXPathToken *stringLiteralOpenToken = [[[_RMXPathTokenClass(StringLiteralOpen) alloc] initWithString:startCharacter] autorelease];
	[stringLiteralTokens addObject:stringLiteralOpenToken];
	
	[scanner pushAllowsWhitespaceCharacters:NO];
	rm_scoped_block_t cleanupCharactersToBeSkipped = ^ {
		[scanner popAllowsWhitespaceCharacters];
	};
	
	NSMutableString *stringLiteralContent = [NSMutableString string];
	NSString *escapedQuotePair = [[NSArray arrayWithObjects:quoteCharacter, quoteCharacter, nil] componentsJoinedByString:@""];
	while (1) {
		NSString *currentString = nil;
		if (currentString == nil) {
			currentString = matchString(scanner, escapedQuotePair);
		}
		if (currentString == nil) {
			currentString = matchCharFromCharacterSet(scanner, exceptQuoteCharCharacterSet);
		}
		if (currentString == nil) {
			break;
		}
		
		[stringLiteralContent appendString:currentString];
	}
	_RMXPathToken *stringLiteralContentToken = [[[_RMXPathTokenClass(StringLiteralContent) alloc] initWithString:stringLiteralContent] autorelease];
	[stringLiteralTokens addObject:stringLiteralContentToken];
	
	NSString *endCharacter = matchString(scanner, quoteCharacter);
	if (endCharacter == nil) {
		[scanner setScanLocation:startScanLocation];
		return nil;
	}
	_RMXPathToken *stringLiteralCloseToken = [[[_RMXPathTokenClass(StringLiteralClose) alloc] initWithString:endCharacter] autorelease];
	[stringLiteralTokens addObject:stringLiteralCloseToken];
	
	return stringLiteralTokens;
};

static NSArray * (^matchDoubleQuotedStringLiteral)(_RMXPathScanner *) = ^ NSArray * (_RMXPathScanner *scanner) {
	NSString *doubleQuotedStringLiteralChar = @"\"";
	
	static NSCharacterSet *doubleQuotedStringLiteralCharCharacterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		NSMutableCharacterSet *newCharacterSet = [[NSMutableCharacterSet alloc] init];
		[newCharacterSet addCharactersInString:doubleQuotedStringLiteralChar];
		[newCharacterSet invert];
		doubleQuotedStringLiteralCharCharacterSet = newCharacterSet;
	});
	
	/* ('"' (('"' '"') | [^"])* '"') */
	return matchQuotedStringLiteral(scanner, doubleQuotedStringLiteralChar, doubleQuotedStringLiteralCharCharacterSet);
};

static NSArray * (^matchSingleQuotedStringLiteral)(_RMXPathScanner *) = ^ NSArray * (_RMXPathScanner *scanner) {
	NSString *singleQuotedStringLiteralChar = @"'";
	
	static NSCharacterSet *singleQuotedStringLiteralCharCharacterSet = nil;
	static dispatch_once_t characterSetPredicate = 0;
	
	dispatch_once(&characterSetPredicate, ^ {
		NSMutableCharacterSet *newCharacterSet = [[NSMutableCharacterSet alloc] init];
		[newCharacterSet addCharactersInString:singleQuotedStringLiteralChar];
		[newCharacterSet invert];
		singleQuotedStringLiteralCharCharacterSet = newCharacterSet;
	});
	
	/* ("'" (("'" "'") | [^'])* "'") */
	return matchQuotedStringLiteral(scanner, singleQuotedStringLiteralChar, singleQuotedStringLiteralCharCharacterSet);
};

#pragma mark - XPath Tokeniser

NSArray *RMFoundationXPathTokenise(NSString *XPath, NSError **errorRef) {
	NSUInteger XPathLength = [XPath length];
	if (XPathLength == 0) {
		return [NSArray array];
	}
	
	/*
		Note
		
		scanner built from reference lexical states and transitions documented in <http://www.w3.org/TR/xquery-xpath-parsing/#XPath-lexical-states>
	 */
	
	_RMXPathScanner *XPathScanner = [[[_RMXPathScanner alloc] initWithString:XPath] autorelease];
	[XPathScanner pushAllowsWhitespaceCharacters:YES];
	
	void (^scanComposedTerminalsWithVariableLengthWhitespaceSeparation)(NSArray *) = ^ void (NSArray *terminals) {
		NSMutableArray *terminalTokens = [NSMutableArray arrayWithCapacity:[terminals count]];
		for (NSString *currentTerminal in terminals) {
			_RMXPathToken *currentTerminalToken = [[[_RMXPathTokenClass() alloc] initWithString:currentTerminal] autorelease];
			[terminalTokens addObject:currentTerminalToken];
		}
		
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			return matchComposedTerminalsWithVariableLengthWhitespaceSeparation(scanner, terminalTokens, candidateTokens);
		}];
	};
	
#pragma mark - Helper Scanners
	
	void (^scanNumberLiteralWithClass)(Class) = ^ void (Class numberClass) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSUInteger startScanLocation = [XPathScanner scanLocation];
			
			BOOL scan = [XPathScanner scanDecimal:NULL];
			if (!scan) {
				return NO;
			}
			
			NSUInteger endScanLocation = [XPathScanner scanLocation];
			
			NSString *scannedString = [[XPathScanner string] substringWithRange:NSMakeRange(startScanLocation, endScanLocation - startScanLocation)];
			
			_RMXPathToken *numberToken = [[[numberClass alloc] initWithString:scannedString] autorelease];
			
			[candidateTokens addObject:numberToken];
			return YES;
		}];
	};
	void (^scanDecimalLiteral)(void) = ^ void (void) {
		scanNumberLiteralWithClass(_RMXPathTokenClass(DecimalLiteral));
	};
	void (^scanDoubleLiteral)(void) = ^ void (void) {
		scanNumberLiteralWithClass(_RMXPathTokenClass(DoubleLiteral));
	};
	void (^scanIntegerLiteral)(void) = ^ void (void) {
		scanNumberLiteralWithClass(_RMXPathTokenClass(IntegerLiteral));
	};
	
	void (^scanToken)(_RMXPathToken *) = ^ void (_RMXPathToken *token) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *scannedString = matchString(scanner, [token string]);
			if (scannedString == nil) {
				return NO;
			}
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanStringWithClass)(Class, NSString *) = ^ void (Class tokenClass, NSString *string) {
		_RMXPathToken *token = [[[tokenClass alloc] initWithString:string] autorelease];
		scanToken(token);
	};
	
	BOOL (^scanNotNumber)(void) = ^ BOOL (void) {
		/*
			Note
			
			lexeme not defined in the XPath EBNF
		 */
		return NO;
	};
	
	void (^scanNCName)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *string = matchNCName(scanner);
			if (string == nil) {
				return NO;
			}
			
			_RMXPathToken *token = [[[_RMXPathTokenClass() alloc] initWithString:string] autorelease];
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanQName)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *string = matchQName(scanner);
			if (string == nil) {
				return NO;
			}
			
			_RMXPathToken *token = [[[_RMXPathTokenClass(QName) alloc] initWithString:string] autorelease];
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanWildcard)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *string = matchWildcard(scanner);
			if (string == nil) {
				return NO;
			}
			
			_RMXPathToken *token = [[[_RMXPathTokenClass() alloc] initWithString:string] autorelease];
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanNCNamePrefixWithWildcardLocalName)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *prefix = matchNCName(scanner);
			if (prefix == nil) {
				return NO;
			}
			
			NSString *separator = matchString(scanner, @":");
			if (separator == nil) {
				return NO;
			}
			
			NSString *suffix = matchWildcard(scanner);
			if (suffix == nil) {
				return NO;
			}
			
			NSString *string = [[NSArray arrayWithObjects:prefix, separator, suffix, nil] componentsJoinedByString:@""];
			
			_RMXPathToken *token = [[[_RMXPathTokenClass(QName) alloc] initWithString:string] autorelease];
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	void (^scanWildcardPrefixWithNCNameLocalName)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSString *prefix = matchWildcard(scanner);
			if (prefix == nil) {
				return NO;
			}
			
			NSString *separator = matchString(scanner, @":");
			if (separator == nil) {
				return NO;
			}
			
			NSString *suffix = matchNCName(scanner);
			if (suffix == nil) {
				return NO;
			}
			
			NSString *string = [[NSArray arrayWithObjects:prefix, separator, suffix, nil] componentsJoinedByString:@""];
			
			_RMXPathToken *token = [[[_RMXPathTokenClass(QName) alloc] initWithString:string] autorelease];
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanQNameWithOpeningParenthesis)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSUInteger startScanLocation = [XPathScanner scanLocation];
			
			NSString *qname = matchQName(scanner);
			if (qname == nil) {
				return NO;
			}
			[XPathScanner setScanLocation:startScanLocation];
			
			NSMutableArray *matchTerminals = [NSMutableArray array];
			
			_RMXPathToken *qnameToken = [[[_RMXPathTokenClass(QName) alloc] initWithString:qname] autorelease];
			[matchTerminals addObject:qnameToken];
			
			_RMXPathToken *openParenthesis = [[[_RMXPathTokenClass() alloc] initWithString:@"("] autorelease];
			[matchTerminals addObject:openParenthesis];
			
			_RMXPathToken__LookAhead__ *notCommentLookAhead = [[[_RMXPathTokenClass(__LookAhead__) alloc] initWithString:@":"] autorelease];
			[notCommentLookAhead setNegative:YES];
			[notCommentLookAhead setAllowsPrecedingWhitespace:NO];
			[matchTerminals addObject:notCommentLookAhead];
			
			return matchComposedTerminalsWithVariableLengthWhitespaceSeparation(scanner, matchTerminals, candidateTokens);
		}];
	};
	
	void (^scanStringLiteral)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			NSArray *tokens = nil;
			if (tokens == nil) {
				tokens = matchDoubleQuotedStringLiteral(scanner);
			}
			if (tokens == nil) {
				tokens = matchSingleQuotedStringLiteral(scanner);
			}
			if (tokens == nil) {
				return NO;
			}
			
			[candidateTokens addObjectsFromArray:tokens];
			return YES;
		}];
	};
	
	void (^scanNotOperatorKeyword)(void) = ^ void (void) {
		/*
			Note
			
			lexeme not defined in the XPath EBNF
		 */
		return;
	};
	
	void (^scanObjectStart)(void) = ^ void (void) {
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"element", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"attribute", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"schema-attribute", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"comment", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"text", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"node", @"(", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"document-node", @"(", nil]);
	};
	
	void (^scanProcessingInstructionStart)(void) = ^ void (void) {
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"processing-instruction", @"(", nil]);
	};
	
	void (^scanOperator)(NSString *) = ^ void (NSString *operator) {
		_RMXPathTokenOperator *token = [[[_RMXPathTokenClass(Operator) alloc] initWithString:operator] autorelease];
		scanToken(token);
	};
	
	void (^scanOperatorFromList)(void) = ^ void (void) {
		scanOperator(@"then");
		scanOperator(@"else");
		scanOperator(@"and");
		scanOperator(@",");
		scanOperator(@"div");
		scanOperator(@"=");
		scanOperator(@"except");
		scanOperator(@"eq");
		scanOperator(@"ge");
		scanOperator(@"gt");
		scanOperator(@"le");
		scanOperator(@"lt");
		scanOperator(@"ne");
		scanOperator(@">=");
		scanOperator(@">>");
		scanOperator(@">");
		scanOperator(@"idiv");
		scanOperator(@"intersect");
		scanOperator(@"in");
		scanOperator(@"is");
		scanOperator(@"[");
		scanOperator(@"<=");
		scanOperator(@"<<");
		scanOperator(@"<");
		scanOperator(@"-");
		scanOperator(@"mod");
		scanOperator(@"*");
		scanOperator(@"!=");
		scanOperator(@"or");
		scanOperator(@"+");
		scanOperator(@"return");
		scanOperator(@"satisfies");
		scanOperator(@"//");
		scanOperator(@"/");
		scanOperator(@"to");
		scanOperator(@"union");
		scanOperator(@"|");
	};
	
	void (^scanCastableStart)(void) = ^ void (void) {
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"castable", @"as", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"cast", @"as", nil]);
	};
	
	void (^scanInstanceStart)(void) = ^ void (void) {
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"instance", @"of", nil]);
		scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"treat", @"as", nil]);
	};
	
	void (^scanCommentStart)(void) = ^ void (void) {
		[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
			_RMXPathToken *token = [scanner scanCommentOpen];
			if (token == nil) {
				return NO;
			}
			
			[candidateTokens addObject:token];
			return YES;
		}];
	};
	
	void (^scanNotOccurrenceIndicator)(void) = ^ void (void) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unknown implementation" userInfo:nil];
	};
	
#pragma mark - Root Expression Scanners
	
	typedef void * (^scanner_t)(void);
	
	NSMutableArray *scannerState = [NSMutableArray array];
	
	void (^pushState)(scanner_t) = ^ void (scanner_t scanner) {
		[scannerState addObject:scanner];
	};
	
	scanner_t (^popState)(void) = ^ scanner_t (void) {
		scanner_t scanner = [scannerState lastObject];
		[scannerState removeLastObject];
		return scanner;
	};
	
	__block scanner_t scanError = [[^ {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unknown parser state, this exception is intended to be caught" userInfo:nil];
		return nil;
	} copy] autorelease];
	
	__block scanner_t syntaxError = [[^ {
		if (errorRef != NULL) {
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   NSLocalizedStringFromTableInBundle(@"XPath syntax invalid", nil, [NSBundle bundleWithIdentifier:RMXPathTokeniserBundleIdentifier], @"RMXPath invalid syntax error description"), NSLocalizedDescriptionKey,
									   nil];
			*errorRef = [NSError errorWithDomain:RMXPathTokeniserBundleIdentifier code:0 userInfo:errorInfo];
		}
		return scanError;
	} copy] autorelease];
	
	/*
		Note
		
		these lexical states and state transitions are from <http://www.w3.org/TR/xquery-xpath-parsing> §2
	 */
	
	__block scanner_t scanExpression = nil;
	__block scanner_t scanDefaultState = nil;
	__block scanner_t scanOperatorState = nil;
	__block scanner_t scanSingleType = nil;
	__block scanner_t scanItemType = nil;
	__block scanner_t scanKindTest = nil;
	__block scanner_t scanKindTestForProcessingInstruction = nil;
	__block scanner_t scanCloseKindTest = nil;
	__block scanner_t scanOccurrenceIndicator = nil;
	__block scanner_t scanVarname = nil;
	__block scanner_t scanExpressionComment = nil;
	
	scanExpression = [[^ scanner_t (void) {
		// -> DEFAULT
		return scanDefaultState;
	} copy] autorelease];
	
	scanDefaultState = [[^ scanner_t (void) {
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanDecimalLiteral();
			scanStringWithClass(_RMXPathTokenClass(), @"..");
			scanStringWithClass(_RMXPathTokenClass(), @".");
			scanDoubleLiteral();
			scanIntegerLiteral();
			scanNotNumber();
			scanNCNamePrefixWithWildcardLocalName();
			scanQName();
			scanStringWithClass(_RMXPathTokenClass(), @")");
			scanWildcardPrefixWithNCNameLocalName();
			scanWildcard();
			scanStringLiteral();
		}
		[XPathScanner endCandidateSection];
		
		// -> VARNAME
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanVarname;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @"$");
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"for", @"$", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"every", @"$", nil]);
		}
		[XPathScanner endCandidateSection];
		
		// pushState(OPERATOR)
		// -> KINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOperatorState);
			return scanKindTest;
		} copy] autorelease]];
		{
			scanObjectStart();
		}
		[XPathScanner endCandidateSection];
		
		// pushState(OPERATOR)
		// -> KINDTESTFORPI
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOperatorState);
			return scanKindTestForProcessingInstruction;
		} copy] autorelease]];
		{
			scanProcessingInstructionStart();
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanDefaultState);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> DEFAULT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanDefaultState;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @",");
			scanStringWithClass(_RMXPathTokenClass(), @"(");
			scanQNameWithOpeningParenthesis();
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"if", @"(", nil]);
			scanStringWithClass(_RMXPathTokenClass(Operator), @"-");
			scanStringWithClass(_RMXPathTokenClass(Operator), @"+");
			scanStringWithClass(_RMXPathTokenClass(Operator), @"//");
			scanStringWithClass(_RMXPathTokenClass(Operator), @"/");
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"ancestor-or-self", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"ancestor", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"attribute", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"child", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"descendant-or-self", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"descendant", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"following-sibling", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"following", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"namespace", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"parent", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"preceding-sibling", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"preceding", @"::", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"self", @"::", nil]);
			scanStringWithClass(_RMXPathTokenClass(), @"@");
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanOperatorState = [[^ scanner_t (void) {
		// -> DEFAULT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanDefaultState;
		} copy] autorelease]];
		{
			scanOperatorFromList();
		}
		[XPathScanner endCandidateSection];
		
		// -> SINGLETYPE
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanSingleType;
		} copy] autorelease]];
		{
			scanCastableStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> ITEMTYPE
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanItemType;
		} copy] autorelease]];
		{
			scanInstanceStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> VARNAME
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanVarname;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @"$");
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"for", @"$", nil]);
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOperatorState);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @")");
			scanStringWithClass(_RMXPathTokenClass(), @"?");
			scanStringWithClass(_RMXPathTokenClass(Operator), @"]");
		}
		[XPathScanner endCandidateSection];
		
		// maintain()
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanStringLiteral();
			scanNotOperatorKeyword();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanSingleType = [[^ scanner_t (void) {
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanQName();
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanSingleType);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanItemType = [[^ scanner_t (void) {
		void (^scanVoid)(void) = ^ void (void) {
			[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
				NSMutableArray *voidTerminals = [NSMutableArray array];
				
				_RMXPathToken *voidToken = [[[_RMXPathTokenClass() alloc] initWithString:@"void"] autorelease];
				[voidTerminals addObject:voidToken];
				
				_RMXPathToken *openParenthesisToken = [[[_RMXPathTokenClass() alloc] initWithString:@"("] autorelease];
				[voidTerminals addObject:openParenthesisToken];
				
				_RMXPathToken__LookAhead__ *notCommentLookAhead = [[[_RMXPathToken__LookAhead__ alloc] initWithString:@":"] autorelease];
				[notCommentLookAhead setNegative:YES];
				[notCommentLookAhead setAllowsPrecedingWhitespace:NO];
				[voidTerminals addObject:notCommentLookAhead];
				
				_RMXPathToken *closeParenthesisToken = [[[_RMXPathTokenClass() alloc] initWithString:@")"] autorelease];
				[voidTerminals addObject:closeParenthesisToken];
				
				return matchComposedTerminalsWithVariableLengthWhitespaceSeparation(XPathScanner, voidTerminals, candidateTokens);
			}];
		};
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanVoid();
			scanQName();
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanItemType);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		// pushState(OCCURRENCEINDICATOR)
		// -> KINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOccurrenceIndicator);
			return scanKindTest;
		} copy] autorelease]];
		{
			scanObjectStart();
		}
		[XPathScanner endCandidateSection];
		
		// pushState(OCCURRENCEINDICATOR)
		// -> KINDTESTFORPI
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOccurrenceIndicator);
			return scanKindTestForProcessingInstruction;
		} copy] autorelease]];
		{
			scanProcessingInstructionStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> OCCURRENCEINDICATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOccurrenceIndicator;
		} copy] autorelease]];
		{
			scanQName();
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"item", @"(", nil]);
		}
		[XPathScanner endCandidateSection];
		
		// -> DEFAULT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanDefaultState;
		} copy] autorelease]];
		{
			scanOperatorFromList();
		}
		[XPathScanner endCandidateSection];
		
		// -> SINGLETYPE
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanSingleType;
		} copy] autorelease]];
		{
			scanCastableStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> ITEMTYPE
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanItemType;
		} copy] autorelease]];
		{
			scanInstanceStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanKindTest = [[^ scanner_t (void) {
		// pop()
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return popState();
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @")");
		}
		[XPathScanner endCandidateSection];
		
		// -> CLOSEKINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanCloseKindTest;
		} copy] autorelease]];
		{
			scanWildcard();
			scanQName();
		}
		[XPathScanner endCandidateSection];
		
		// pushState(KINDTEST)
		// -> KINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanKindTest);
			return scanKindTest;
		} copy] autorelease]];
		{
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"element", @"(", nil]);
			scanComposedTerminalsWithVariableLengthWhitespaceSeparation([NSArray arrayWithObjects:@"schema-element", @"(", nil]);
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanKindTest);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanKindTestForProcessingInstruction = [[^ scanner_t (void) {
		// pop()
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return popState();
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @")");
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanKindTestForProcessingInstruction);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		// -> KINDTESTFORPI
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanKindTestForProcessingInstruction;
		} copy] autorelease]];
		{
			scanNCName();
			scanStringLiteral();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanCloseKindTest = [[^ scanner_t (void) {
		// pop()
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return popState();
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @")");
		}
		[XPathScanner endCandidateSection];
		
		// -> KINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanKindTest;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @",");
		}
		[XPathScanner endCandidateSection];
		
		// -> CLOSEKINDTEST
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanCloseKindTest;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @"?");
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanCloseKindTest);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanOccurrenceIndicator = [[^ scanner_t (void) {
		// inputStream.backup(1)
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"unimplemented inputStream.backup(1)" userInfo:nil];
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanNotOccurrenceIndicator();
		}
		[XPathScanner endCandidateSection];
		
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanStringWithClass(_RMXPathTokenClass(), @"?");
			scanStringWithClass(_RMXPathTokenClass(), @"*");
			scanStringWithClass(_RMXPathTokenClass(), @"+");
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanOccurrenceIndicator);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanVarname = [[^ scanner_t (void) {
		// -> OPERATOR
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return scanOperatorState;
		} copy] autorelease]];
		{
			scanVarname();
		}
		[XPathScanner endCandidateSection];
		
		// pushState()
		// -> EXPR_COMMENT
		[XPathScanner startCandidateSection:[[^ void * (void) {
			pushState(scanVarname);
			return scanExpressionComment;
		} copy] autorelease]];
		{
			scanCommentStart();
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanExpressionComment = [[^ scanner_t (void) {
		[XPathScanner startCandidateSection:[[^ void * (void) {
			return popState;
		} copy] autorelease]];
		{
			[XPathScanner measureCandidateScan:^ BOOL (_RMXPathScanner *scanner, NSMutableArray *candidateTokens) {
				NSArray *tokens = [scanner scanExpressionComment];
				if ([tokens count] == 0) {
					return NO;
				}
				
				[candidateTokens addObjectsFromArray:tokens];
				return YES;
			}];
		}
		[XPathScanner endCandidateSection];
		
		return [XPathScanner commitCandidate];
	} copy] autorelease];
	
	scanner_t currentScanner = scanExpression;
	while (1) {
		if ([XPathScanner isAtEnd]) {
			break;
		}
		
		currentScanner = currentScanner();
		
		if (currentScanner == nil) {
			currentScanner = syntaxError();
		}
		if (currentScanner == scanError) {
			return nil;
		}
		
		continue;
	}
	
	return [XPathScanner cumulativeTokens];
}

NSString *RMFoundationXPathSerialise(NSArray *tokens) {
	return [[tokens valueForKey:_RMXPathTokenSerialisedRepresentationKey] componentsJoinedByString:@""];
}

#pragma mark - XPath Preprocessor

NSString *RMFoundationXPathPreprocessQNameNamespaces(NSString *XPathWithNamespaces, NSDictionary *namespacesMap) {
	if (XPathWithNamespaces == nil || namespacesMap == nil) {
		return XPathWithNamespaces;
	}
	
	NSArray *XPathTokens = nil;
	
	@autoreleasepool {
		NSArray *result = RMFoundationXPathTokenise(XPathWithNamespaces, NULL);
		if (result == nil) {
			return XPathWithNamespaces;
		}
		
		XPathTokens = [result retain];
	}
	
	XPathTokens = [XPathTokens autorelease];
	
	NSMutableArray *outputTokens = [[XPathTokens mutableCopy] autorelease];
	__block BOOL didReplaceOutputToken = NO;
	
	[XPathTokens enumerateObjectsUsingBlock:^ (id XPathTokensObj, NSUInteger XPathTokensIdx, BOOL *stopEnumeratingXPathTokens) {
		_RMXPathToken *currentToken = XPathTokensObj;
		if (![currentToken isKindOfClass:[_RMXPathTokenClass(QName) class]]) {
			return;
		}
		
		NSString *currentQName = [currentToken string];
		
		NSArray *currentQNameComponents = [currentQName componentsSeparatedByString:@":"];
		if ([currentQNameComponents count] != 2) {
			return;
		}
		NSString *prefix = [currentQNameComponents objectAtIndex:0], *localName = [currentQNameComponents objectAtIndex:1];
		
		NSString *prefixURI = [namespacesMap objectForKey:prefix];
		if (prefixURI == nil) {
			return;
		}
		
		NSString *QNameEquivalence = [NSString stringWithFormat:@"*[local-name() = '%@' and string(namespace-uri()) = '%@']", localName, prefixURI];
		
		_RMXPathToken *replacementToken = [[[_RMXPathTokenClass(QName) alloc] initWithString:QNameEquivalence] autorelease];
		[outputTokens replaceObjectAtIndex:XPathTokensIdx withObject:replacementToken];
		didReplaceOutputToken = YES;
	}];
	
	if (!didReplaceOutputToken) {
		return XPathWithNamespaces;
	}
	
	return RMFoundationXPathSerialise(outputTokens);
}
