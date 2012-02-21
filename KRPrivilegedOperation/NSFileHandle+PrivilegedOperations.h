//
//  NSFileHandle+PrivilegedOperations.h
//  KRPrivilegedOperation
//
//  Created by Kevin Ross on 3/24/11.
//  Copyright (c) 2012 Kevin Ross. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileHandle (PrivilegedOperations)
{}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged Counterparts to NSFileHandle.h
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)privilegedFileHandleForReadingAtPath:(NSString *)path;
+ (id)privilegedFileHandleForWritingAtPath:(NSString *)path;

/**
 * 
 @Parameters: 
 path
 The path to the file, device, or named socket to access.
 
 @Return Value
 The initialized file handle object or nil if no file exists at path.
 
 @Discussion
 The file pointer is set to the beginning of the file. The returned object responds to both read... messages and writeData:.
 
 When using this method to create a file handle object, the file handle owns its associated file descriptor and is responsible for closing it.
 */
+ (id)privilegedFileHandleForUpdatingAtPath:(NSString *)path;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged File Handles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)privilegedReadWriteCreateFileHandleForURL:(NSURL *)url;
+ (id)privilegedFileHandleForURL:(NSURL *)url
                              createWithMode:(NSString *)mode;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged File Operations
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (BOOL)writeData:(NSData *)data 
            toURL:(NSURL *)url;

+ (BOOL)writeData:(NSData *)data 
            toURL:(NSURL *)url
   createWithMode:(NSString *)mode;



@end
