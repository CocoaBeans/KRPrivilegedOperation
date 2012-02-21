//
//  NSFileManager+PrivilegedOperations.m
//  KRPrivilegedOperation
//
//  Created by Kevin Ross on 3/25/11.
//  Copyright (c) 2012 Kevin Ross. All rights reserved.
//

#import "NSFileManager+PrivilegedOperations.h"
#import "NSFileHandle+PrivilegedOperations.h"
#import <fcntl.h>



@implementation NSFileManager (PivilegedOperations)

- (BOOL)createDirectoryAtPath:(NSString *)path 
  withIntermediateDirectories:(BOOL)createIntermediates 
                   attributes:(NSDictionary *)attributes 
                         mode:(NSString *)mode 
                        error:(NSError **)error
{  
    BOOL didCreate = NO;

    
    return didCreate;
}

- (BOOL)createPrivilegedDirectoryAtURL:(NSURL *)url
                              withMode:(NSString *)mode
{
    BOOL didCreate = NO;
    
    NSFileHandle *fh = [NSFileHandle privilegedFileHandleForURL:url
                                                 createWithMode:mode];
    int32_t priv_fd = [fh fileDescriptor];
    
    int32_t flags = fcntl(priv_fd, F_GETFL);
//    int32_t result = fcntl(priv_fd, F_SETFL, flags | S_IFDIR);
    int32_t modifiedFlags = (flags | S_IFDIR);
    int32_t result = fcntl(priv_fd, F_SETFL, modifiedFlags);
    
    int32_t newFlags = fcntl(priv_fd, F_GETFL);
    NSAssert(flags != newFlags, @"Flags did not get set!");
    
    
    NSLog(@"result: %d", result);
    
    if (fh)
        didCreate = YES;
    
    return didCreate;
}



@end
