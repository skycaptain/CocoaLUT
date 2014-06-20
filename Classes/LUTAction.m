//
//  LUTAction.m
//  Lattice
//
//  Created by Greg Cotten on 6/19/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "LUTAction.h"

@interface LUTAction ()

@property (strong) LUT* cachedInLUT;
@property (strong) LUT* cachedOutLUT;

@end

@implementation LUTAction

+(instancetype)actionWithBlock:(LUT *(^)(LUT *lut))actionBlock
                    actionName:(NSString *)actionName
                actionMetadata:(M13OrderedDictionary *)actionMetadata{
    return [[self alloc] initWithBlock:actionBlock actionName:actionName actionMetadata:actionMetadata];
}

+(instancetype)actionWithBypassBlockWithName:(NSString *)actionName{
    return [self actionWithBlock:^LUT *(LUT *lut) {
        return lut;
    }
                              actionName:actionName
                          actionMetadata:M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Bypass"}])];
}

-(instancetype)initWithBlock:(LUT *(^)(LUT *lut))actionBlock
                  actionName:(NSString *)actionName
              actionMetadata:(M13OrderedDictionary *)actionMetadata{
    if(self = [super init]){
        self.actionBlock = actionBlock;
        self.actionName = actionName ? actionName : @"Untitled Action";
        if (actionMetadata == nil){
            @throw [NSException exceptionWithName:@"LUTActionInitError" reason:@"Action metadata must not be nil." userInfo:nil];
        }
        if (actionMetadata[@"id"] == nil){
            @throw [NSException exceptionWithName:@"LUTActionInitError" reason:@"Action metadata doesn't contain an ID." userInfo:nil];
        }
        self.actionMetadata = actionMetadata;
    }
    return self;
}

-(LUT *)LUTByUsingActionBlockOnLUT:(LUT *)lut{
    if(self.cachedInLUT != nil && self.cachedInLUT == lut){
        //NSLog(@"\"%@\" cached", self);
        [self.cachedOutLUT copyMetaPropertiesFromLUT:lut];
        return self.cachedOutLUT;
    }
    else{
        //NSLog(@"\"%@\" not cached", self);
        self.cachedInLUT = lut;
        self.cachedOutLUT = self.actionBlock(lut);
        [self.cachedOutLUT copyMetaPropertiesFromLUT:lut];
        return self.cachedOutLUT;
    }
}

-(NSString *)description{
    return [self.actionName stringByAppendingString:[NSString stringWithFormat:@": %@", [self actionDetails]]];
}

-(instancetype)copyWithZone:(NSZone *)zone{
    LUTAction *copiedAction = [LUTAction actionWithBlock:self.actionBlock actionName:[self.actionName copyWithZone:zone] actionMetadata:[self.actionMetadata copyWithZone:zone]];
    copiedAction.cachedInLUT = self.cachedInLUT;
    copiedAction.cachedOutLUT = self.cachedOutLUT;
    return copiedAction;
}

-(NSString *)actionDetails{
    NSString *outString = [NSString string];
    for(NSString *key in [self.actionMetadata allKeys]){
        if(![key isEqualToString:@"id"]){
            outString = [outString stringByAppendingString:[NSString stringWithFormat:@"\n%@: %@", key, self.actionMetadata[key]]];
        }
    }
    return outString;
}

+(instancetype)actionWithLUTByChangingInputLowerBound:(double)inputLowerBound
                                      inputUpperBound:(double)inputUpperBound{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"ChangeInputBounds"},
                                                           @{@"inputLowerBound": @(inputLowerBound)},
                                                           @{@"inputUpperBound": @(inputUpperBound)}]);
    
    return [self actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByChangingInputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    }
                              actionName:[NSString stringWithFormat:@"Change Input Bounds to [%.3f, %.3f]", inputLowerBound, inputUpperBound]
                          actionMetadata:actionMetadata];
}

+(instancetype)actionWithLUTByClampingLowerBound:(double)lowerBound
                                      upperBound:(double)upperBound{
    M13OrderedDictionary *actionMetadata =
    M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"id":@"Clamp"},
                                                           @{@"lowerBound": @(lowerBound)},
                                                           @{@"upperBound": @(upperBound)}]);
    
    return [LUTAction actionWithBlock:^LUT *(LUT *lut) {
        return [lut LUTByClampingLowerBound:lowerBound upperBound:upperBound];
    }
     
                           actionName:[NSString stringWithFormat:@"Clamp LUT to [%.3f, %.3f]", lowerBound, upperBound]
                       actionMetadata:actionMetadata];
}



@end