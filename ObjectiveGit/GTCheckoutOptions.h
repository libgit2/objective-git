//
//  GTCheckoutOptions.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/04/2015.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/checkout.h"

@class GTDiffFile;

NS_ASSUME_NONNULL_BEGIN

/// Checkout strategies used by the various -checkout... methods
/// See git_checkout_strategy_t
typedef NS_OPTIONS(NSInteger, GTCheckoutStrategyType) {
	GTCheckoutStrategyNone = GIT_CHECKOUT_NONE,
	GTCheckoutStrategySafe = GIT_CHECKOUT_SAFE,
	GTCheckoutStrategyForce = GIT_CHECKOUT_FORCE,
	GTCheckoutStrategyAllowConflicts = GIT_CHECKOUT_ALLOW_CONFLICTS,
	GTCheckoutStrategyRemoveUntracked = GIT_CHECKOUT_REMOVE_UNTRACKED,
	GTCheckoutStrategyRemoveIgnored = GIT_CHECKOUT_REMOVE_IGNORED,
	GTCheckoutStrategyUpdateOnly = GIT_CHECKOUT_UPDATE_ONLY,
	GTCheckoutStrategyDontUpdateIndex = GIT_CHECKOUT_DONT_UPDATE_INDEX,
	GTCheckoutStrategyNoRefresh = GIT_CHECKOUT_NO_REFRESH,
	GTCheckoutStrategyDisablePathspecMatch = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH,
	GTCheckoutStrategySkipLockedDirectories = GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES,
};

/// Checkout notification flags used by the various -checkout... methods
/// See git_checkout_notify_t
typedef NS_OPTIONS(NSInteger, GTCheckoutNotifyFlags) {
	GTCheckoutNotifyNone = GIT_CHECKOUT_NOTIFY_NONE,
	GTCheckoutNotifyConflict = GIT_CHECKOUT_NOTIFY_CONFLICT,
	GTCheckoutNotifyDirty = GIT_CHECKOUT_NOTIFY_DIRTY,
	GTCheckoutNotifyUpdated = GIT_CHECKOUT_NOTIFY_UPDATED,
	GTCheckoutNotifyUntracked = GIT_CHECKOUT_NOTIFY_UNTRACKED,
	GTCheckoutNotifyIgnored = GIT_CHECKOUT_NOTIFY_IGNORED,

	GTCheckoutNotifyAll = GIT_CHECKOUT_NOTIFY_ALL,
};

@interface GTCheckoutOptions : NSObject
+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags progressBlock:(nullable void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock notifyBlock:(nullable int (^)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags notifyBlock:(int (^)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock;

+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy;

- (git_checkout_options *)git_checkoutOptions NS_RETURNS_INNER_POINTER;

@property (assign) GTCheckoutStrategyType strategy;
@property (copy) void (^progressBlock)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps);

@property (assign) GTCheckoutNotifyFlags notifyFlags;
@property (copy) int (^notifyBlock)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir);

@property (copy) NSArray *pathSpecs;

@end

NS_ASSUME_NONNULL_END