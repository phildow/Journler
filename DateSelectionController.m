
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

#import "DateSelectionController.h"

#import "PDDatePicker.h"

#define kDSClearDateCode -11

@implementation DateSelectionController

- (id) init {
	self = [self initWithDate:[NSDate date] key:nil];
	return self;
}

- (id) initWithDate:(NSDate*)aDate key:(NSString*)aKey;
{
	if ( self = [super initWithWindowNibName:@"DateSelector"] ) 
	{
		date = (aDate != nil ? [aDate copyWithZone:[self zone]] : [[NSDate date] retain] );
		key = [aKey copyWithZone:[self zone]];
		
		usesGraphicalEditor = [[NSUserDefaults standardUserDefaults] boolForKey:@"EditDatesWithGraphicalInterface"];
		if ( ![self isWindowLoaded] )
			[self window];
		
		targetWindow = ( usesGraphicalEditor == YES ? graphicalWindow : textualWindow );
		
		[self retain];
	}
	return self;
}

- (void) awakeFromNib
{
	NSInteger borders[4] = {0,0,0,0};
	[gradient setBordered:NO];
	[gradient setBorders:borders];
	
	[gradientB setBordered:NO];
	[gradientB setBorders:borders];
	
	[datePicker setEnterOnlyTarget:self];
	[datePicker setEnterOnlyAction:@selector(saveDate:)];
	
}

- (void) dealloc 
{
	#ifdef __DEBUG__
		NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[date release];
	[representedObject release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) usesGraphicalEditor
{
	return usesGraphicalEditor;
}

- (void) setUsesGraphicalEditor:(BOOL)graphical
{
	if ( usesGraphicalEditor == graphical )
		return;
	
	usesGraphicalEditor = graphical;
	if ( ![self isWindowLoaded] )
		[self window];
	
	if ( usesGraphicalEditor )
	{
		targetWindow = graphicalWindow;
	}
	else
	{
		targetWindow = textualWindow;
	}
}

- (NSDate*) date 
{ 
	return date; 
}

- (void) setDate:(NSDate*)aDate 
{
	if ( date != aDate ) 
	{
		[date release];
		date = [aDate copyWithZone:[self zone]];
		if ( date == nil )
			date = [[NSDate date] retain];
	}
}

- (NSString*) key
{
	return key;
}

- (void) setKey:(NSString*)aString
{
	if ( key != aString )
	{
		[key release];
		key = [aString copyWithZone:[self zone]];
	}
}

- (id) delegate 
{ 
	return delegate; 
}

- (void) setDelegate:(id)anObject 
{
	delegate = anObject;
}

- (id) representedObject 
{
	return representedObject;
}

- (void) setRepresentedObject:(id)anObject 
{
	if ( representedObject != anObject )
	{
		[representedObject release];
		representedObject = [anObject retain];
	}
}

- (BOOL) clearDateHidden
{
	return clearDateHidden;
}

- (void) setClearDateHidden:(BOOL)hidden
{
	clearDateHidden = hidden;
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{	
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];

	[self autorelease];
}

- (void) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet location:(NSRect)frame 
{	
	NSInteger result = NSRunAbortedResponse;
	isSheet = sheet;
	
	id originalDelegate = [window delegate];
	[window setDelegate:self];
	
	if ( sheet ) 
	{
		sheetFrame = frame;
		sheetFrame.size.height = 0;
		
		//[NSApp beginSheet: [self window] modalForWindow: window modalDelegate: self
		//		didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: nil];
		[NSApp beginSheet: targetWindow modalForWindow: window modalDelegate: self
				didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: nil];
	}
	else 
	{
		//result = [NSApp runModalForWindow: [self window]];
		result = [NSApp runModalForWindow: targetWindow];
		
		if ( ![objectController commitEditing] )
			NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
	}
	
	if ( !isSheet && result == NSRunAbortedResponse ) 
	{
		// only possible if ran as modal and the date was canceled
		if ( [delegate respondsToSelector:@selector(dateSelectorDidCancelDateSelection:)] )
			[delegate dateSelectorDidCancelDateSelection:self];
			
		//[[self window] close];
		[targetWindow close];
	}
	else if ( !isSheet && result == NSRunStoppedResponse ) 
	{
		// only possible if ran as modal and the date was saved
		if ( [delegate respondsToSelector:@selector(dateSelector:didSaveDate:key:)] )
			[delegate dateSelector:self didSaveDate:[self date] key:[self key]];
			
		//[[self window] close];
		[targetWindow close];
	}
	
	[window setDelegate:originalDelegate];
}

- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo 
{	
	if ( ![objectController commitEditing] )
		NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
	
	if ( returnCode == NSRunAbortedResponse && [delegate respondsToSelector:@selector(dateSelectorDidCancelDateSelection:)] )
		[delegate dateSelectorDidCancelDateSelection:self];
			
	else if ( returnCode == NSRunStoppedResponse && [delegate respondsToSelector:@selector(dateSelector:didSaveDate:key:)] )
		[delegate dateSelector:self didSaveDate:[self date] key:[self key]];
	
	else if ( returnCode == kDSClearDateCode && [delegate respondsToSelector:@selector(dateSelector:didClearDateForKey:)] )
		[delegate dateSelector:self didClearDateForKey:[self key]];
	
	//[[self window] close];
	[targetWindow close];
}

#pragma mark -

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect 
{
	return sheetFrame;
}

#pragma mark -

- (IBAction) saveDate:(id)sender 
{	
	if ( isSheet )
		//[NSApp endSheet:[self window] returnCode:NSRunStoppedResponse];
		[NSApp endSheet:targetWindow returnCode:NSRunStoppedResponse];
	else
		[NSApp stopModal];
}

- (IBAction) cancelDate:(id)sender 
{	
	if ( isSheet )
		[NSApp endSheet:targetWindow returnCode:NSRunAbortedResponse];
	else
		[NSApp abortModal];
}

- (IBAction) clearDate:(id)sender 
{	
	if ( isSheet )
		[NSApp endSheet:targetWindow returnCode:kDSClearDateCode];
	else
		[NSApp abortModal];
}

@end
