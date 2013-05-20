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

/*!
	\brief
	Unicode manipulation
 */
@interface NSString (RMUnicodeAdditions)

/*!
	\brief
	This DOES NOT return UTF-32 encoded Unicode, it returns Unicode codepoints.
	
	\details
	The codepoints buffer is allocated for you, the parameters are out only.
 */
- (BOOL)getCodepoints:(out uint32_t **)codepointsRef length:(out size_t *)lengthRef;

/*!
	\brief
	Given an array of Unicode codepoints, construct a string object to encode them
	
	Using NSString the codepoints can be encoded into anything NSString supports.
 */
- (id)initWithCodepoints:(uint32_t *)codepoints length:(size_t)length;

@end
