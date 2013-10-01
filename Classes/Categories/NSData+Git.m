//
//  NSData+Git.m
//

#import "NSData+Git.h"
#import "GTError.h"

@implementation NSData (Git)

+ (NSData *)git_dataWithOid:(git_oid *)oid {
    return [NSData dataWithBytes:oid length:sizeof(git_oid)];
}

- (BOOL)git_getOid:(git_oid *)oid error:(NSError **)error {
    if ([self length] != sizeof(git_oid)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:GTGitErrorDomain 
                                         code:GITERR_INVALID 
                                     userInfo:
                      [NSDictionary dictionaryWithObject:@"can't extract oid from data of incorrect length" 
                                                  forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    [self getBytes:oid length:sizeof(git_oid)];
    return YES;
}

@end
