/* PDStylesBar */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class PDBorderedFill;

//@class PDStylesButton;
//@class PDButtonColorWell;

#define PDDiscloseExtendedStyles				@"Disclose Extended Styles Notification"

@interface PDStylesBar : NSObject
{
    IBOutlet PDBorderedFill *view;
	
	IBOutlet PDStylesButton			*buttonBold;
	IBOutlet PDStylesButton			*buttonItalic;
	IBOutlet PDStylesButton			*buttonUnderline;
	IBOutlet PDStylesButton			*buttonShadow;
	IBOutlet PDStylesButton			*buttonStrike;
	IBOutlet PDStylesButton			*buttonFont;
	IBOutlet PDButtonColorWell		*buttonColor;
	
	IBOutlet NSButton				*extendedDisclosure;
	IBOutlet NSView					*extendedStyles;
	IBOutlet NSView					*extendedPlaceholder;
	
	IBOutlet PDStylesButton			*buttonDespand;
	IBOutlet PDStylesButton			*buttonExpand;
	IBOutlet PDStylesButton			*buttonSuperscript;
	IBOutlet PDStylesButton			*buttonSubscript;
	IBOutlet PDStylesButton			*buttonBigger;
	IBOutlet PDStylesButton			*buttonSmaller;
	
	NSFontManager					*fm;
	NSFont							*_lastFont;
	NSTextView						*_associatedText;
	
	BOOL							_extendedDisclosed;
	
}

- (id) initWithTextView:(NSTextView*)textView;

- (NSView*) view;

- (NSTextView*) associatedText;
- (void) setAssociatedText:(NSTextView*)aTextView;

- (void) clearWithDefaultFont:(NSFont*)font color:(NSColor*)fontColor;
- (void) updateView:(NSNotification*)aNotification;

- (IBAction) bold:(id)sender;
- (IBAction) italic:(id)sender;
- (IBAction) shadow:(id)sender;
- (IBAction) strikethrough:(id)sender;
- (IBAction) despand:(id)sender;
- (IBAction) expand:(id)sender;
- (IBAction) bigger:(id)sender;
- (IBAction) smaller:(id)sender;

- (IBAction) discloseExtendedAction:(id)sender;
- (void) discloseExtended:(BOOL)show;

- (void) fadeIn:(NSView*)innie outView:(NSView*)auie parentView:(NSView*)parent;

- (IBAction) launchColorPanel:(id) sender;
- (IBAction) launchFontPanel:(id) sender;

@end
