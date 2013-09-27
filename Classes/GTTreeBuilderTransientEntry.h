//
//  GTTreeBuilderTransientEntry.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTTreeBuilder.h"

// A tree build entry which hasn't been written yet. It exists entirely in
// memory.
@interface GTTreeBuilderTransientEntry : NSObject

// The data which will be written.
@property (nonatomic, readonly, strong) NSData *data;

// The file name for the entry.
@property (nonatomic, readonly, copy) NSString *fileName;

// The file mode which will be used.
@property (nonatomic, readonly, assign) GTFileMode fileMode;

// Initializes a new transient entry.
//
// fileName - The name of the file to write. Cannot be nil.
// data     - The data to write. Cannot be nil.
// fileMode - The mode of the file.
//
// Returns the initialized object.
- (id)initWithFileName:(NSString *)fileName data:(NSData *)data fileMode:(GTFileMode)fileMode;

@end
