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
	GTCheckoutStrategyRecreateMissing = GIT_CHECKOUT_RECREATE_MISSING,
	GTCheckoutStrategyAllowConflicts = GIT_CHECKOUT_ALLOW_CONFLICTS,
	GTCheckoutStrategyRemoveUntracked = GIT_CHECKOUT_REMOVE_UNTRACKED,
	GTCheckoutStrategyRemoveIgnored = GIT_CHECKOUT_REMOVE_IGNORED,
	GTCheckoutStrategyUpdateOnly = GIT_CHECKOUT_UPDATE_ONLY,
	GTCheckoutStrategyDontUpdateIndex = GIT_CHECKOUT_DONT_UPDATE_INDEX,
	GTCheckoutStrategyNoRefresh = GIT_CHECKOUT_NO_REFRESH,
	GTCheckoutStrategySkipUnmerged = GIT_CHECKOUT_SKIP_UNMERGED,
	GTCheckoutStrategyUseOurs = GIT_CHECKOUT_USE_OURS,
	GTCheckoutStrategyUseTheirs = GIT_CHECKOUT_USE_THEIRS,
	GTCheckoutStrategyDisablePathspecMatch = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH,
	GTCheckoutStrategySkipLockedDirectories = GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES,
	GTCheckoutStrategyDoNotOverwriteIgnored = GIT_CHECKOUT_DONT_OVERWRITE_IGNORED,
	GTCheckoutStrategyConflictStyleMerge = GIT_CHECKOUT_CONFLICT_STYLE_MERGE,
	GTCheckoutStrategyCoflictStyleDiff3 = GIT_CHECKOUT_CONFLICT_STYLE_DIFF3,
	GTCheckoutStrategyDoNotRemoveExisting = GIT_CHECKOUT_DONT_REMOVE_EXISTING,
	GTCheckoutStrategyDoNotWriteIndex = GIT_CHECKOUT_DONT_WRITE_INDEX,
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

/// Create a checkout options object.
///
/// Since there are many places where we can checkout data, this object allow us
/// to centralize all the various behaviors that checkout allow.
///
/// @param strategy      The checkout strategy to use.
/// @param notifyFlags   The checkout events that will be notified via `notifyBlock`.
/// @param progressBlock A block that will be called for each checkout step.
/// @param notifyBlock   A block that will be called for each event, @see `notifyFlags`.
///
/// @return A newly-initialized GTCheckoutOptions object.
+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags progressBlock:(void (^ _Nullable)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock notifyBlock:(int (^ _Nullable)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

/// Create a checkout options object.
/// @see +checkoutOptionsWithStrategy:notifyFlags:progressBlock:notifyBlock:
+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags notifyBlock:(int (^)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

/// Create a checkout options object.
/// @see +checkoutOptionsWithStrategy:notifyFlags:progressBlock:notifyBlock:
+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock;

/// Create a checkout options object.
/// @see +checkoutOptionsWithStrategy:notifyFlags:progressBlock:notifyBlock:
+ (instancetype)checkoutOptionsWithStrategy:(GTCheckoutStrategyType)strategy;

/// Get the underlying git_checkout_options struct.
///
/// @return <#return value description#>
- (git_checkout_options *)git_checkoutOptions NS_RETURNS_INNER_POINTER;

/// The checkout strategy to use.
@property (assign) GTCheckoutStrategyType strategy;

/// The checkout progress block that was passed in.
@property (copy) void (^progressBlock)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps);

/// The notification flags currently enabled.
@property (assign) GTCheckoutNotifyFlags notifyFlags;

/// The checkout notification block that was passed in.
@property (copy) int (^notifyBlock)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir);

/// An array of strings used to restrict what will be checked out.
@property (copy) NSArray <NSString *> *pathSpecs;

@end

NS_ASSUME_NONNULL_END
