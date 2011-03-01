//
//  GTLib.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/18/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//


@interface GTLib : NSObject {

}

+ (NSData *)hexToRaw:(NSString *)hex;
+ (NSString *)rawToHex:(NSData *)raw;

@end
