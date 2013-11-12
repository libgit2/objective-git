//
//  clone.c
//  ocgit
//
//  Created by Etienne on 12/11/13.
//  Copyright (c) 2013 tiennou. All rights reserved.
//

#import "GTCLITool.h"
#import <ObjectiveGit/GTCredential.h>

@interface GTCloneTool : GTCLITool <GTCLITool>

@end

@implementation GTCloneTool

+ (NSString *)toolName { return @"clone"; }

- (BOOL)performCommandWithArguments:(NSMutableArray *)arguments options:(NSArray *)options error:(NSError **)error {
    GTCredentialProvider *provider = [[self class] credentialProviderWithArguments:arguments error:error];
    NSArray *commandOptions = [[self class] parseOptions:arguments error:error];
    if (commandOptions.count != 0) {
        // TODO: Error: Unhandled options.
        return NO;
    }

    // Parse arguments:
    // 1 - repo to clone
    // 2 - working directory (optional)
    NSURL *repoURL = nil;
    NSURL *workingDirURL = nil;
    switch (arguments.count) {
        case 2:
            repoURL = [NSURL URLWithString:arguments[0]];
            NSString *workingDirPath = [[arguments[1] stringByExpandingTildeInPath] stringByStandardizingPath];
            workingDirURL = [NSURL fileURLWithPath:workingDirPath isDirectory:YES];
            break;
//        case 1:
//            repoURL = arguments[0];
//            NSString *repoString = [repoURL absoluteString];
//
//            NSString *workingDirPath = [[arguments[1] stringByExpandingTildeInPath] stringByStandardizingPath];
//            workingDirURL = [NSURL fileURLWithPath:workingDirPath isDirectory:YES];
//            break;
            break;
    }

    if (repoURL == nil || workingDirURL == nil) {
        // TODO: Invalid arguments
        return NO;
    }

    // Create the working directory if it doesn't exist
    if (![NSFileManager.defaultManager fileExistsAtPath:workingDirURL.path]) {
        [NSFileManager.defaultManager createDirectoryAtURL:workingDirURL
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
    }

    NSDictionary *cloneOptions = @{ GTRepositoryCloneOptionsCredentialProvider: provider, };

    GTRepository *repo = [GTRepository cloneFromURL:repoURL
                                 toWorkingDirectory:workingDirURL
                                            options:cloneOptions
                                              error:error
                              transferProgressBlock:^(const git_transfer_progress *stats) {
                          NSLog(@"Transferring objects: %d total, %d indexed, %d received in %ld bytes", stats->total_objects, stats->indexed_objects, stats->received_objects, stats->received_bytes);
                          }
                              checkoutProgressBlock:^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) {
                          NSLog(@"Checking out %@, %ld/%ld", path, completedSteps, totalSteps);
                          }];

    return (repo != nil);
}

@end