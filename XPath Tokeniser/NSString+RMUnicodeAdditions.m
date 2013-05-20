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

#import "NSString+RMUnicodeAdditions.h"

@implementation NSString (RMUnicodeAdditions)

- (BOOL)getCodepoints:(uint32_t **)codepointsRef length:(size_t *)lengthRef {
	struct _NSStringRMUnicodeAdditions_CompileTimeAssertions {
		char assert0[(sizeof(uint32_t) >= sizeof(UniChar) ? 1 : -1)];
	};
	
	if ([self length] == 0) {
		return NO;
	}
	
	NSParameterAssert(codepointsRef != NULL);
	NSParameterAssert(lengthRef != NULL);
	
	CFStringInlineBuffer stringBuffer = {};
	CFStringInitInlineBuffer((CFStringRef)self, &stringBuffer, CFRangeMake(0, [self length]));
	
	CFIndex stringLength = CFStringGetLength((CFStringRef)self);
	
	// Note: worst case allocation
	uint32_t *codepoints = (uint32_t *)calloc(sizeof(uint32_t), stringLength);
	size_t codepointsLength = 0;
	
	BOOL converted = YES;
	for (CFIndex currentCharacterIndex = 0; currentCharacterIndex < stringLength; currentCharacterIndex++) {
		uint32_t currentCodepoint = 0;
		
		UniChar c1 = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentCharacterIndex);
		if (CFStringIsSurrogateHighCharacter(c1)) {
			currentCharacterIndex++;
			if (currentCharacterIndex > stringLength) {
				converted = NO;
				break;
			}
			
			UniChar c2 = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentCharacterIndex);
			if (!CFStringIsSurrogateLowCharacter(c2)) {
				converted = NO;
				break;
			}
			
			currentCodepoint = (((c1 - /* 0b1101100000000000 */ 0xD800) << 10) + ((c2 - /* 0b1101110000000000 */ 0xDC00) + /* 0b10000000000000000 */ 0x10000));
		}
		else if (CFStringIsSurrogateLowCharacter(c1)) {
			converted = NO;
			break;
		}
		else {
			currentCodepoint = c1;
		}
		
		codepoints[codepointsLength] = currentCodepoint;
		codepointsLength++;
	}
	if (!converted) {
		free(codepoints);
		return NO;
	}
	
	*codepointsRef = codepoints;
	*lengthRef = codepointsLength;
	
	return YES;
}

- (id)initWithCodepoints:(uint32_t *)codepoints length:(size_t)length {
	[self release];
	self = nil;
	
	/*
		Note
		
		the `length` parameter is the size of the `codepoints` array
		the `capacity` parameter is the number of UTF-16 encoded Unicode characters the mutable string is expected to hold
		
		these aren't directly equivocal but it's a good estimate for the capacity hint
	 */
	NSMutableString *newString = [[NSMutableString alloc] initWithCapacity:length];
	
	UniChar buffer[2];
	
	for (size_t idx = 0; idx < length; idx++) {
		uint32_t currentCodepoint = codepoints[idx];
		
		size_t characters = 0;
		if (currentCodepoint < 0x10000) {
			UniChar c1 = currentCodepoint;
			
			buffer[0] = c1;
			
			characters = 1;
		}
		else if (currentCodepoint >= 0x10000 && currentCodepoint <= 0x10FFFF) {
			UniChar c1 = 0xD800 + (((currentCodepoint - 0x10000) & /* 0b11111111110000000000 */ 0xFFC00) >> 10);
			UniChar c2 = 0xDC00 + ((currentCodepoint - 0x10000) & /* 0b00000000001111111111 */ 0x3FF);
			
			buffer[0] = c1;
			buffer[1] = c2;
			
			characters = 2;
		}
		else {
			[newString release];
			return nil;
		}
		
		CFStringAppendCharacters((CFMutableStringRef)newString, buffer, characters);
	}
	
	return newString;
}

@end
