//
//  CNBSegwitAddress.mm
//  CNBitcoinKit
//
//  Created by BJ Miller on 7/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

#import "CNBSegwitAddress.h"
#import "CNBWitnessMetadata.h"
#import "NSData+CNBitcoinKit.h"

#ifdef __cplusplus
#include <bitcoin/bitcoin/coinninja/address/segwit_address.hpp>
#endif

#define kP2WPKHProgramSize 20
#define kP2WSHProgramSize 32

@implementation CNBSegwitAddress

+ (CNBWitnessMetadata *)decodeSegwitAddressWithHRP:(NSString *)hrpString address:(NSString *)addressString {
  std::string hrp = [hrpString cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::string addr = [addressString cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::pair<int, std::vector<uint8_t>> dec(coinninja::address::segwit_address::decode(hrp, addr));
  NSData *data = [NSData dataWithBytes:dec.second.data() length:dec.second.size()];
  CNBWitnessMetadata *metadata = [[CNBWitnessMetadata alloc] initWithWitVer:dec.first witProg:data];
  return metadata;
}

+ (NSString *)encodeSegwitAddressWithHRP:(NSString *)hrpString witnessMetadata:(CNBWitnessMetadata *)metadata {
  std::string hrp = [hrpString cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::vector<uint8_t> witprog = [[metadata witprog] dataChunk];
  std::string encoded = coinninja::address::segwit_address::encode(hrp, (int)metadata.witver, witprog);
  return [NSString stringWithCString:encoded.c_str() encoding:[NSString defaultCStringEncoding]];
}

+ (BOOL)isValidP2WPKHAddress:(NSString *)address {
  if ([address isEqualToString:@""]) {
    return false;
  }

  NSString *hrp = [self hrpFromAddress: address];
  CNBWitnessMetadata *metadata = [self decodeSegwitAddressWithHRP:hrp address:address];
  return (metadata.witver != -1) && (metadata.witprog.length == kP2WPKHProgramSize);
}

+ (BOOL)isValidP2WSHAddress:(NSString *)address {
  if ([address isEqualToString:@""]) {
    return false;
  }

  NSString *hrp = [self hrpFromAddress: address];
  CNBWitnessMetadata *metadata = [self decodeSegwitAddressWithHRP:hrp address:address];
  return (metadata.witver != -1) && (metadata.witprog.length == kP2WSHProgramSize);
}

+ (NSString *)hrpFromAddress:(NSString *)address {
  NSRange separatorRange = [address rangeOfString:@"1" options:NSBackwardsSearch];
  NSString *truncatedString = [address substringToIndex:separatorRange.location];
  NSRange hrpRange = [truncatedString rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet];
  if (hrpRange.location != NSNotFound) {
    NSString *hrp = [address substringToIndex:hrpRange.location];
    return hrp;
  } else {
    return truncatedString;
  }
}

@end
