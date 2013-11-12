//
//  GTCLITool.m
//  ocgit
//
//  Created by Etienne on 12/11/13.
//  Copyright (c) 2013 tiennou. All rights reserved.
//

#import <objc/runtime.h>
#import "GTCLITool.h"

static NSMutableDictionary *cliTools = nil;

@implementation GTCLITool

+ (NSString *)toolName {
    return nil;
}

+ (NSDictionary *)parseCredentialOptions:(NSMutableArray *)arguments error:(NSError **)error {
    NSMutableDictionary *credOptions = [NSMutableDictionary dictionary];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    [arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL *stop) {
        BOOL matched = NO;
        if ([argument isEqualToString:@"-U"] || [argument isEqualToString:@"--username"]) {
            credOptions[@"userName"] = arguments[idx + 1];
            matched = YES;
        } else if ([argument isEqualToString:@"-K"] || [argument isEqualToString:@"--keyfile"]) {
            credOptions[@"keyFileName"] = arguments[idx + 1];
        }

        if (matched) {
            [indexesToRemove addIndex:idx];
            [indexesToRemove addIndex:idx + 1];
        }
    }];
    return credOptions;
}

+ (NSString *)readStringFromFileHandle:(NSFileHandle *)handle securely:(BOOL)secure {
    NSData *newData = nil;
    // FIXME: How can I echo off ?
    NSMutableString *string = [NSMutableString string];
    while ((newData = [handle readDataOfLength:1]) != nil && newData.length != 0) {
        NSRange dataRange = [newData rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, newData.length)];
        if (dataRange.location != NSNotFound)
            break;

        [string appendString:[[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding]];
    }
    return string;
}

static NSString *descForCredType(GTCredentialType type) {
    NSMutableArray *typeStrings = [NSMutableArray arrayWithCapacity:2];
    if (type & GTCredentialTypeSSHKeyFilePassPhrase) {
        [typeStrings addObject:@"ssh-keypass"];
    }
    if (type & GTCredentialTypeSSHPublicKey) {
        [typeStrings addObject:@"ssh-key"];
    }
    if (type & GTCredentialTypeUserPassPlaintext) {
        [typeStrings addObject:@"user-pass"];
    }
    return [typeStrings componentsJoinedByString:@", "];
}

+ (GTCredentialProvider *)credentialProviderWithArguments:(NSMutableArray *)arguments error:(NSError **)error {
    __block NSDictionary *credOptions = [self parseCredentialOptions:arguments error:error];

    GTCredentialProvider *provider = [GTCredentialProvider providerWithBlock:^GTCredential *(GTCredentialType type, NSString *URL, NSString *userName) {
        NSLog(@"Authentication requested for %@, user: %@, auth types allowed: %@", URL, userName, descForCredType(type));

        NSString *keyFileName = credOptions[@"keyFileName"];
        NSString *authUserName = credOptions[@"userName"];
        GTCredential *cred = nil;
        if (type & GTCredentialTypeSSHKeyFilePassPhrase && keyFileName != nil) {
            NSString *privateKeyPath = nil;
            NSString *publicKeyPath = nil;

            // First try to find the key file by checking if it's an absolute path
            NSString *keyFilePath = [[keyFileName stringByExpandingTildeInPath] stringByStandardizingPath];
            if ([NSFileManager.defaultManager fileExistsAtPath:keyFilePath]) {
                privateKeyPath = keyFilePath;
            } else {
                // Try a key file name in the user's .ssh dir
                keyFilePath = [[[NSString stringWithFormat:@"~/.ssh/%@", keyFileName] stringByExpandingTildeInPath] stringByStandardizingPath];
                if ([NSFileManager.defaultManager fileExistsAtPath:keyFilePath])
                    privateKeyPath = keyFilePath;
            }
            if (privateKeyPath == nil) {
                // TODO: Error here
                return nil;
            }

            // Now fetch the private key's passphrase
            NSLog(@"Authenticating using key %@, please enter the key's passphrase — WARNING: it will be echoed:", keyFileName);
            NSString *passphrase = [self readStringFromFileHandle:[NSFileHandle fileHandleWithStandardInput] securely:YES];

            publicKeyPath = [privateKeyPath stringByAppendingPathExtension:@".pub"];
            NSURL *publicKeyURL = [NSURL fileURLWithPath:publicKeyPath];
            NSURL *privateKeyURL = [NSURL fileURLWithPath:privateKeyPath];

            cred = [GTCredential credentialWithUserName:userName publicKeyURL:publicKeyURL privateKeyURL:privateKeyURL passphrase:passphrase error:error];
        } else if (type & GTCredentialTypeUserPassPlaintext) {
            if (authUserName == nil) authUserName = userName;

            NSLog(@"Authenticating as %@, please enter your password — WARNING: it will be echoed:", authUserName);
            NSString *password = [self readStringFromFileHandle:[NSFileHandle fileHandleWithStandardInput] securely:YES];
            cred = [GTCredential credentialWithUserName:authUserName password:password error:error];
        }
        //        } else if (type & GTCredentialTypeSSHPublicKey) {
        //            NSString *publicKeyPath = [[@"~/.ssh/id_dsa.pub" stringByExpandingTildeInPath] stringByStandardizingPath];
        //
        //            NSData *publicKey = [NSData dataWithContentsOfFile:publicKeyPath];
        //
        //            cred = [GTCredential credentialWithUserName:userName publicKey:publicKey error:&error signBlock:nil];
        //        }
        
        return cred;
    }];
    return provider;
}

+ (NSArray *)parseOptions:(NSMutableArray *)arguments error:(NSError **)error {
    NSMutableIndexSet *optionSet = [NSMutableIndexSet indexSet];
    [arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL *stop) {
        if ([argument hasPrefix:@"-"] || [argument hasPrefix:@"--"]) {
            [optionSet addIndex:idx];
        } else {
            // First non-argument encountered, stop
            *stop = YES;
        }
    }];

    NSArray *options = [arguments objectsAtIndexes:optionSet];
    [arguments removeObjectsAtIndexes:optionSet];
    return options;
}

+ (instancetype)findToolForCommand:(NSString *)command error:(NSError **)error {
    static NSMutableDictionary *toolClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        toolClasses = [NSMutableDictionary dictionary];
        unsigned int classCount = 0;
        Class *classList = objc_copyClassList(&classCount);
        for (int i = 0; i < classCount; i++) {
            Class objClass = classList[i];

            if (class_conformsToProtocol(objClass, @protocol(GTCLITool))) {
                if ([objClass.toolName isEqualToString:command]) {
                    toolClasses[objClass.toolName] = [[objClass alloc] init];
                }
            }
        }
    });
    return toolClasses[command];
}

+ (BOOL)executeToolWithArguments:(NSMutableArray *)arguments error:(NSError **)error {
    NSArray *options = [self parseOptions:arguments error:error];
    if (options == nil) return NO;

    if (arguments.count == 0) {
        // TODO: Error
        return NO;
    }

    NSString *command = [arguments objectAtIndex:0];
    [arguments removeObjectAtIndex:0];

    GTCLITool *tool = [self findToolForCommand:command error:error];
    if (tool == nil) {
        // TODO: Error
        return NO;
    }

    return [tool performCommandWithArguments:arguments options:options error:error];
}

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        cliTools = [NSMutableDictionary dictionary];
//    });
//}
//
//+ (void)initialize {
//    if ([self class] != [GTCLITool class]) {
//        cliTools[[[self class] toolName]] = self;
//    }
//}

- (BOOL)performCommandWithArguments:(NSMutableArray *)arguments options:(NSArray *)options error:(NSError **)error {
    return NO;
}

@end
