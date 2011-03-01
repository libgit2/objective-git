//
//  NSError+Git.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "NSError+Git.h"

static NSString * const GTGitErrorDomain = @"GTGitErrorDomain";

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

+ (NSError *)gitErrorForLookupSha: (int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:@"Failed to lookup sha"
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

@end
