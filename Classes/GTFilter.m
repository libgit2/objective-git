//
//  GTFilter.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilter.h"
#import "GTRepository.h"
#import "NSError+Git.h"
#import "GTFilterSource+Private.h"
#import "git2/sys/filter.h"

NSString * const GTFilterErrorDomain = @"GTFilterErrorDomain";

const NSInteger GTFilterErrorNameAlreadyRegistered = -1;

typedef BOOL (^GTFilterCheckBlock)(void **payload, GTFilterSource *source, const char **attr_values);
typedef BOOL (^GTFilterApplyBlock)(void **payload, NSData *from, NSData **to, GTFilterSource *source);
typedef void (^GTFilterCleanupBlock)(void *payload);

static NSMutableDictionary *GTFiltersNameToRegisteredFilters = nil;
static NSMutableDictionary *GTFiltersGitFilterToRegisteredFilters = nil;

@interface GTFilter () {
	git_filter *_filter;
}

@property (nonatomic, readonly, copy) NSString *name;

@property (nonatomic, readonly, copy) void (^initializeBlock)(void);

@property (nonatomic, readonly, copy) void (^shutdownBlock)(void);

@property (nonatomic, readonly, copy) GTFilterCheckBlock checkBlock;

@property (nonatomic, readonly, copy) GTFilterApplyBlock applyBlock;

@property (nonatomic, readonly, copy) GTFilterCleanupBlock cleanupBlock;

@end

@implementation GTFilter

#pragma mark Lifecycle

+ (void)initialize {
	if (self == GTFilter.class) {
		GTFiltersNameToRegisteredFilters = [[NSMutableDictionary alloc] init];
		GTFiltersGitFilterToRegisteredFilters = [[NSMutableDictionary alloc] init];
	}
}

- (void)dealloc {
	if (_filter != NULL) free(_filter);
}

static int GTFilterInit(git_filter *filter) {
	GTFilter *self = GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:filter]];
	self.initializeBlock();
	return 0;
}

static void GTFilterShutdown(git_filter *filter) {
	GTFilter *self = GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:filter]];
	self.shutdownBlock();
}

static int GTFilterCheck(git_filter *filter, void **payload, const git_filter_source *src, const char **attr_values) {
	GTFilter *self = GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:filter]];
	BOOL accept = self.checkBlock(payload, [[GTFilterSource alloc] initWithGitFilterSource:src], attr_values);
	return accept ? 0 : GIT_PASSTHROUGH;
}

static int GTFilterApply(git_filter *filter, void **payload, git_buf *to, const git_buf *from, const git_filter_source *src) {
	GTFilter *self = GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:filter]];
	NSData *fromData = [NSData dataWithBytesNoCopy:from->ptr length:from->size freeWhenDone:NO];
	NSData *toData;
	BOOL applied = self.applyBlock(payload, fromData, &toData, [[GTFilterSource alloc] initWithGitFilterSource:src]);
	if (applied) git_buf_set(to, toData.bytes, toData.length);

	return applied ? 0 : GIT_PASSTHROUGH;
}

static void GTFilterCleanup(git_filter *filter, void *payload) {
	GTFilter *self = GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:filter]];
	self.cleanupBlock(payload);
}

- (id)initWithName:(NSString *)name attributes:(NSString *)attributes initializeBlock:(void (^)(void))initializeBlock shutdownBlock:(void (^)(void))shutdownBlock checkBlock:(GTFilterCheckBlock)checkBlock applyBlock:(GTFilterApplyBlock)applyBlock cleanupBlock:(GTFilterCleanupBlock)cleanupBlock {
	NSParameterAssert(name != nil);

	self = [super init];
	if (self == nil) return nil;

	_filter = calloc(1, sizeof(git_filter));
	_filter->version = GIT_FILTER_VERSION;
	_filter->attributes = attributes.UTF8String;
	if (initializeBlock != NULL) _filter->initialize = &GTFilterInit;
	if (shutdownBlock != NULL) _filter->shutdown = &GTFilterShutdown;
	if (checkBlock != NULL) _filter->check = &GTFilterCheck;
	if (applyBlock != NULL) _filter->apply = &GTFilterApply;
	if (cleanupBlock != NULL) _filter->cleanup = &GTFilterCleanup;

	_name = [name copy];
	_initializeBlock = [initializeBlock copy];
	_shutdownBlock = [shutdownBlock copy];
	_checkBlock = [checkBlock copy];
	_applyBlock = [applyBlock copy];
	_cleanupBlock = [cleanupBlock copy];

	return self;
}

#pragma mark NSObject

- (BOOL)isEqual:(GTFilter *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:self.class]) return NO;

	return [object.name isEqual:object.name];
}

- (NSUInteger)hash {
	return self.name.hash;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> name: %@", self.class, self, self.name];
}

#pragma mark Registration

- (BOOL)registerWithPriority:(int)priority error:(NSError **)error {
	if (GTFiltersNameToRegisteredFilters[self.name] != nil) {
		if (error != NULL) {
			NSString *description = [NSString stringWithFormat:NSLocalizedString(@"A filter named \"%@\" has already been registered.", @""), self.name];
			NSString *recoverySuggestion = NSLocalizedString(@"Unregister the existing filter first.", @"");
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: description,
				NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
			};
			*error = [NSError errorWithDomain:GTFilterErrorDomain code:GTFilterErrorNameAlreadyRegistered userInfo:userInfo];
		}

		return NO;
	}

	int result = git_filter_register(self.name.UTF8String, _filter, GIT_FILTER_DRIVER_PRIORITY + priority);
	if (result != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:result description:@"Failed to register filter: %@", self.name];
		}

		return NO;
	}

	GTFiltersNameToRegisteredFilters[self.name] = self;
	GTFiltersGitFilterToRegisteredFilters[[NSValue valueWithPointer:_filter]] = self;

	return YES;
}

- (BOOL)unregister:(NSError **)error {
	int result = git_filter_unregister(self.name.UTF8String);
	if (result != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:result description:@"Failed to unregister filter: %@", self.name];
		}

		return NO;
	}

	[GTFiltersNameToRegisteredFilters removeObjectForKey:self.name];
	[GTFiltersGitFilterToRegisteredFilters removeObjectForKey:[NSValue valueWithPointer:_filter]];

	return YES;
}

#pragma mark Lookup

+ (GTFilter *)lookUpFilterWithName:(NSString *)name {
	NSParameterAssert(name != nil);

	return GTFiltersNameToRegisteredFilters[name];
}

@end
