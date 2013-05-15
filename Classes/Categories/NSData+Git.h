//
//  NSData+Git.h
//

#import "git2.h"

@interface NSData (Git)

+ (NSData *)git_dataWithOid:(git_oid *)oid;
- (BOOL)git_getOid:(git_oid *)oid error:(NSError **)error;

@end
