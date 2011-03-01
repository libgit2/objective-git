# Objective Git - libgit2 wrapper for Objective-C
Objective Git provides Objective-C bindings for the libgit2 linkable C Git library. 

A good reference for setting up frameworks in xcode:
http://atastypixel.com/blog/creating-applications-in-xcode-using-frameworks/

Trying this out for testing:
https://github.com/gabriel/gh-unit

## TODO: 
- Need to get (void)testCanGetCompleteContentWithNulls working (in GTBlobTest.m).
I'm having issues with getting nulls and other binary content in a string. Probably
a better way to do this in obj-c
- Implement memory mgt and garbage collection finalizers better
