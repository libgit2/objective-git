//
//  git2-Mac.h
//  git2-Mac
//
//  Created by Ben Chatelain on 8/12/15.
//  Copyright © 2015 phatblat. All rights reserved.
//

/// Project version number for git2-Mac.
extern double git2_MacVersionNumber;

/// Project version string for git2-Mac.
extern const unsigned char git2_MacVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <git2_Mac/PublicHeader.h>

// Headers from libit2/git2.h
#import <git2/annotated_commit.h>
#import <git2/attr.h>
#import <git2/blob.h>
#import <git2/blame.h>
#import <git2/branch.h>
#import <git2/buffer.h>
#import <git2/checkout.h>
#import <git2/cherrypick.h>
#import <git2/clone.h>
#import <git2/commit.h>
#import <git2/common.h>
#import <git2/config.h>
#import <git2/describe.h>
#import <git2/diff.h>
#import <git2/errors.h>
#import <git2/filter.h>
#import <git2/global.h>
#import <git2/graph.h>
#import <git2/ignore.h>
#import <git2/index.h>
#import <git2/indexer.h>
#import <git2/merge.h>
#import <git2/message.h>
#import <git2/net.h>
#import <git2/notes.h>
#import <git2/object.h>
#import <git2/odb.h>
#import <git2/odb_backend.h>
#import <git2/oid.h>
#import <git2/pack.h>
#import <git2/patch.h>
#import <git2/pathspec.h>
#import <git2/rebase.h>
#import <git2/refdb.h>
#import <git2/reflog.h>
#import <git2/refs.h>
#import <git2/refspec.h>
#import <git2/remote.h>
#import <git2/repository.h>
#import <git2/reset.h>
#import <git2/revert.h>
#import <git2/revparse.h>
#import <git2/revwalk.h>
#import <git2/signature.h>
#import <git2/stash.h>
#import <git2/status.h>
#import <git2/submodule.h>
#import <git2/tag.h>
#import <git2/transport.h>
#import <git2/transaction.h>
#import <git2/tree.h>
#import <git2/types.h>
#import <git2/version.h>

// Other headers
#import <git2/cred_helpers.h>
#import <git2/oidarray.h>
#import <git2/strarray.h>
#import <git2/trace.h>

#import <git2/sys/commit.h>
#import <git2/sys/config.h>
#import <git2/sys/diff.h>
#import <git2/sys/filter.h>
#import <git2/sys/hashsig.h>
#import <git2/sys/index.h>
#import <git2/sys/mempack.h>
#import <git2/sys/odb_backend.h>
#import <git2/sys/openssl.h>
#import <git2/sys/refdb_backend.h>
#import <git2/sys/reflog.h>
#import <git2/sys/refs.h>
#import <git2/sys/repository.h>
#import <git2/sys/stream.h>
#import <git2/sys/transport.h>

// Microsoft platforms
//#import <git2/inttypes.h>
//#import <git2/stdint.h>
