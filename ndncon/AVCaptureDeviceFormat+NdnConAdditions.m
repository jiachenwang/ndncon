//
//  AVCaptureDeviceFormat+NdnConAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "AVCaptureDeviceFormat+NdnConAdditions.h"

@implementation AVCaptureDeviceFormat (NdnConAdditions)

- (NSString *)localizedName
{
    NSString *localizedName = nil;
    
    CMMediaType mediaType = CMFormatDescriptionGetMediaType([self formatDescription]);
    
    switch (mediaType)
    {
        case kCMMediaType_Video:
        {
            CFStringRef formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions((CMVideoFormatDescriptionRef)[self formatDescription]);
            localizedName = [NSString stringWithFormat:@"%@, %d x %d", formatName, dimensions.width, dimensions.height];
        }
            break;
        case kCMMediaType_Audio:
        {
            CFStringRef formatName = NULL;
            AudioStreamBasicDescription const *originalASBDPtr = CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)[self formatDescription]);
            if (originalASBDPtr)
            {
                size_t channelLayoutSize = 0;
                AudioChannelLayout const *channelLayoutPtr = CMAudioFormatDescriptionGetChannelLayout((CMAudioFormatDescriptionRef)[self formatDescription], &channelLayoutSize);
                
                CFStringRef channelLayoutName = NULL;
                if (channelLayoutPtr && (channelLayoutSize > 0))
                {
                    UInt32 propertyDataSize = (UInt32)sizeof(channelLayoutName);
                    AudioFormatGetProperty(kAudioFormatProperty_ChannelLayoutName, (UInt32)channelLayoutSize, channelLayoutPtr, &propertyDataSize, &channelLayoutName);
                }
                
                if (channelLayoutName && (0 == CFStringGetLength(channelLayoutName)))
                {
                    CFRelease(channelLayoutName);
                    channelLayoutName = NULL;
                }
                
                AudioStreamBasicDescription modifiedASBD = *originalASBDPtr;
                if (channelLayoutName)
                {
                    // If the format will include the description of a channel layout, zero out mChannelsPerFrame so that the number of channels does not redundantly appear in the format string.
                    modifiedASBD.mChannelsPerFrame = 0;
                }
                
                UInt32 propertyDataSize = (UInt32)sizeof(formatName);
                AudioFormatGetProperty(kAudioFormatProperty_FormatName, (UInt32)sizeof(modifiedASBD), &modifiedASBD, &propertyDataSize, &formatName);
                if (!formatName)
                {
                    formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
                    if (formatName)
                        CFRetain(formatName);
                }
                
                if (formatName)
                {
                    if (channelLayoutName)
                    {
                        localizedName = [NSString stringWithFormat:@"%@, %@", formatName, channelLayoutName];
                    }
                    else
                    {
                        localizedName = [NSString stringWithFormat:@"%@", formatName];
                    }
                    
                    CFRelease(formatName);
                }
                
                if (channelLayoutName)
                    CFRelease(channelLayoutName);
            }
        }
            break;
        default:
            break;
    }
    
    return localizedName;
}

@end