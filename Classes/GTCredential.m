//
//  GTCredential.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/09/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/NSError+Git.h>
#import "GTCredential.h"
#import "GTCredential+Private.h"
#import <libssh2.h>

typedef GTCredential *(^GTCredentialProviderBlock)(GTCredentialType allowedTypes, NSString *URL, NSString *userName);

@interface GTCredentialProvider ()
@property (copy) GTCredentialProviderBlock credBlock;
@end

@implementation GTCredentialProvider
+ (instancetype)providerWithBlock:(GTCredential *(^)(GTCredentialType type, NSString *URL, NSString *userName))credentialBlock {
	NSParameterAssert(credentialBlock != nil);
	GTCredentialProvider *provider = [[self alloc] init];

	provider.credBlock = credentialBlock;

	return provider;
}

- (GTCredential *)credentialForType:(GTCredentialType)type URL:(NSString *)URL userName:(NSString *)userName {
	NSAssert(self.credBlock != nil, @"Provider asked for credentials without block being set.");

	return self.credBlock(type, URL, userName);
}

@end

@interface GTCredential ()
@property (nonatomic, assign, readonly) git_cred *git_cred;
@end

@implementation GTCredential

+ (instancetype)credentialWithUserName:(NSString *)userName password:(NSString *)password error:(NSError **)error {
	git_cred *cred;
	int gitError = git_cred_userpass_plaintext_new(&cred, userName.UTF8String, password.UTF8String);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to create credentials object" failureReason:@"There was an error creating a credential object for username %@.", userName];
		return nil;
	}

    return [[self alloc] initWithGitCred:cred];
}

+ (instancetype)credentialWithUserName:(NSString *)userName publicKeyURL:(NSURL *)publicKeyURL privateKeyURL:(NSURL *)privateKeyURL passphrase:(NSString *)passphrase error:(NSError **)error {
	NSParameterAssert(privateKeyURL != nil);
	NSString *publicKeyPath = publicKeyURL.filePathURL.path;
	NSString *privateKeyPath = privateKeyURL.filePathURL.path;
	NSAssert(privateKeyPath != nil, @"Invalid file URL passed: %@", privateKeyURL);

	git_cred *cred;
	int gitError = git_cred_ssh_keyfile_passphrase_new(&cred, userName.UTF8String, publicKeyPath.fileSystemRepresentation, privateKeyPath.fileSystemRepresentation, passphrase.UTF8String);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to create credentials object" failureReason:@"There was an error creating a credential object for username %@ with the provided public/private key pair.", userName];
		return nil;
	}

    return [[self alloc] initWithGitCred:cred];
}

typedef NSData *(^GTCredentialSignBlock)(void *session, NSData *data);

struct GTCredentialSignPayload {
	__unsafe_unretained GTCredentialSignBlock signBlock;
};

int GTCredentialSignCallback(LIBSSH2_SESSION *session, unsigned char **sig, size_t *sig_len, const unsigned char *data, size_t data_len, void **abstract) {
	struct GTCredentialSignPayload *payload = *abstract;
	NSData *dataObject = [NSData dataWithBytesNoCopy:(void *)data length:data_len];

	NSData *signData = payload->signBlock(session, dataObject);

	memcpy(sig, signData.bytes, signData.length);
	*sig_len = signData.length;

	return signData != nil ? 0 : -1;
}

+ (instancetype)credentialWithUserName:(NSString *)userName publicKey:(NSData *)publicKey error:(NSError **)error signBlock:(GTCredentialSignBlock)signBlock {
	struct GTCredentialSignPayload payload = { .signBlock = signBlock };

	git_cred *cred;
	int gitError = git_cred_ssh_publickey_new(&cred, userName.UTF8String, publicKey.bytes, publicKey.length, GTCredentialSignCallback, &payload);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to create credentials object" failureReason:@"There was an error creating a credential object for username %@ with the provided public key and sign block.", userName];
		return nil;
	}

	return [[self alloc] initWithGitCred:cred];
}

- (instancetype)initWithGitCred:(git_cred *)cred {
	NSParameterAssert(cred != nil);
	self = [self init];

	if (!self) return nil;

	_git_cred = cred;

	return self;
}

@end

int GTCredentialAcquireCallback(git_cred **git_cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
	NSCParameterAssert(git_cred != NULL);
	NSCParameterAssert(payload != NULL);

    GTCredentialAcquireCallbackInfo *info = payload;
	GTCredentialProvider *provider = info->credProvider;

    if (provider == nil) {
        NSString *errorMsg = [NSString stringWithFormat:@"No GTCredentialProvider set, but authentication was requested."];
        giterr_set_str(GIT_EUSER, errorMsg.UTF8String);
        return GIT_ERROR;
    }

    NSString *URL = (url != NULL ? @(url) : nil);
    NSString *userName = (username_from_url != NULL ? @(username_from_url) : nil);

	GTCredential *cred = [provider credentialForType:(GTCredentialType)allowed_types URL:URL userName:userName];
	if (!cred) {
        NSString *errorMsg = [NSString stringWithFormat:@"GTCredentialProvider failed to provide credentials."];
        giterr_set_str(GIT_EUSER, errorMsg.UTF8String);
        return GIT_ERROR;
	}

	*git_cred = cred.git_cred;
	return GIT_OK;
}
