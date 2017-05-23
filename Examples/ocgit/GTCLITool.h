//
//  GTCLITool.h
//  ocgit
//
//  Created by Etienne on 12/11/13.
//  Copyright (c) 2013 tiennou. All rights reserved.
//

#import <ObjectiveGit/GTCredential.h>

@protocol GTCLITool <NSObject>
- (BOOL)performCommandWithArguments:(NSArray *)arguments options:(NSArray *)options error:(NSError **)error;
@end

@interface GTCLITool : NSObject <GTCLITool>

+ (BOOL)executeToolWithArguments:(NSMutableArray *)arguments error:(NSError **)error;

+ (NSArray *)parseOptions:(NSMutableArray *)arguments error:(NSError **)error;

+ (GTCredentialProvider *)credentialProviderWithArguments:(NSMutableArray *)arguments error:(NSError **)error;

@end
