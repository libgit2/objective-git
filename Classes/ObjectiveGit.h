//
//  ObjectiveGit.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
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

#import "git2.h"

#import <ObjectiveGit/GTRepository.h>
#import <ObjectiveGit/GTRepository+Stashing.h>
#import <ObjectiveGit/GTRepository+Committing.h>
#import <ObjectiveGit/GTRepository+Status.h>
#import <ObjectiveGit/GTRepository+Reset.h>
#import <ObjectiveGit/GTEnumerator.h>
#import <ObjectiveGit/GTCommit.h>
#import <ObjectiveGit/GTCredential.h>
#import <ObjectiveGit/GTSignature.h>
#import <ObjectiveGit/GTTree.h>
#import <ObjectiveGit/GTTreeEntry.h>
#import <ObjectiveGit/GTTreeBuilder.h>
#import <ObjectiveGit/GTBlob.h>
#import <ObjectiveGit/GTBlame.h>
#import <ObjectiveGit/GTBlameHunk.h>
#import <ObjectiveGit/GTTag.h>
#import <ObjectiveGit/GTIndex.h>
#import <ObjectiveGit/GTIndexEntry.h>
#import <ObjectiveGit/GTReference.h>
#import <ObjectiveGit/GTBranch.h>
#import <ObjectiveGit/GTObject.h>
#import <ObjectiveGit/GTRemote.h>
#import <ObjectiveGit/GTConfiguration.h>
#import <ObjectiveGit/GTReflog.h>
#import <ObjectiveGit/GTReflogEntry.h>
#import <ObjectiveGit/GTOID.h>
#import <ObjectiveGit/GTSubmodule.h>
#import <ObjectiveGit/GTStatusDelta.h>
#import <ObjectiveGit/GTRepository+Blame.h>
#import <ObjectiveGit/GTFilter.h>
#import <ObjectiveGit/GTFilterList.h>
#import <ObjectiveGit/GTFilterSource.h>

#import <ObjectiveGit/GTObjectDatabase.h>
#import <ObjectiveGit/GTOdbObject.h>

#import <ObjectiveGit/NSError+Git.h>
#import <ObjectiveGit/NSData+Git.h>
#import <ObjectiveGit/NSString+Git.h>
#import <ObjectiveGit/NSArray+StringArray.h>

#import <ObjectiveGit/GTDiff.h>
#import <ObjectiveGit/GTDiffDelta.h>
#import <ObjectiveGit/GTDiffFile.h>
#import <ObjectiveGit/GTDiffHunk.h>
#import <ObjectiveGit/GTDiffLine.h>
#import <ObjectiveGit/GTDiffPatch.h>
