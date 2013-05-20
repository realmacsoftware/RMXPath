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
	Convert a character stream into a token stream for token-wise manipulations
 */
extern NSArray *RMFoundationXPathTokenise(NSString *XPath, NSError **errorRef);

/*!
	\brief
	Serialise a token stream into a character stream for passing into an XPath evaluator
 */
extern NSString *RMFoundationXPathSerialise(NSArray *tokens);

/*!
	\brief
	This function converts an XPath with namespaces into an XPath suitable for use with the NSXML family of classes
	
	\details
	Given the following semantically equivalent documents, though differing in syntax:
	
	```xml
	<?xml version="1.0" encoding="utf-8"?>
	<root xmlns="http://realmacsoftware.com/dts/namespaces/example.xml">
		<child>
			<grandchild/>
		</child>
		<child/>
		<child/>
	</root>
	```
 
	```xml
	<?xml version="1.0" encoding="utf-8"?>
	<name:root xmlns:name="http://realmacsoftware.com/dts/namespaces/example.xml">
		<name:child>
			<name:grandchild/>
		</name:child>
		<name:child/>
		<name:child/>
	</name:root>
	```
	
	```rubycocoa
	doc1 = NSXMLDocument.alloc.initWithXMLString_options_error "<?xml version=\"1.0\" encoding=\"utf-8\"?><root xmlns=\"http://realmacsoftware.com/dts/namespaces/example.xml\"><child><grandchild/></child><child/><child/></root>", 0
	doc2 = NSXMLDocument.alloc.initWithXMLString_options_error "<?xml version=\"1.0\" encoding=\"utf-8\"?><name:root xmlns:name=\"http://realmacsoftware.com/dts/namespaces/example.xml\"><name:child><name:grandchild/></name:child><name:child/><name:child/></name:root>", 0
	```
	
	`[xmlDocument nodesForXPath:@"/root/child/grandchild" error:NULL]` will return a populated array for the first document, and an empty array for the second document
	`[xmlDocument nodesForXPath:RMXMLPreprocessXPath(@"/a:root/a:child/a:grandchild", @{ @"a" : @"http://realmacsoftware.com/dts/namespaces/example.xml" }) error:NULL]` will return a populated array for both documents
	
	\param namespacesMap
	Map of prefix string to URI string
	
	\return
	An XPath where QName references of the form `a:node` given a namespacesMap of the form `@{ @"a" : @"http://realmacsoftware.com/dts/namespaces/example.xml" }` are transformed into `*[local-name() = 'node' and string(namespace-uri()) = 'http://realmacsoftware.com/dts/namespaces/example.xml']` which is equivalent to the orignal QName
 */
extern NSString *RMFoundationXPathPreprocessQNameNamespaces(NSString *XPathWithNamespaces, NSDictionary *namespacesMap);
