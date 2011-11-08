/* PDStylesBar */

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
