//
//  DropBoxSourceList.m
//  Journler
//
//  Created by Phil Dow on 3/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DropBoxSourceList.h"


@implementation DropBoxSourceList

- (void) awakeFromNib {

	[self setIntercellSpacing:NSMakeSize(0.0,0.0)];
			
	_searchString = [[NSMutableString alloc] init];
	
	[self setAutoresizesOutlineColumn:NO];
	
	// appearance bindings
	[self bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
		withKeyPath:@"values.FoldersTableFont" options:[NSDictionary dictionaryWithObjectsAndKeys:
		@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
		[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
}

- (void)keyDown:(NSEvent *)event
{
	static unichar kUnicharKeyReturn = '\r';
	static unichar kUnicharKeyNewline = '\n';
	
	//unsigned int flags = [event modifierFlags];
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if ( key == kUnicharKeyReturn || key == kUnicharKeyNewline || [event keyCode] == 53 )
		[[self window] keyDown:event];
	else
		[super keyDown:event];
}


- (BOOL)needsPanelToBecomeKey
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	BOOL became = [super becomeFirstResponder];
	if ( became == YES && [self selectedRow] == -1 && [self numberOfRows] != 0 )
		[self selectRow:0 byExtendingSelection:NO];
	
	return became;
}

@end
