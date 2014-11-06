//
//  NSData+Git.h
//

#import <Foundation/Foundation.h>
#import "git2/buffer.h"
#import "git2/oid.h"

@interface NSData (Git)

+ (NSData *)git_dataWithOid:(git_oid *)oid;
- (BOOL)git_getOid:(git_oid *)oid error:(NSError **)error;

/// Creates an NSData object that will take ownership of a libgit2 buffer.
///
/// buffer - A buffer of data to wrap in NSData, which will be copied if
///          necessary. This method will replace the buffer's content with
///          a NULL pointer on success. This argument must not be NULL.
///
/// Returns the wrapped data, or nil if memory allocation fails.
+ (instancetype)git_dataWithBuffer:(git_buf *)buffer;

/// Returns a read-only libgit2 buffer that will proxy the current bytes of the
/// receiver. If the length of the receiver changes after this method, the
/// behavior of the returned buffer is undefined.
- (git_buf)git_buf;

/// Creates a git_buf from the data and then checks if the buffer contains a NUL
/// byte.
- (BOOL)git_containsNUL;

/// Creates a git_buf from the data and then checks if the buffer looks like it
/// contains binary data.
- (BOOL)git_isBinary;

@end
