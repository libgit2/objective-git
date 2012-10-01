//
//  ObjectiveGit.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/1/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "ObjectiveGit.h"


void GTSetupThreads(void) {
	git_threads_init();
}

extern void GTShutdownThreads(void) {
	git_threads_shutdown();
}

__attribute__((constructor))
static void initializer(void) {
	GTSetupThreads();
}

__attribute__((destructor))
static void finalizer(void) {
	GTShutdownThreads();
}
