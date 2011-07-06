//  L0iPod.h

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

typedef enum {
    // internal, unused
    kL0iPodUnchecked = -1,
    
    // cannot determine the iPod type.
    kL0iPodGeneric = 0,
    
    // iPod, first or second generation
    kL0iPodMechanicalOrTouchWheel = 1,
    
    // iPod, third generation
    kL0iPodTouchWheelAndButtons = 2,
    
    // iPod mini (either first or second gen.)
    kL0iPodMini = 3,
    
    // iPod, fourth generation
    kL0iPodClickWheel = 4,
    
    // iPod photo or iPod with color display
    kL0iPodColorDisplay = 5,
    
    // iPod, fifth generation
    kL0iPodVideo = 6,
    
    // iPod nano
    kL0iPodNano = 7,
    
    // iPod shuffle
    kL0iPodShuffle = 128
} L0iPodFamily;

@interface L0iPod : NSObject {
    FSRef iPodRef;
    L0iPodFamily family;
}

// If the given path is inside an iPod, returns the absolute
// path to that iPod's mount point. Otherwise, returns nil.
+ (NSString*) deviceRootForPath:(NSString*) path;

// Is the given path an iPod mount point?
+ (BOOL) hasControlFolder:(NSString*) path;

// Returns the mount points of all mounted iPods.
+ (NSArray*) allMountedDevices;

// Initializes a L0iPod object that refers to the iPod that
// contains the given path. Returns the new object or nil if
// the path is not inside an iPod.
- (id) initWithPath:(NSString*) path;

// The file:// URL to the iPod mount point.
// Always returns the right URL, even if it has changed since
// you created this object. Returns nil if iPod was unmounted.
- (NSURL*) fileURL;

// The absolute path to the iPod mount point.
// Always returns the right path, even if it has changed since
// you created this object. Returns nil if iPod was unmounted.
- (NSString*) path;

// Returns the iPod's icon at a size of 32x32, as currently
// displayed by the Finder.
- (NSImage*) icon;

// Returns a dictionary containing the keys and values of the
// iPod's SysInfo file.
- (NSDictionary*) deviceInformation;

// Returns the iPod's family (one of the L0iPodFamily constants
// above).
- (L0iPodFamily) family;

// Does this iPod have a display?
- (BOOL) hasDisplay;

// Does this iPod have a color display?
- (BOOL) hasColorDisplay;

// Does this iPod have the Extras > Notes submenu?
- (BOOL) hasNotes;

// Can this iPod be connected to a TV (for photo or video
// viewing)?
- (BOOL) hasTVOut;

// Can this iPod play back video?
- (BOOL) hasVideoPlayback;

// Does this iPod have photo display capabilities?
- (BOOL) hasPhotoAlbum;

// The iPod's display name, as shown by the Finder, or
// nil if the iPod was unmounted.
- (NSString*) displayName;

@end