//
//  GTWalker.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTWalker.h"
#import "GTCommit.h"
#import "NSError+Git.h"


@interface GTWalker()

@property (nonatomic, assign) git_revwalk *walk;

@end


@implementation GTWalker

@synthesize repo;
@synthesize walk;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	if(self = [super init]){
	
		self.repo = theRepo;
		git_revwalk *w;
		int gitError = git_revwalk_new(&w, self.repo.repo);
		if(gitError != GIT_SUCCESS) {
			if (error != NULL)
				*error = [NSError gitErrorForInitRevWalker:gitError];
			return nil;
		}
		self.walk = w;
	}
	return self;
}

- (void)push:(NSString *)sha error:(NSError **)error {
	
	git_commit *commit;
	commit = (git_commit *)[GTObject getNewObjectInRepo:self.repo.repo sha:sha type:GIT_OBJ_COMMIT error:error];
	
	git_revwalk_push(self.walk, commit);
}

- (void)hide:(NSString *)sha error:(NSError **)error {
	
	git_commit *commit;
	commit = (git_commit *)[GTObject getNewObjectInRepo:self.repo.repo sha:sha type:GIT_OBJ_COMMIT error:error];
	
	git_revwalk_hide(self.walk, commit);
}

- (void)reset {
	
	git_revwalk_reset(self.walk);
}

- (void)sorting:(unsigned int)sortMode {
	
	git_revwalk_sorting(self.walk, sortMode);
}

- (GTCommit *)next {

	git_commit *commit;
	int gitError = git_revwalk_next(&commit, self.walk);
	if(gitError == GIT_EREVWALKOVER)
		return nil;
	
	return (GTCommit *)[GTObject objectInRepo:self.repo withObject:(git_object*)commit];
}

- (void)finalize {
	
	git_revwalk_free(self.walk);
	[super finalize];
}

@end
