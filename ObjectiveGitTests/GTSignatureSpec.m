//
//  GTSignatureSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-06-26.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTSignature)

NSString *name = @"test_user";
NSString *email = @"test@example.com";

__block NSDate *time;

beforeEach(^{
	time = [NSDate date];
});

describe(@"instance", ^{
	__block GTSignature *testSignature;

	beforeEach(^{
		testSignature = [[GTSignature alloc] initWithName:name email:email time:time];
		expect(testSignature).notTo.beNil();
	});

	it(@"should expose the git_signature", ^{
		expect(testSignature.git_signature).notTo.beNil();
		expect(testSignature).to.equal([[GTSignature alloc] initWithGitSignature:testSignature.git_signature]);
	});

	it(@"should compare equal to a signature created with the same information", ^{
		expect(testSignature).to.equal([[GTSignature alloc] initWithName:name email:email time:time]);
	});

	it(@"should compare unequal to a different signature", ^{
		expect(testSignature).notTo.equal([[GTSignature alloc] initWithName:name email:email time:[NSDate dateWithTimeIntervalSinceNow:10]]);
	});
});

it(@"should keep the git_signature alive even if the object goes out of scope", ^{
	const git_signature *git_signature = NULL;

	{
		GTSignature *testSignature __attribute__((objc_precise_lifetime)) = [[GTSignature alloc] initWithName:name email:email time:time];
		git_signature = testSignature.git_signature;
	}

	GTSignature *testSignature = [[GTSignature alloc] initWithGitSignature:git_signature];
	expect(testSignature.name).to.equal(name);
	expect(testSignature.email).to.equal(email);
});

afterEach(^{
	[self tearDown];
});

SpecEnd
