//
//  EUExZipMgr.m
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExZip.h"
#import "EUtility.h"
 #import "EUExBaseDefine.h"

@implementation EUExZip

-(id)initWithBrwView:(EBrowserView *) eInBrwView{	
	if (self = [super initWithBrwView:eInBrwView]) {
	}
	return self;
}

-(void)dealloc{
	[super dealloc];
}


-(void)zipThread:(NSMutableArray *)inArguments {
	NSString *inSrcPath = [inArguments objectAtIndex:0];
	NSString *inZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    if (isZipWithPassword) {
        inPassword = [inArguments objectAtIndex:2];
    }
	BOOL ret = NO;
	NSString *trueSrcPath = [super absPath:inSrcPath];
	NSString *trueZippedPath = [super absPath:inZippedPath];
	if (trueSrcPath!=nil && trueZippedPath!=nil) {
 		NSFileManager *fmanager = [NSFileManager defaultManager];
		if ([fmanager fileExistsAtPath:trueZippedPath]) {
			[fmanager removeItemAtPath:trueZippedPath error:nil];
		} 
		//判断上级文件夹是否存在，不存在就创建
		NSString *docpath = [trueZippedPath substringToIndex:[trueZippedPath length]-([[trueZippedPath lastPathComponent] length])];
		if (![fmanager fileExistsAtPath:docpath]) {
			[fmanager createDirectoryAtPath:docpath withIntermediateDirectories:YES attributes:nil error:nil];
		}
        //12.29 zip
		UexZipArchive *zipObj = [[UexZipArchive alloc] init];
        if (isZipWithPassword) {
            State = isZipWithPassword;
            [zipObj CreateZipFile2:trueZippedPath Password:inPassword];
        }else{
            [zipObj CreateZipFile2:trueZippedPath];
        }
		NSArray *array= [trueSrcPath componentsSeparatedByString:@"/"];
		NSString *newName = [array lastObject];
        
        if ([newName length]!=0) {
            ret = [zipObj addFileToZip:trueSrcPath newname:newName];
        }else {
            NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:trueSrcPath];
            NSString *file = nil;
            while (file = [de nextObject]) {
                //判断文件 还是文件夹---07.17
                NSString *filePath;
                if (![trueSrcPath hasSuffix:@"/"]) {
                    filePath =[trueSrcPath stringByAppendingFormat:@"/%@",file];
                }else {
                    filePath =[trueSrcPath stringByAppendingString:file];
                }
                BOOL isDir;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] &&isDir) {
                }else {
                    [zipObj addFileToZip:filePath newname:file];
                }
            }  
        }
        if (ret) {
            //
        }
		[zipObj CloseZipFile2];
		[zipObj release];
        isZipWithPassword = NO;
		if ([fmanager fileExistsAtPath:trueZippedPath]) {
            NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbZip",@"uexZip.cbZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CSUCCESS];
            [self mainThreadCallBack:jsString];

		}else {
            NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbZip",@"uexZip.cbZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
            [self mainThreadCallBack:jsString];
		}
	}else{
        NSString *inErrorDes =[UEX_ERROR_DESCRIBE_ARGS stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *jsFailedStr = [NSString stringWithFormat:@"if(uexWidgetOne.cbError!=null){uexWidgetOne.cbError(%d,%d,\'%@\');}",0,1260101,inErrorDes];
        [self mainThreadCallBack:jsFailedStr];
	}
}

-(void)zipWithPassword:(NSMutableArray *)inArguments {
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isZipWithPassword = YES;
        [self zip:inArguments];
    }
}

-(void)zip:(NSMutableArray *)inArguments {
    
    [NSThread detachNewThreadSelector:@selector(zipThread:) toTarget:self withObject:inArguments];
}


-(void)unzipThread:(NSMutableArray *)inArguments {
    NSString *inSrcPath = [inArguments objectAtIndex:0];
    NSString *inunZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    
    if (isUnZipWithPassword) {
        if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>2) {
            inPassword = [inArguments objectAtIndex:2];
        }
    }
    
    BOOL ret = NO;
    NSString *trueSrcPath = [super absPath:inSrcPath];
    NSString *trueUnzippedPath = [super absPath:inunZippedPath];
    if (trueSrcPath!=nil && trueUnzippedPath!=nil) {
        NSFileManager *fmanager = [NSFileManager defaultManager];
        if (![fmanager fileExistsAtPath:trueUnzippedPath]) {
            [fmanager createDirectoryAtPath:trueUnzippedPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if ([fmanager fileExistsAtPath:trueSrcPath]) {
            UexZipArchive *zipObj = [[UexZipArchive alloc] init];
            if (isUnZipWithPassword) {
                ret = [zipObj UnzipOpenFile:trueSrcPath Password:inPassword];
            }else{
                //当state为yes 证明是带有密码的压缩包 需要使用 UnzipOpenFile Password 接口
                if (State) {
                    [zipObj UnzipCloseFile];
                    [zipObj release];
                    isUnZipWithPassword = NO;
                    NSError *error;
                    [fmanager removeItemAtPath:trueUnzippedPath error:&error];
                    
                    NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
                    [self mainThreadCallBack:jsString];

                    return;
                }else{
                    [zipObj UnzipOpenFile:trueSrcPath];
                }
            }
            ret = [zipObj UnzipFileTo:trueUnzippedPath overWrite:YES];
            [zipObj UnzipCloseFile];
            [zipObj release];
        }
        isUnZipWithPassword = NO;
        if (ret) {
            NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CSUCCESS];
            [self mainThreadCallBack:jsString];

        }else {
            NSError *error;
            [fmanager removeItemAtPath:trueUnzippedPath error:&error];
            
            NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
            [self mainThreadCallBack:jsString];

        } 		
    }else{
        NSString *inErrorDes =[UEX_ERROR_DESCRIBE_ARGS stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *jsFailedStr = [NSString stringWithFormat:@"if(uexWidgetOne.cbError!=null){uexWidgetOne.cbError(%d,%d,\'%@\');}",0,1260201,inErrorDes];
        [self mainThreadCallBack:jsFailedStr];

    }

}


-(void)unzip:(NSMutableArray *)inArguments {
    
    [NSThread detachNewThreadSelector:@selector(unzipThread:) toTarget:self withObject:inArguments];
}

-(void)unzipWithPassword:(NSMutableArray *)inArguments {
    
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isUnZipWithPassword = YES;
        [self unzip:inArguments];
    }
}

-(void)mainThreadCallBack:(NSString *)jsString{
    if ([NSThread isMainThread]) {
        [self.meBrwView stringByEvaluatingJavaScriptFromString:jsString];
    }else{
        [self performSelectorOnMainThread:@selector(callBackMethod:) withObject:jsString waitUntilDone:NO];
    }
}

-(void)callBackMethod:(NSString *)jsString{
    [self.meBrwView stringByEvaluatingJavaScriptFromString:jsString];
}

@end
