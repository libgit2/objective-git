//
//  EXTScope.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTScope.h"

void gt_ext_executeCleanupBlock (__strong gt_ext_cleanupBlock_t *block) {
    (*block)();
}

