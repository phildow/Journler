
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

#import "PDStylesBar.h"
#import "PDBorderedFill.h"
#import "JournlerEntry.h"

//#import "PDStylesButton.h"
//#import "PDButtonColorWell.h"

@implementation PDStylesBar

- (id) initWithTextView:(NSTextView*)textView 
{	
	if ( self = [super init] ) 
	{
		// handle disclosing the extended styles
		_extendedDisclosed = NO;
		
		// font manager and last font
		fm = [[NSFontManager sharedFontManager] retain];
		_lastFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
		
		// set the associated text and register for notifications
		[self setAssociatedText:textView];
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(extendedNotification:) 
				name:PDDiscloseExtendedStyles 
				object:nil];
		
		// load the styles bar
		[NSBundle loadNibNamed:@"PDStylesBar" owner:self];
		
		// show the styles bar if necessary
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"PDShowExtendedStyles"] )
			[extendedDisclosure performClick:self];		
	}
	
	return self;	
}

- (void) dealloc 
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[view release];
	view = nil;
	
	[extendedStyles release];
	extendedStyles = nil;
	
	[fm release];
	fm = nil;
	[_lastFont release];
	_lastFont = nil;
	
	[super dealloc];
}

- (void) awakeFromNib 
{
	// set our fillview's properties 
	// - Leopard addition because of window background color
	[view setBordered:NO];
	[view setFill:[NSColor windowBackgroundColor]];
	
	// customize the buttons
	NSMutableAttributedString *underlineAttrTitle = [[[buttonUnderline attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	[underlineAttrTitle addAttribute:NSUnderlineStyleAttributeName 
			value:[NSNumber numberWithDouble:(NSUnderlineStyleSingle|NSUnderlinePatternSolid)] 
			range:NSMakeRange(0,[underlineAttrTitle length])];
	[buttonUnderline setAttributedTitle:underlineAttrTitle];
		
	NSMutableAttributedString *shadowAttrTitle = [[[buttonShadow attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	NSShadow *theShadow = [[NSShadow alloc] init];
	[theShadow setShadowOffset:NSMakeSize(2.0,-2.0)];
	[theShadow setShadowBlurRadius:2.0];
	[theShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.7]];
	[shadowAttrTitle addAttribute:NSShadowAttributeName 
			value:theShadow 
			range:NSMakeRange(0,[shadowAttrTitle length])];
	[buttonShadow setAttributedTitle:shadowAttrTitle];
	[theShadow release];
	
	NSMutableAttributedString *strikeAttrTitle = [[[buttonStrike attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	[strikeAttrTitle addAttribute:NSStrikethroughStyleAttributeName 
			value:[NSNumber numberWithInteger:1] 
			range:NSMakeRange(0, [strikeAttrTitle length])];
	[buttonStrike setAttributedTitle:strikeAttrTitle];
	
	NSMutableAttributedString *despandAttrTitle = [[[buttonDespand attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	[despandAttrTitle addAttribute:NSExpansionAttributeName 
			value:[NSNumber numberWithFloat:-0.1] 
			range:NSMakeRange(0, [despandAttrTitle length])];
	[buttonDespand setAttributedTitle:despandAttrTitle];
	
	NSMutableAttributedString *expandAttrTitle = [[[buttonExpand attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	[expandAttrTitle addAttribute:NSExpansionAttributeName 
			value:[NSNumber numberWithFloat:0.3] 
			range:NSMakeRange(0, [expandAttrTitle length])];
	[buttonExpand setAttributedTitle:expandAttrTitle];
	
	[buttonSubscript setSuperscriptValue:-1];
	[buttonSuperscript setSuperscriptValue:1];
		
	NSMutableAttributedString *biggerAttrTitle = [[[buttonBigger attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	NSFont *biggerFont = [biggerAttrTitle attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
	[biggerAttrTitle addAttribute:NSFontAttributeName 
			value:[fm convertFont:biggerFont toSize:[biggerFont pointSize]-2] 
			range:NSMakeRange(0,1)];
	[biggerAttrTitle addAttribute:NSFontAttributeName 
			value:[fm convertFont:biggerFont toSize:[biggerFont pointSize]+2] 
			range:NSMakeRange(1,1)];
	[buttonBigger setAttributedTitle:biggerAttrTitle];
	
	NSMutableAttributedString *smallerAttrTitle = [[[buttonSmaller attributedTitle] mutableCopyWithZone:[self zone]] autorelease];
	NSFont *smallerFont = [smallerAttrTitle attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
	[smallerAttrTitle addAttribute:NSFontAttributeName 
			value:[fm convertFont:smallerFont toSize:[biggerFont pointSize]+2] 
			range:NSMakeRange(0,1)];
	[smallerAttrTitle addAttribute:NSFontAttributeName 
			value:[fm convertFont:smallerFont toSize:[biggerFont pointSize]-2] 
			range:NSMakeRange(1,1)];
	[buttonSmaller setAttributedTitle:smallerAttrTitle];
}

#pragma mark -

- (NSView*) view { return view; }

- (NSTextView*) associatedText {
	return _associatedText;
}

- (void) setAssociatedText:(NSTextView*)aTextView 
{	
	if ( _associatedText != aTextView )
	{
		// could probably be removing earlier notifiations
		// but I never anticipated this being called more than once at init
		
		// retain?
		_associatedText = aTextView;
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(updateView:) 
				name:NSTextViewDidChangeSelectionNotification 
				object:_associatedText];
				
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(updateView:) 
				name:NSTextViewDidChangeTypingAttributesNotification 
				object:_associatedText];

		// fake an attributed change notification to update the styles bar
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTextViewDidChangeTypingAttributesNotification 
				object:_associatedText 
				userInfo:nil];
	}
}

#pragma mark -

- (void) clearWithDefaultFont:(NSFont*)font color:(NSColor*)fontColor 
{	
	// the font name
	NSString *button_title = [NSString stringWithFormat:@"%@ %ipt", [font displayName], (NSInteger)[font pointSize]];
	[buttonFont setTitle:button_title];
	
	// potenially standard attributes
	if ( [[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask )
		[buttonBold setState:NSOnState];
	else
		[buttonBold setState:NSOffState];
		
	if ( [[NSFontManager sharedFontManager] traitsOfFont:font] & NSItalicFontMask )
		[buttonItalic setState:NSOnState];
	else
		[buttonItalic setState:NSOffState];
	
	// non-standard attributes
	[buttonUnderline setState:NSOffState];
	[buttonShadow setState:NSOffState];
	[buttonStrike setState:NSOffState];
	
	[buttonColor setColor:[NSColor blackColor]];
}

- (void) updateView:(NSNotification*)aNotification 
{
	NSDictionary *attrs = [[aNotification object] typingAttributes];
	NSFont *font = [attrs objectForKey:NSFontAttributeName];
	
	// bad hack to clear out the text
	if ( ![_associatedText isEditable] ) {
		
		#warning should have a variable for default attributes rather than grab from JournlerEntry
		NSDictionary *default_attributes = [JournlerEntry defaultTextAttributes];
		
		[self clearWithDefaultFont:[default_attributes objectForKey:NSFontAttributeName] 
				color:[default_attributes objectForKey:NSForegroundColorAttributeName]];
	
		return;
	}
	
	if ( font && ![font isEqual:_lastFont] ) 
	{
		// the font name
		[buttonFont setTitle:[NSString stringWithFormat:@"%@ %ipt", [font displayName], (NSInteger)[font pointSize]]];
		
		// bold - why not using & operation like above?
		if ( BitAnd(NSBoldFontMask,[fm traitsOfFont:font]) == NSBoldFontMask )
			[buttonBold setState:NSOnState];
		else
			[buttonBold setState:NSOffState];
		
		// italic
		if ( BitAnd(NSItalicFontMask,[fm traitsOfFont:font]) == NSItalicFontMask )
			[buttonItalic setState:NSOnState];
		else
			[buttonItalic setState:NSOffState];
	
	}
	
	// underline
	if ( [attrs objectForKey:NSUnderlineStyleAttributeName] && [[attrs objectForKey:NSUnderlineStyleAttributeName] integerValue] != 0 )
		[buttonUnderline setState:NSOnState];
	else
		[buttonUnderline setState:NSOffState];
	
	// shadow
	if ( [attrs objectForKey:NSShadowAttributeName] )
		[buttonShadow setState:NSOnState];
	else
		[buttonShadow setState:NSOffState];
	
	// strikethrough
	if ( [attrs objectForKey:NSStrikethroughStyleAttributeName] && [[attrs objectForKey:NSStrikethroughStyleAttributeName] integerValue] != 0 )
		[buttonStrike setState:NSOnState];
	else
		[buttonStrike setState:NSOffState];
	
	// color
	if ( [attrs objectForKey:NSForegroundColorAttributeName] )
		[buttonColor setColor:[attrs objectForKey:NSForegroundColorAttributeName]];
	else
		[buttonColor setColor:[NSColor blackColor]];
	
	
	[buttonDespand setState:NSOffState];
	[buttonExpand setState:NSOffState];
	[buttonSuperscript setState:NSOffState];
	[buttonSubscript setState:NSOffState];
	[buttonBigger setState:NSOffState];
	[buttonSmaller setState:NSOffState];
}

#pragma mark -

- (IBAction) bold:(id)sender 
{	
	if ( [sender state] == NSOnState )
		[[NSFontManager sharedFontManager] addFontTrait:sender];
	else
		[[NSFontManager sharedFontManager] removeFontTrait:sender];	
}

- (IBAction) italic:(id)sender 
{	
	if ( [sender state] == NSOnState )
		[[NSFontManager sharedFontManager] addFontTrait:sender];
	else
		[[NSFontManager sharedFontManager] removeFontTrait:sender];	
}

- (IBAction) shadow:(id)sender 
{	
	if ( ![_associatedText shouldChangeTextInRange:[_associatedText rangeForUserTextChange] replacementString:nil] ) 
	{
		NSBeep();
		return;
	}
	
	[[_associatedText textStorage] beginEditing];
	
	if ( [sender state] == NSOnState ) 
	{
		NSShadow *theShadow = [[NSShadow alloc] init];
		
		[theShadow setShadowOffset:NSMakeSize(2.0,-2.0)];
		[theShadow setShadowBlurRadius:2.0];
		[theShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.7]];
		
		[[_associatedText textStorage] 
				addAttribute:NSShadowAttributeName 
				value:theShadow 
				range:[_associatedText rangeForUserTextChange]];
		
		[theShadow release];
		
	}
	else
	{
		[[_associatedText textStorage] 
				removeAttribute:NSShadowAttributeName 
				range:[_associatedText rangeForUserTextChange]];
	}
	
	
	[[_associatedText textStorage] endEditing];
	[_associatedText didChangeText];
}

- (IBAction) strikethrough:(id)sender 
{	
	if ( ![_associatedText shouldChangeTextInRange:[_associatedText rangeForUserTextChange] replacementString:nil] ) 
	{
		NSBeep();
		return;
	}
	
	[[_associatedText textStorage] beginEditing];
	
	if ( [sender state] == NSOnState )
		[[_associatedText textStorage]
				addAttribute:NSStrikethroughStyleAttributeName 
				value:[NSNumber numberWithInteger:1] 
				range:[_associatedText rangeForUserTextChange]];
	else
		[[_associatedText textStorage]
				addAttribute:NSStrikethroughStyleAttributeName 
				value:[NSNumber numberWithInteger:0] 
				range:[_associatedText rangeForUserTextChange]];				
	
	[[_associatedText textStorage] endEditing];
	[_associatedText didChangeText];
}



- (IBAction) despand:(id)sender 
{	
	//NSExpansion -2.0 -> 2.0 : 0.1
	
	if ( ![_associatedText shouldChangeTextInRange:[_associatedText rangeForUserTextChange] replacementString:nil] ) 
	{
		NSBeep();
		return;
	}
	
	NSNumber *newExpansion;
	NSNumber *originalExpansion = [[_associatedText textStorage] 
			attribute:NSExpansionAttributeName 
			atIndex:[_associatedText rangeForUserTextChange].location 
			effectiveRange:nil];
	
	if ( originalExpansion == nil )
		originalExpansion = [NSNumber numberWithFloat:0.0];
	
	newExpansion = [NSNumber numberWithFloat:[originalExpansion floatValue] - 0.1];
	
	[[_associatedText textStorage] beginEditing];
	[[_associatedText textStorage] addAttribute:NSExpansionAttributeName 
			value:newExpansion 
			range:[_associatedText 
			rangeForUserTextChange]];
			
	[[_associatedText textStorage] endEditing];
	[_associatedText didChangeText];
}

- (IBAction) expand:(id)sender 
{
	//NSExpansion -2.0 -> 2.0 : 0.1
	
	if ( ![_associatedText shouldChangeTextInRange:[_associatedText rangeForUserTextChange] replacementString:nil] ) 
	{
		NSBeep();
		return;
	}
	
	NSNumber *newExpansion;
	NSNumber *originalExpansion = [[_associatedText textStorage] 
			attribute:NSExpansionAttributeName 
			atIndex:[_associatedText rangeForUserTextChange].location 
			effectiveRange:nil];
	
	if ( !originalExpansion )
		originalExpansion = [NSNumber numberWithFloat:0.0];
	
	newExpansion = [NSNumber numberWithFloat:[originalExpansion floatValue] + 0.1];
	
	[[_associatedText textStorage] beginEditing];
	[[_associatedText textStorage] addAttribute:NSExpansionAttributeName 
			value:newExpansion
			range:[_associatedText rangeForUserTextChange]];
			
	[[_associatedText textStorage] endEditing];	
	[_associatedText didChangeText];
}

- (IBAction) bigger:(id)sender 
{
	[[NSFontManager sharedFontManager] modifyFont:sender];
}

- (IBAction) smaller:(id)sender 
{
	[[NSFontManager sharedFontManager] modifyFont:sender];
}

#pragma mark -

- (IBAction) discloseExtendedAction:(id)sender 
{
	// post a notification so that all styles bar receive the message
	[[NSNotificationCenter defaultCenter] postNotificationName:PDDiscloseExtendedStyles object:self 
	userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:([sender state]==NSOnState?YES:NO)] forKey:@"DiscloseExtended"]];
}

- (void) extendedNotification:(NSNotification*)aNotification 
{
	BOOL doDisclose = [[[aNotification userInfo] objectForKey:@"DiscloseExtended"] boolValue];
	
	[self discloseExtended:doDisclose];
	[extendedDisclosure setState:(doDisclose?NSOnState:NSOffState)];
}

- (void) discloseExtended:(BOOL)show 
{
	NSView *innie = nil;
	NSView *auie = nil;
	
	if ( show && show != _extendedDisclosed) 
	{
		// show the extended styles
		innie = extendedStyles;
		auie = extendedPlaceholder;
	}
	else if ( !show && show != _extendedDisclosed ) 
	{
		// hide the extended styles
		innie = extendedPlaceholder;
		auie = extendedStyles;
	}
	
	if ( innie && auie ) 
	{
		[innie retain];
		[innie removeFromSuperviewWithoutNeedingDisplay];
		[innie setFrame:[auie frame]];
		[auie retain];
					
		[view replaceSubview:auie with:innie];
	}
	
	// set the internal bool and prefs
	_extendedDisclosed = show;
	[[NSUserDefaults standardUserDefaults] setBool:show forKey:@"PDShowExtendedStyles"];
}

- (void) fadeIn:(NSView*)innie outView:(NSView*)auie parentView:(NSView*)parent 
{
	
	[innie setHidden:YES];
	[parent addSubview:innie];
	
	NSViewAnimation *theAnim;
							
	NSDictionary *theDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			innie, NSViewAnimationTargetKey, 
			NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
	
	NSDictionary *otherDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			auie, NSViewAnimationTargetKey, 
			NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
	
	theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:theDict, otherDict, nil]];
	[theAnim startAnimation];
	
	// clean up
	[theAnim release];
	[theDict release];
	[otherDict release];
}

#pragma mark -

- (IBAction) launchColorPanel:(id) sender 
{
	[[NSColorPanel sharedColorPanel] setColor:[buttonColor color]];
	[NSApp orderFrontColorPanel:sender];
}

- (IBAction) launchFontPanel:(id) sender
{
	[[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
	[sender setState:NSOffState];
}

@end
