//
//  main.m
//  ocgit
//
//  Created by Etienne on 16/09/13.
//  Copyright (c) 2013 tiennou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTCLITool.h"

int main(int argc, const char * argv[])
{
    BOOL success = NO;
    @autoreleasepool {
        NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argc];
        for (int argi = 1; argi < argc; argi++) {
            [arguments addObject:@(argv[argi])];
        }
        NSError *error = nil;
        success = [GTCLITool executeToolWithArguments:arguments error:&error];
    }
    return success != NO;
}

