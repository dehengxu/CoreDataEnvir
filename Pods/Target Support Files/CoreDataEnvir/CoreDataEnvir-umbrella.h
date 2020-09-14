#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CoreDataEnvir.h"
#import "CoreDataEnvirHeader.h"
#import "CoreDataEnvir_Background.h"
#import "CoreDataEnvir_Main.h"
#import "NSManagedObject_Background.h"
#import "NSManagedObject_Convenient.h"
#import "NSManagedObject_MainThread.h"
#import "CoreDataEnvir_Private.h"

FOUNDATION_EXPORT double CoreDataEnvirVersionNumber;
FOUNDATION_EXPORT const unsigned char CoreDataEnvirVersionString[];

