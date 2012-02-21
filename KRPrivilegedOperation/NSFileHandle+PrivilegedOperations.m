//
//  NSFileHandle+PrivilegedOperations.m
//  KRPrivilegedOperation
//
//  Created by Kevin Ross on 3/24/11.
//  Copyright (c) 2012 Kevin Ross. All rights reserved.
//

#import "NSFileHandle+PrivilegedOperations.h"
#import "recvfdpriv.h"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSFileHandle (PrivilegedOperationsPrivateMethods)
+ (NSInteger)_privilegedReadWriteCreateFileDescriptorForURL:(NSURL *)url;



@end

@implementation NSFileHandle (PrivilegedOperationsPrivateMethods)


#if 0
NSString *kMMAuthopenSocketPairKey = @"kMMAuthopenSocketPair";
NSString *kMMAuthopenModeKey = @"kMMAuthopenMode";
NSString *kMMAuthopenURLKey = @"kMMAuthopenURL";

/**
 * int32_t[2] socketpair MUST BE CREATED USIG:
   socketpair(AF_UNIX, SOCK_STREAM, 0, pipe)
 */
+ (int32_t)forkAuthopenWithArgs:(NSDictionary *)args
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    int32_t *socketpair = (int32_t *)[[args valueForKey:kMMAuthopenSocketPairKey] pointerValue];
    NSString * mode = [args valueForKey:kMMAuthopenModeKey];
    NSURL * url = [args valueForKey:kMMAuthopenURLKey];
    
    int32_t result = -1;
    // close parent's pipe
    result = close(socketpair[0]); 
    if (result == -1) {
        // we couldn't close the pipe, let's error
        NSString *errorStr = [NSString stringWithUTF8String:strerror(errno)];
        NSLog(@"%@", errorStr);
        NSException *e = [NSException exceptionWithName:@"Close Pipe Error" 
                                                 reason:errorStr
                                               userInfo:nil];
        @throw e;
        return -1;
    }
    // dup2 the pipe as per man authopen
    int32_t pipe = dup2(socketpair[1], STDOUT_FILENO);
    
    const char *authopenPath = "/usr/libexec/authopen";
    const char *file = [[[url filePathURL] path] UTF8String];
    
    if (mode)
    {
        execl(authopenPath, 
              authopenPath,
              "-stdoutpipe", 
//              "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
              "-c",  // create the file if it doesn't exist.  -m requires -c 
              "-m",   // specify the mode bits if a file is created.
              [mode UTF8String],
              file,
              NULL);
    } 
    else
    {
        execl(authopenPath, 
              authopenPath,
              "-stdoutpipe", 
              "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
              "-c",  // create the file if it doesn't exist.  -m requires -c 
              //"-a",   // appends to filename rather than truncating it (truncating is the default
              file,
              NULL);
    }    
  
    [pool release];

    return pipe;
}

#endif


#define FORK_AUTHOPEN

/**
 * Returns the priviledged file descriptor passed back by authopen after recieving authorization from the user.
 */
+ (NSInteger)_privilegedReadWriteCreateFileDescriptorForURL:(NSURL *)url
                                                   withMode:(NSString *)mode
{
    int32_t pipe[2];
    socketpair(AF_UNIX, SOCK_STREAM, 0, pipe);
    
#ifdef FORK_AUTHOPEN
    if (fork() == 0) {	 // child
        int32_t result = -1;
        // close parent's pipe
        result = close(pipe[0]); 
        // dup2 the pipe as per man authopen
        pipe[0] = dup2(pipe[1], STDOUT_FILENO);
        
        const char *authopenPath = "/usr/libexec/authopen";
        const char *file = [[[url filePathURL] path] UTF8String];
        
        if (mode)
        {
            execl(authopenPath, 
                  authopenPath,
                  "-stdoutpipe", 
                  "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
                  "-c",  // create the file if it doesn't exist.  -m requires -c 
                  "-m",   // specify the mode bits if a file is created.
                  [mode UTF8String],
                  file,
                  NULL);
        } 
        else
        {
            execl(authopenPath, 
                  authopenPath,
                  "-stdoutpipe", 
                  "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
                  "-c",  // create the file if it doesn't exist.  -m requires -c 
                  //"-a",   // appends to filename rather than truncating it (truncating is the default
                  file,
                  NULL);
        }
        
        
        
    }

    int32_t fd = pipe[0];

#else
#error "This doesn't work! We need to fork()!"
        int32_t result = -1;
        // close parent's pipe
        result = close(pipe[0]); 
        // dup2 the pipe as per man authopen
        pipe[0] = dup2(pipe[1], STDOUT_FILENO);
        
        const char *authopenPath = "/usr/libexec/authopen";
        const char *file = [[[url filePathURL] path] UTF8String];
        
    dispatch_queue_t queue = dispatch_queue_create("com.app.task", NULL);
    dispatch_sync(queue, ^{
        if (mode)
        {
            execl(authopenPath, 
                  authopenPath,
                  "-stdoutpipe", 
                  "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
                  "-c",  // create the file if it doesn't exist.  -m requires -c 
                  "-m",   // specify the mode bits if a file is created.
                  [mode UTF8String],
                  file,
                  NULL);
        } 
        else
        {
            execl(authopenPath, 
                  authopenPath,
                  "-stdoutpipe", 
                  "-w",   // instructs authopen to open filename read/write and truncate it.  If -stdoutpipe has not been specified, authopen will then copy stdin to filename until stdin is closed.
                  "-c",  // create the file if it doesn't exist.  -m requires -c 
                  //"-a",   // appends to filename rather than truncating it (truncating is the default
                  file,
                  NULL);
        }
    });
    
        
    int32_t fd = pipe[0];

#endif

    uid_t uid;
    
    NSInteger newFD = recv_ufd(fd, &uid, NULL);
    
    if (newFD < 0)
    {
        NSException *e = [NSException exceptionWithName:@"Failed Authentication"
                                                 reason:@"Failed to authenticate privledged operation."
                                               userInfo:nil];
        @throw e;
        return -1;
    }
	return newFD;
}

+ (NSInteger)_privilegedReadWriteCreateFileDescriptorForURL:(NSURL *)url
{
    
	return [self _privilegedReadWriteCreateFileDescriptorForURL:url
                                                       withMode:nil];
}


@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSFileHandle (PrivilegedOperations)



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged Counterparts to NSFileHandle.h
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)privilegedFileHandleForReadingAtPath:(NSString *)path
{
    return nil;
}

+ (id)privilegedFileHandleForWritingAtPath:(NSString *)path
{
    return nil;
}

+ (id)privilegedFileHandleForUpdatingAtPath:(NSString *)path
{
    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged File Handles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (id)privilegedFileHandleForURL:(NSURL *)url
                  createWithMode:(NSString *)mode
{
    NSInteger fileDescriptor = [self _privilegedReadWriteCreateFileDescriptorForURL:url
                                                                           withMode:mode];
    if (fileDescriptor < 0)
        return nil;
    
    id handle = [[self alloc] initWithFileDescriptor:(int32_t)fileDescriptor 
                                      closeOnDealloc:YES];
    return [handle autorelease];
}


+ (id)privilegedReadWriteCreateFileHandleForURL:(NSURL *)url
{
    return [self privilegedFileHandleForURL:url
                             createWithMode:nil];
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Privileged File Operations
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)writeData:(NSData *)data 
            toURL:(NSURL *)url
{
    return [self writeData:data
                     toURL:url
            createWithMode:nil];
}

+ (BOOL)writeData:(NSData *)data 
            toURL:(NSURL *)url
   createWithMode:(NSString *)mode
{
    BOOL didWriteData = NO;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Does a file exist at the given URL?
    BOOL isDirectory = NO;
    BOOL fileExists = [fm fileExistsAtPath:[[url filePathURL] path]
                               isDirectory:&isDirectory];
    if (isDirectory)
        return didWriteData;
    
    NSFileHandle *writeHandle;
    if (!fileExists && mode)
        writeHandle = [self privilegedFileHandleForURL: url
                                        createWithMode:mode];
    else
        writeHandle = [self privilegedReadWriteCreateFileHandleForURL: url];
    
    
    [writeHandle writeData:data];
    [writeHandle truncateFileAtOffset:[writeHandle offsetInFile]];
    [writeHandle closeFile];
    
    
    return didWriteData;
}



@end
