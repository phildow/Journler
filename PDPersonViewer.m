//
//  CustomView.m
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/18/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

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

#import "PDPersonViewer.h"
#import "PDPersonPropertyCell.h"
#import "PDPersonPropertyField.h"

#define kImageDimension 64
#define kPadding 10
#define kInterPropertyPadding 15
#define kNameFontHeight 20
#define kCompanyFontHeight 16
#define kHorizontalRuleHeight 84
#define kPropertiesOffset 100

#pragma mark -

@implementation PDPersonViewer

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
        // Initialization code here.
		
		propertyFields = [[NSMutableArray alloc] init];
		trackingRects = [[NSMutableArray alloc] init];
		
		drawsBackground = NO;
		backgroundColor = [[NSColor whiteColor] retain];
		
		[self setPostsBoundsChangedNotifications:YES];
		[self setPostsFrameChangedNotifications:YES];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(boundsChanged:) 
				name:NSViewBoundsDidChangeNotification 
				object:self];
				
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(boundsChanged:) 
				name:NSViewFrameDidChangeNotification 
				object:self];
		
		//[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil]];

    }
    return self;
}

- (void) dealloc 
{
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[person release];
	person = nil;
	
	[propertyFields release];
	propertyFields = nil;
	
	[trackingRects release];
	trackingRects = nil;
	
	[super dealloc];
}

#pragma mark -

- (ABPerson*) person 
{
	return person;
}

- (void) setPerson:(ABPerson*)aPerson 
{
	if ( person != aPerson ) 
	{
		[person release];
		person = [aPerson retain];
		
		[self updatePropertyFields];
		[self updatePropertyFieldLocations];
		[self resetCursorRects];
	}
}

- (id) target 
{
	return target;
}

- (void) setTarget:(id)anObject 
{
	target = anObject;
}

- (SEL) action 
{
	return action;
}

- (void) setAction:(SEL)selector 
{
	action = selector;
}

- (BOOL) drawsBackground 
{
	return drawsBackground;
}

- (void) setDrawsBackground:(BOOL)draws
{
	drawsBackground = draws;
}

- (NSColor*) backgroundColor
{
	return backgroundColor;
}

- (void) setBackgroundColor:(NSColor*)aColor
{
	if ( backgroundColor != aColor )
	{
		[backgroundColor release];
		backgroundColor = [aColor copyWithZone:[self zone]];
	}
}

#pragma mark -

- (void)drawRect:(NSRect)rect 
{
    // Drawing code here.
	
	ABPerson *aPerson = [self person];
	if ( aPerson == nil )
		return;
	
	NSRect bds = [self bounds];
	
	NSMutableString *name;
	NSString *firstName, *lastName, *middleName, *prefix, *suffix;
	
	NSMutableString *companyTitle;
	NSString *jobTitle, *jobDepartment, *jobCompany;
	
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// the background
	if ( [self drawsBackground] )
	{
		[[self backgroundColor] set];
		NSRectFill(bds);
	}
	
	//
	// the person's image
	
	NSData *tiffData;
	NSImage *personImage = nil;
	
	tiffData = [aPerson imageData];
	if ( tiffData != nil ) 
		personImage = [[[NSImage alloc] initWithData:tiffData] autorelease];
	else
		personImage = [NSImage imageNamed:@"vCard.tiff"];
	
	NSRect imageDestination = NSMakeRect( kPadding, kPadding, kImageDimension, kImageDimension );
	[personImage setFlipped:[self isFlipped]];
	[personImage drawInRect:imageDestination fromRect:NSMakeRect(0,0,[personImage size].width,[personImage size].height)
			operation:NSCompositeSourceOver fraction:1.0];

	
	//
	// the person's title
	
	name = [[[NSMutableString alloc] init] autorelease];
	
	prefix = [aPerson valueForProperty:kABTitleProperty];
	suffix = [aPerson valueForProperty:kABSuffixProperty];
	firstName = [aPerson valueForProperty:kABFirstNameProperty];
	lastName = [aPerson valueForProperty:kABLastNameProperty];
	middleName = [aPerson valueForProperty:kABMiddleNameProperty];
	
	//create the name string
	if ( !prefix && !suffix && !firstName && !lastName && !middleName ) 
	{
		
		//maybe this is a company?
		NSString *orgProperty = [aPerson valueForProperty:kABOrganizationProperty];
		if ( orgProperty) [name appendString:orgProperty];
		
	}
	else
	{
		
		// prepare the person's name
		if ( prefix ) 
		{
			[name appendString:prefix];
			if ( firstName || middleName || lastName || suffix ) [name appendString:@" "];
		}
		if ( firstName ) 
		{
			[name appendString:firstName];
			if ( middleName || lastName || suffix) [name appendString:@" "];
		}
		if ( middleName ) 
		{
			[name appendString:middleName];
			if ( lastName || suffix) [name appendString:@" "];
		}
		if ( lastName ) 
		{
			[name appendString:lastName];
			if ( suffix ) [name appendString:@" "];
		}
		if ( suffix ) 
		{
			[name appendString:suffix];
		}
	}	
	
	NSDictionary *nameAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName, 
			[NSFont systemFontOfSize:kNameFontHeight], NSFontAttributeName, 
			[NSColor blackColor], NSForegroundColorAttributeName,nil];
	
	NSSize nameSize = [name sizeWithAttributes:nameAttributes];
	NSRect nameDestination = NSMakeRect(	kImageDimension + kPadding*2, 
											kPadding*2, 
											bds.size.width - kImageDimension - kPadding*3, nameSize.height );
											
	[name drawInRect:nameDestination withAttributes:nameAttributes];
	
	
	//
	// prepare the job information
	
	companyTitle = [[[NSMutableString alloc] init] autorelease];
	
	jobTitle = [aPerson valueForKey:kABJobTitleProperty];
	jobDepartment = [aPerson valueForKey:kABDepartmentProperty];
	jobCompany = [aPerson valueForKey:kABOrganizationProperty];
	
	if ( jobTitle ) 
	{
		[companyTitle appendString:jobTitle];
		if ( jobDepartment ) [companyTitle appendString:@" - "];
		else if ( jobCompany ) [companyTitle appendString:@", "];
	}
	if ( jobDepartment ) 
	{
		[companyTitle appendString:jobDepartment];
		if ( jobCompany ) [companyTitle appendString:@", "];
	}
	if ( jobCompany ) 
	{
		[companyTitle appendString:jobCompany];
	}

	NSDictionary *companyAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName, 
			[NSFont systemFontOfSize:kCompanyFontHeight], NSFontAttributeName, 
			[NSColor darkGrayColor], NSForegroundColorAttributeName, nil];
	
	NSSize companySize = [companyTitle sizeWithAttributes:companyAttributes];
	NSRect companyDestination = NSMakeRect( kImageDimension + kPadding*2, 
											kPadding*2 + nameSize.height + kPadding/2,
											bds.size.width - kImageDimension - kPadding*3, companySize.height );
											
	[companyTitle drawInRect:companyDestination withAttributes:companyAttributes];
	
	//
	// draw the horizontal rule
	
	[[NSColor lightGrayColor] set];
	NSRectFill( NSMakeRect(kPadding, kHorizontalRuleHeight, bds.size.width - kPadding*2, 1) );
	
	if ( drawsNoteRule ) 
	{
		[[NSColor lightGrayColor] set];
		NSRectFill( NSMakeRect(kPadding, noteRuleHeight, bds.size.width - kPadding*2, 1) );
	}
	
}

- (BOOL) isFlipped 
{
	return YES;
}

#pragma mark -

- (void)resetCursorRects 
{
	
	NSInteger i;
	
	for ( i = 0; i < [trackingRects count]; i++ )
		[self removeTrackingRect:[[trackingRects objectAtIndex:i] integerValue]];
	
	[trackingRects removeAllObjects];
	
	if ( [propertyFields count] == 0 )
		return;

	for ( i = 0; i < [propertyFields count]; i++ ) 
	{
		
		PDPersonPropertyField *field = [propertyFields objectAtIndex:i];
		
		NSTrackingRectTag trackTag = [self addTrackingRect:[[field cell] 
				labelBoundsForCellFrame:[field frame]] owner:self userData:field assumeInside:NO];
				
		[trackingRects addObject:[NSNumber numberWithInteger:trackTag]];
	
	}

}

- (void) boundsChanged:(NSNotification*)aNotification {
	[self updatePropertyFieldLocations];
}

#pragma mark -

- (void) updatePropertyFieldLocations 
{
	
	NSInteger i;
	NSString *thisProperty, *lastProperty;
	float totalOffset = kPropertiesOffset;
	
	NSRect bds = [self bounds];
	
	drawsNoteRule = NO;
	
	if ( [propertyFields count] == 0 )
		return;
	
	lastProperty = [[propertyFields objectAtIndex:0] property];
	
	for ( i = 0; i < [propertyFields count]; i++ ) 
	{
		
		thisProperty = [[propertyFields objectAtIndex:i] property];
		
		if ( ![thisProperty isEqualToString:lastProperty] ) 
		{
			
			// only adjust the offset if we haven't already done so because of an address
			if ( ![lastProperty isEqualToString:kABAddressProperty] )
				totalOffset += kInterPropertyPadding;
				
			lastProperty = thisProperty;
		}
		
		if ( [thisProperty isEqualToString:kABNoteProperty] && drawsNoteRule == NO ) 
		{
			drawsNoteRule = YES;
			noteRuleHeight = totalOffset;
			totalOffset += kInterPropertyPadding;
		}
		
		NSSize propertySize;
		propertySize = [[[propertyFields objectAtIndex:i] cell] cellSizeWithWidth:(bds.size.width-kPadding*2)];
		
		NSRect propertyFrame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, propertySize.height);
		[[propertyFields objectAtIndex:i] setFrame:propertyFrame];
		
		totalOffset += propertyFrame.size.height;
		if ( [thisProperty isEqualToString:kABAddressProperty] )
			totalOffset += kInterPropertyPadding;
		
	}
	
	// extra space
	totalOffset += kPadding;
	
	// resize the view's frame for the scroller - does not mark for redisplay
	[self setFrameSize:NSMakeSize([self frame].size.width, totalOffset)];

	[self setNeedsDisplay:YES];
	
}


- (void) updatePropertyFields 
{
	
	[propertyFields makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[propertyFields removeAllObjects];
	
	NSSize propertySize;
	
	NSRect bds = [self bounds];
	
	ABPerson *aPerson = [self person];
	if ( aPerson == nil )
		return;

	NSString *note;
	ABMultiValue *phoneRecords, *emailRecords, *urlRecords, *addressRecords;

	float totalOffset = kPropertiesOffset;
	
	phoneRecords = [aPerson valueForProperty:kABPhoneProperty];
	if ( phoneRecords != nil && [phoneRecords count] != 0 ) {
		
		NSInteger i;
		for ( i = 0; i < [phoneRecords count]; i++ ) 
		{
			
			NSRect frame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, 20);
			PDPersonPropertyField *propertyField = [[self newPropertyFieldWithFrame:frame property:kABPhoneProperty 
					label:ABLocalizedPropertyOrLabel([phoneRecords labelAtIndex:i]) content:[phoneRecords valueAtIndex:i] 
					target:self action:@selector(showFieldMenu:)] autorelease];
			
			[propertyFields addObject:propertyField];
			[self addSubview:propertyField];
			
			totalOffset += propertySize.height;
		}
			
		// extra spacing
		totalOffset += kInterPropertyPadding;
		
	}
	
	
	emailRecords = [aPerson valueForProperty:kABEmailProperty];
	if ( emailRecords != nil && [emailRecords count] != 0 ) 
	{
		
		NSInteger i;
		for ( i = 0; i < [emailRecords count]; i++ ) 
		{
			
			NSRect frame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, 20);
			PDPersonPropertyField *propertyField = [[self newPropertyFieldWithFrame:frame property:kABEmailProperty 
					label:ABLocalizedPropertyOrLabel([emailRecords labelAtIndex:i]) content:[emailRecords valueAtIndex:i] 
					target:self action:@selector(showFieldMenu:)] autorelease];
			
			[propertyFields addObject:propertyField];
			[self addSubview:propertyField];
			
			totalOffset += propertySize.height;
		
		}
		
		// extra spacing
		totalOffset += kInterPropertyPadding;

	}
		
	
	urlRecords = [aPerson valueForProperty:kABURLsProperty];
	if ( urlRecords != nil && [urlRecords count] != 0 ) 
	{
		
		NSInteger i;
		for ( i = 0; i < [urlRecords count]; i++ ) 
		{
			
			NSRect frame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, 20);
			PDPersonPropertyField *propertyField = [[self newPropertyFieldWithFrame:frame property:kABURLsProperty 
					label:ABLocalizedPropertyOrLabel([urlRecords labelAtIndex:i]) content:[urlRecords valueAtIndex:i] 
					target:self action:@selector(showFieldMenu:)] autorelease];

			[propertyFields addObject:propertyField];
			[self addSubview:propertyField];

			totalOffset += propertySize.height;
		
		}
		
		// extra spacing
		totalOffset += kInterPropertyPadding;

	}
		
	addressRecords = [aPerson valueForProperty:kABAddressProperty];
	if ( addressRecords != nil && [addressRecords count] != 0 ) 
	{
		
		NSInteger i;
		for ( i = 0; i < [addressRecords count]; i++ ) 
		{
			
			NSAttributedString *formattedAddress = [[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:[addressRecords valueAtIndex:i]];
			NSMutableString *formattedString = [[[formattedAddress string] mutableCopyWithZone:[self zone]] autorelease];
			
			[formattedString replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[formattedString length])];
						
			NSRect frame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, 20);
			PDPersonPropertyField *propertyField = [[self newPropertyFieldWithFrame:frame property:kABAddressProperty 
					label:ABLocalizedPropertyOrLabel([addressRecords labelAtIndex:i]) content:formattedString 
					target:self action:@selector(showFieldMenu:)] autorelease];
			
			[propertyFields addObject:propertyField];
			[self addSubview:propertyField];
			
			totalOffset += propertySize.height;
			totalOffset += kInterPropertyPadding;
		
		}

	}
	
	
	//
	// draw the note and horizontal rule separating it from the rest
	
	note = [aPerson valueForProperty:kABNoteProperty];
	if ( note != nil ) 
	{
		
		totalOffset += kInterPropertyPadding;
		
		NSRect frame = NSMakeRect(kPadding, totalOffset, bds.size.width - kPadding*2, 20);
		PDPersonPropertyField *propertyField = [[self newPropertyFieldWithFrame:frame property:kABNoteProperty 
				label:ABLocalizedPropertyOrLabel(kABNoteProperty) content:note 
				target:self action:@selector(showFieldMenu:)] autorelease];	
		
		[propertyFields addObject:propertyField];
		[self addSubview:propertyField];
		
		totalOffset += propertySize.height;
	
	}
	else 
	{
		drawsNoteRule = NO;
	}
	
	// extra space
	totalOffset += kPadding;
	
	// resize the view's frame for the scroller - does not mark for redisplay
	[self setFrameSize:NSMakeSize([self frame].size.width, totalOffset)];
	
	[self setNeedsDisplay:YES];
	
}

- (PDPersonPropertyField*) newPropertyFieldWithFrame:(NSRect)frame property:(NSString*)property 
		label:(NSString*)label content:(NSString*)content target:(NSObject*)aTarget action:(SEL)aSelector {
	
	PDPersonPropertyField *propertyField = [[PDPersonPropertyField alloc] initWithFrame:frame];
	
	[propertyField setProperty:property];
	[propertyField setLabel:label];
	[propertyField setContent:content];
	[propertyField setTarget:aTarget];
	[propertyField setAction:aSelector];
	
	return propertyField;
	
}

#pragma mark -

- (void)mouseEntered:(NSEvent *)theEvent 
{
	PDPersonPropertyField *propertyField = (PDPersonPropertyField*)[theEvent userData];
	
	[[propertyField cell] setHighlighted:YES];
	[propertyField setNeedsDisplay:YES];
	
}

- (void)mouseExited:(NSEvent *)theEvent 
{
	PDPersonPropertyField *propertyField = (PDPersonPropertyField*)[theEvent userData];
	
	[[propertyField cell] setHighlighted:NO];
	[propertyField setNeedsDisplay:YES];
	
}

#pragma mark -

- (IBAction) showFieldMenu:(id)sender 
{
	[[self target] performSelector:[self action] withObject:sender];
}

@end
