//
//  NSData+Git.h
//

#import "git2.h"

@interface NSData (Git)

+ (NSData *)git_dataWithOid:(git_oid *)oid;
- (BOOL)git_getOid:(git_oid *)oid error:(NSError **)error;

/// Creates an NSData object that will take ownership of a libgit2 buffer.
///
/// buffer - A buffer of data to wrap in NSData, which will be copied if
///          necessary. After this method has completed, the buffer must not be
///          used directly. Must not be NULL.
///
/// Returns the wrapped data, or nil if an error occurs.
+ (instancetype)git_dataWithBuffer:(git_buf *)buffer;

@end
