//
//  NSArray+StringArraySpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 22/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(StringArray)

describe(@"String arrays", ^{

	void (^validateStrArray)(NSArray *, git_strarray) = ^(NSArray *array, git_strarray strArray) {
		expect(strArray.count).to.equal(array.count);

		for (NSUInteger idx = 0; idx < array.count; idx++) {
			const char *convertedString = strArray.strings[idx];
			NSString *comparisonString = @(convertedString);
			expect(array[idx]).to.equal(comparisonString);
		}
	};

	describe(@"allow conversion to a git_strarray", ^{
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

		it(@"should correctly translate the strings", ^{
			validateStrArray(originalArray, strArray);
		});

		it(@"should be able to be copied", ^{
			git_strarray copiedArray;
			git_strarray_copy(&copiedArray, &strArray);
			validateStrArray(originalArray, copiedArray);
			git_strarray_free(&copiedArray);
		});

		it(@"should stay valid outside of an autorelease pool", ^{
			git_strarray dontAutoreleaseThis;
			@autoreleasepool {
				dontAutoreleaseThis = originalArray.git_strarray;
			}

			validateStrArray(originalArray, dontAutoreleaseThis);
		});
	});

	describe(@"allows conversion from a git_strarray", ^{
		__block git_strarray originalStrArray;

		beforeEach(^{
			originalStrArray.count = 3;
			originalStrArray.strings = calloc(originalStrArray.count, sizeof(char *));
			originalStrArray.strings[0] = "First";
			originalStrArray.strings[1] = "Second";
			originalStrArray.strings[2] = "Third";
		});

		afterEach(^{
			free(originalStrArray.strings);
		});

		it(@"should return an empty array for an NULL strarray", ^{
			git_strarray strarray = { .strings = NULL, .count = 0 };
			NSArray *array = [NSArray git_arrayWithStrarray:strarray];
			expect(array.count).to.equal(0);
		});

		it(@"should correctly translate the strarray", ^{
			NSArray *array = [NSArray git_arrayWithStrarray:originalStrArray];
			validateStrArray(array, originalStrArray);
		});

		it(@"should omit NULL strings", ^{
			originalStrArray.strings[1] = NULL;

			NSArray *array = [NSArray git_arrayWithStrarray:originalStrArray];
			expect(array).to.equal((@[ @"First", @"Third" ]));
		});
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
