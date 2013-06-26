//
//  GTSignature.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import "GTObject.h"

// A git signature.
@interface GTSignature : NSObject

// The name of the person.
@property (nonatomic, readonly, copy) NSString *name;

// The email of the person.
@property (nonatomic, readonly, copy) NSString *email;

// The time when the action happened.
@property (nonatomic, readonly, strong) NSDate *time;

// The time zone that `time` should be interpreted relative to.
@property (nonatomic, readonly, copy) NSTimeZone *timeZone;

// Initializes the receiver with the given signature.
//
// git_signature - The signature to wrap. This must not be NULL.
//
// Returns an initialized GTSignature, or nil if an error occurs.
- (id)initWithGitSignature:(const git_signature *)git_signature;

// Initializes the receiver with the given information.
//
// name  - The name of the person. This must not be nil.
// email - The email of the person. This must not be nil.
// time  - The time of the action, interpreted relative to the default time
//         zone. This may be nil.
//
// Returns an initialized GTSignature, or nil if an error occurs.
- (id)initWithName:(NSString *)name email:(NSString *)email time:(NSDate *)time;

// The underlying `git_signature` object.
- (const git_signature *)git_signature __attribute__((objc_returns_inner_pointer));

@end
