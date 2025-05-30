#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void StartBLEScan(void);
const char* StartBLEScanAndReturnJSON(void);
void ConnectToBLEDevice(const char* uuid);

#ifdef __cplusplus
}
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothScanner : NSObject
- (instancetype)init;
- (void)startScan;
- (void)connectToDeviceWith:(NSString*)uuid;
@end

NS_ASSUME_NONNULL_END
#endif

