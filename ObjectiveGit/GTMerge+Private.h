//
//  GTMerge+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 27/10/2018.
//  Copyright © 2018 GitHub, Inc. All rights reserved.
//

#import "GTMerge.h"

@interface GTMergeFile (Private)

+ (BOOL)handleMergeFileOptions:(git_merge_file_options *)opts optionsDict:(NSDictionary *)dict error:(NSError **)error;

@end
