//
//  NSFileManager+PrivilegedOperations.h
//  KRPrivilegedOperation
//
//  Created by Kevin Ross on 3/25/11.
//  Copyright (c) 2012 Kevin Ross. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (PivilegedOperations)
{}
- (BOOL)createPrivilegedDirectoryAtURL:(NSURL *)url
                              withMode:(NSString *)mode;

@end
