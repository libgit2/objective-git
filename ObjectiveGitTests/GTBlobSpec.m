//
//  GTBlobSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-11-07.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBlob.h"

SpecBegin(GTBlob)

__block GTRepository *repository;
__block NSString *blobSHA;
__block GTBlob *blob;

describe(@"blob properties can be accessed", ^{
	beforeEach(^{
		repository = self.bareFixtureRepository;
		blobSHA = @"fa49b077972391ad58037050f2a75f74e3671e92";
		blob = [repository lookUpObjectBySHA:blobSHA objectType:GTObjectTypeBlob error:NULL];
		expect(blob).notTo.beNil();
	});

	it(@"has a size", ^{
		expect(blob.size).to.equal(9);
	});

	it(@"has content", ^{
		expect(blob.content).to.equal(@"new file\n");
	});

	it(@"has type", ^{
		expect(blob.type).to.equal(@"blob");
	});

	it(@"has a SHA", ^{
		expect(blob.SHA).to.equal(blobSHA);
	});
});

describe(@"blobs can be created", ^{
	beforeEach(^{
		repository = self.testAppFixtureRepository;
	});

	describe(@"+blobWithString:inRepository:error", ^{
		it(@"works with valid parameters", ^{
			NSError *error = nil;
			blob = [GTBlob blobWithString:@"a new blob content" inRepository:repository error:&error];
			expect(error).to.beNil();
			expect(blob).notTo.beNil();
			expect(blob.SHA).notTo.beNil();
		});
	});

	describe(@"+blobWithData:inRepository:error", ^{
		it(@"works with valid parameters", ^{
			char bytes[] = "100644 example_helper.rb\00\xD3\xD5\xED\x9D A4_\x00 40000 examples";
			NSData *content = [NSData dataWithBytes:bytes length:sizeof(bytes)];

			NSError *error = nil;
			blob = [GTBlob blobWithData:content inRepository:repository error:&error];
			expect(error).to.beNil();
			expect(blob).notTo.beNil();
			expect(blob.SHA).notTo.beNil();
		});
	});

	describe(@"+blobWithFile:inRepository:error", ^{
		it(@"works with valid parameters", ^{
			NSString *fileContent = @"Test contents\n";
			NSString *fileName = @"myfile.txt";
			NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:fileName];

			NSError *error = nil;
			BOOL success = [fileContent writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
			expect(success).to.beTruthy();
			expect(error).to.beNil();

			blob = [GTBlob blobWithFile:fileURL inRepository:repository error:&error];
			expect(error).to.beNil();
			expect(blob).notTo.beNil();
			expect(blob.SHA).notTo.beNil();
			expect(blob.content).to.equal(fileContent);
		});
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
