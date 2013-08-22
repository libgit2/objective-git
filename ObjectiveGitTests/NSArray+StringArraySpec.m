//
//  NSArray+StringArraySpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 22/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(StringArray)

describe(@"String arrays", ^{
	it(@"should return null for an empty array", ^{
		NSArray *emptyArray = [NSArray array];
		expect([emptyArray git_strarray]).to.beNull();
	});
	
	it(@"should correctly translate the strings", ^{
		NSArray *originalArray = @[ @"First", @"Second", @"Third", @"Fourth", @"Fifth", @"Sixth" ];
		git_strarray *strArray = [originalArray git_strarray];
		expect(strArray->count).to.equal(originalArray.count);
		
		for (NSUInteger idx = 0; idx < originalArray.count; idx++) {
			const char *UTF8String = [originalArray[idx] UTF8String];
			const char *convertedString = strArray->strings[idx];
			expect(strcmp(UTF8String, convertedString)).to.equal(0);
		}
		
		git_strarray_free(strArray);
	});
});

SpecEnd
