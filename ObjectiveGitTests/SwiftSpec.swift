//
//  SwiftSpec.swift
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-10-02.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

import Nimble
import Quick
import XCTest

// Without this, the Swift stdlib won't be linked into the test target (even if
// “Embedded Content Contains Swift Code” is enabled).
// https://github.com/Quick/Quick/issues/164
class SwiftSpec: QuickSpec {
	override func spec() {
		expect(true).to(beTruthy())
	}
}
