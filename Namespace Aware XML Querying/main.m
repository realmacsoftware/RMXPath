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

int main(int argc, char *const *argv)
{
	/*
		Note
		
		these documents are semantically identical but use different namespace prefixes
		
		the same XPath should be usable to query all three
		
		the first XPath only returns results for Catalog+ns+prefix.xml where the prefix in the XPath matches the prefix in the document
		the second XPath returns results for all documents because it matches the local-name() and the namespace-uri() making it document prefix agnostic
	 */
	
	NSArray *documentNames = @[ @"Catalog+ns.xml", @"Catalog+ns+prefix.xml", @"Catalog+ns+prefix2.xml" ];
	
	NSArray *XPaths = @[ @"/book:catalog/book:book[book:id = 'urn:isbn:978-0762723133']", @"/*[local-name() = 'catalog' and string(namespace-uri()) = 'http://realmacsoftware.com/namespaces/dts/book.xml']/*[local-name() = 'book' and string(namespace-uri()) = 'http://realmacsoftware.com/namespaces/dts/book.xml'][*[local-name() = 'id' and string(namespace-uri()) = 'http://realmacsoftware.com/namespaces/dts/book.xml'] = 'urn:isbn:978-0762723133']", ];
	
	for (NSString *documentName in documentNames) {
		NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[documentName stringByDeletingPathExtension] withExtension:[documentName pathExtension]] options:0 error:NULL];
		
		for (NSString *XPath in XPaths) {
			NSArray *nodes = [document nodesForXPath:XPath error:NULL];
			NSLog(@"%@ %@", documentName, nodes);
		}
	}
	
	return 0;
}
