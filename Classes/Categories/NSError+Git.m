//
//  NSError+Git.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "NSError+Git.h"


NSString * const GTGitErrorDomain = @"GTGitErrorDomain";

@implementation NSError (Git)

+ (NSError *)gitErrorForInitRepository: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
	 [NSDictionary dictionaryWithObject:@"Failed to init this repository"
								 forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForOpenRepository: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to open this repository"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForInitRepoIndex: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to get index for this repository"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForInitRevWalker: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to initialize rev walker"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForPushRevWalker: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to push sha onto rev walker"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForHideRevWalker: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to hide sha on rev walker"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForLookupObject: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to lookup object in repository"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForMkStr: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to create object id from sha"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForAddTreeEntry: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to add a new tree entry"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForNewObject: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to create new object"
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)gitErrorForWriteObject: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to write object"
										forKey:NSLocalizedDescriptionKey]];	
	
}

+ (NSError *)gitErrorForRawRead: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to read raw object"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForHashObject: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to get hash for object"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForWriteObjectToDb: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to write object to database"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForTreeEntryToObject: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to get object for tree entry"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForInitIndex: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to initialize index"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForReadIndex: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to read index"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForIndexStageValue {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:-1
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Invalid index stage (must range from 0 to 3)"
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)gitErrorForAddEntryToIndex: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to add entry to index"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForWriteIndex: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to write index"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForLookupRef: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to lookup reference"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForCreateRef: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to create symbolic reference"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForSetRefTarget: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to set reference target"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForPackAllRefs: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to pack all references in repo"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForDeleteRef: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to delete reference"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForResloveRef: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to resolve reference"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForRenameRef: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to rename reference"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForListAllRefs: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to list all references"
										forKey:NSLocalizedDescriptionKey]];	
}

+ (NSError *)gitErrorForNoBlockProvided {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:-1
						   userInfo:
			[NSDictionary dictionaryWithObject:@"No block was provided to the method"
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)gitErrorFor:(int)code withDescription:(NSString *)desc {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:-1
						   userInfo:
			[NSDictionary dictionaryWithObject:desc
										forKey:NSLocalizedDescriptionKey]];
}

@end
