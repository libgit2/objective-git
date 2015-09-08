//
//  GTCredential.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/09/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/transport.h"

/// An enum describing the data needed for authentication.
/// See `git_credtype_t`.
typedef NS_ENUM(NSInteger, GTCredentialType) {
    GTCredentialTypeUserPassPlaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,
    GTCredentialTypeSSHKey = GIT_CREDTYPE_SSH_KEY,
    GTCredentialTypeSSHCustom = GIT_CREDTYPE_SSH_CUSTOM,
};

NS_ASSUME_NONNULL_BEGIN

@class GTCredential;

/// The GTCredentialProvider acts as a proxy for GTCredential requests.
///
/// The default implementation is used through `+providerWithBlock:`,
/// passing your own block that will build a GTCredential object.
/// But you're allowed to subclass it and handle more complex workflows.
@interface GTCredentialProvider : NSObject

/// Creates a provider from a block.
///
/// credentialBlock - a block that will be called when credentials are requested.
///                   Must not be nil.
+ (instancetype)providerWithBlock:(GTCredential *(^)(GTCredentialType type, NSString *URL, NSString *userName))credentialBlock;

/// Default credential provider method.
///
/// This method will get called when an operation requests credentials from the
/// provider.
///
/// The default implementation calls through the `providedBlock` passed
/// in `providerWithBlock:` above, but your subclass is expected to override it
/// to do its specific work.
///
/// type     - the credential types allowed by the operation.
/// URL      - the URL the operation is authenticating against.
/// userName - the user name provided by the operation. Can be nil, and might be ignored.
- (GTCredential *)credentialForType:(GTCredentialType)type URL:(NSString *)URL userName:(nullable NSString *)userName;
@end

/// The GTCredential class is used to provide authentication data.
/// It acts as a wrapper around `git_cred` objects.
@interface GTCredential : NSObject

/// Create a credential object from a username/password pair.
///
/// userName - The username to authenticate as.
/// password - The password belonging to that user.
/// error    - If not NULL, set to any errors that occur.
///
/// Return a new GTCredential instance, or nil if an error occurred
+ (nullable instancetype)credentialWithUserName:(NSString *)userName password:(NSString *)password error:(NSError **)error;

/// Create a credential object from a SSH keyfile
///
/// userName      - The username to authenticate as. Must not be nil.
/// publicKeyURL  - The URL to the public key for that user.
///                  Can be omitted to reconstruct the public key from the private key.
/// privateKeyURL - The URL to the private key for that user. Must not be nil.
/// passphrase    - The passPhrase for the private key. Optional if the private key has no password.
/// error         - If not NULL, set to any errors that occur.
///
/// Return a new GTCredential instance, or nil if an error occurred
+ (nullable instancetype)credentialWithUserName:(NSString *)userName publicKeyURL:(nullable NSURL *)publicKeyURL privateKeyURL:(NSURL *)privateKeyURL passphrase:(nullable NSString *)passphrase error:(NSError **)error;

/// Create a credential object from a SSH keyfile data string
///
/// userName         - The username to authenticate as.
/// publicKeyString  - The string containing the public key for that user.
///                     Can be omitted to reconstruct the public key from the private key.
/// privateKeyString - The URL to the private key for that user.
/// passphrase       - The passPhrase for the private key. Optional if the private key has no password.
/// error            - If not NULL, set to any errors that occur.
///
/// Return a new GTCredential instance, or nil if an error occurred
+ (nullable instancetype)credentialWithUserName:(NSString *)userName publicKeyString:(nullable NSString *)publicKeyString privateKeyString:(NSString *)privateKeyString passphrase:(nullable NSString *)passphrase error:(NSError **)error;

/// The underlying `git_cred` object.
- (git_cred *)git_cred __attribute__((objc_returns_inner_pointer));

@end

NS_ASSUME_NONNULL_END
