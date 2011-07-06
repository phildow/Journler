//
//  PolishedWindow.h
//  TunesWindow
//
//  Created by Matt Gemmell on 12/02/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// offers the 10.5 window look in 10.4

@interface PolishedWindow : NSWindow {
    BOOL _flat;
    BOOL forceDisplay;
	
	// PD Modifications to improve rendering during drag
	NSImage *bottomLeft;
    NSImage *bottomMiddle;
    NSColor *bottomMiddlePattern;
    NSImage *bottomRight;
    NSImage *topLeft;
    NSImage *topMiddle;
    NSColor *topMiddlePattern;
    NSImage *topRight;
    NSImage *middleLeft;
    NSImage *middleRight;
	// End modifications
}

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)styleMask 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag 
                     flat:(BOOL)flat;

- (NSColor *)sizedPolishedBackground;

- (BOOL)flat;
- (void)setFlat:(BOOL)newFlat;

@end