//
//  NSArray+StringArraySpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 22/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(StringArray)

describe(@"String arrays", ^{
	__block NSArray *originalArray = nil;
	__block git_strarray strArray;
	
	beforeEach(^{
		originalArray = @[ @"First", @"Second", @"Third", @"Fourth", @"Fifth", @"Sixth" ];
		strArray = originalArray.git_strarray;
	});
	
	afterEach(^{
		git_strarray_free(&strArray);
	});
	
	it(@"should return null for an empty array", ^{
		NSArray *emptyArray = [NSArray array];
		expect(emptyArray.git_strarray.count).to.equal(0);
		expect(emptyArray.git_strarray.strings).to.beNil();
	});

	void (^validateStrArray)(git_strarray) = ^ (git_strarray arrayToValidate) {
		expect(arrayToValidate.count).to.equal(originalArray.count);
		
		for (NSUInteger idx = 0; idx < originalArray.count; idx++) {
			const char *UTF8String = [originalArray[idx] UTF8String];
			const char *convertedString = arrayToValidate.strings[idx];
			expect(strcmp(UTF8String, convertedString)).to.equal(0);
		}
	};
	
	it(@"should correctly translate the strings", ^{
		validateStrArray(strArray);
	});
	
	it(@"should be able to be copied", ^{
		git_strarray copiedArray;
		git_strarray_copy(&copiedArray, &strArray);
		validateStrArray(copiedArray);
	});
});

SpecEnd
