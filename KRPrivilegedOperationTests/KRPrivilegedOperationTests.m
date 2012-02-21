//
//  KRPrivilegedOperationTests.m
//  KRPrivilegedOperationTests
//
//  Created by Kevin Ross on 3/23/11.
//  Copyright (c) 2012 Kevin Ross. All rights reserved.
//

#import "KRPrivilegedOperationTests.h"
#import "NSFileHandle+PrivilegedOperations.h"
#import "NSFileManager+PrivilegedOperations.h"


@implementation KRPrivilegedOperationTests

- (NSString *)privilegedTestPath
{
	return @"/var/tmp/com.kevinross.KRPrivilegedOperationTests";
}


- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL testDirExists = [fileManager fileExistsAtPath:[self privilegedTestPath]
                                           isDirectory:&isDirectory];
    if (!testDirExists) 
    {
        NSError *error = nil;
        BOOL didCreatePath = [fileManager createDirectoryAtPath:[self privilegedTestPath]
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&error];
        if (!didCreatePath && error) 
        {
            NSLog(@"%@", error);
        }
    }
    
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFileCreationWithMode0000
{
    NSString *filename = @"test.txt";
    NSURL *url = [[NSURL fileURLWithPath:[self privilegedTestPath]] URLByAppendingPathComponent:filename];
    NSFileHandle *fh = [NSFileHandle privilegedFileHandleForURL:url createWithMode:@"0000"];
    STAssertNotNil(fh, @"fileHandle is nil!", nil);
    //    STFail(@"Unit tests are not implemented yet in MMPrivilegedOperationTests");
}


- (void)doNOTtestCreatePrivilegedDirectory
{
	BOOL didCreate = NO;
    
    NSString *privilegedPath = @"/var/lolcats";
    
    NSURL *url = [NSURL fileURLWithPath:privilegedPath];
    didCreate = [[NSFileManager defaultManager] createPrivilegedDirectoryAtURL:url
                                                                      withMode:@"0000"];
    
    STAssertTrue(didCreate, @"Did not create the privileged directory", nil);
}



@end
