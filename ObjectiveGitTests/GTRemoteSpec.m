//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-09-06
//
//  The MIT License
//
//  Copyright (c) 2013 Etienne Samson
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

#import "GTRemote.h"

SpecBegin(GTRemote)

__block GTRepository *masterRepo;
__block GTRepository *fetchingRepo;

beforeEach(^{
	masterRepo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(masterRepo).notTo.beNil();
	
	/* Build back an URL to the temporary fixture folder
	 * I'd wanted to do :
	 
	 NSURL *masterRepoURL = [NSURL fileURLWithPath:[self pathForFixtureRepositoryNamed:@"testrepo.git"]];
	 NSURL *fixturesURL = [NSURL fileURLWithPath:self.repositoryFixturesPath];
	 
	 * But this errors.
	 */
	
	NSURL *masterRepoURL = [masterRepo fileURL];
	NSURL *fixturesURL = [masterRepoURL URLByDeletingLastPathComponent];
	NSURL *fetchingURLRepo = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

	NSError *error = nil;
	fetchingRepo = [GTRepository cloneFromURL:masterRepoURL toWorkingDirectory:fetchingURLRepo barely:NO withCheckout:YES error:&error transferProgressBlock:nil checkoutProgressBlock:nil];
	expect(fetchingRepo).notTo.beNil();
	expect(error.localizedDescription).to.beNil();
});

SpecEnd
