//
//  ResourceInfoView.m
//  Journler
//
//  Created by Philip Dow on 1/20/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "ResourceInfoView.h"

#import "JournlerResource.h"
#import "JournlerEntry.h"
#import "JournlerCollection.h"

#import <SproutedUtilities/SproutedUtilities.h>

@implementation ResourceInfoView

static NSString* NoNullString( NSString *aString ) 
{
	return ( aString == nil ? [NSString string] : aString );
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		cell = [[NSImageCell alloc] initImageCell:nil];
		[cell setImageFrameStyle:NSImageFrameNone];
		
		viewAlignment = ResourceInfoAlignLeft;
		
		// flip the gradient 'cause we're a flipped view
		//NSColor *theGradientStart = [self gradientStartColor];
		//NSColor *theGradientEnd = [self gradientEndColor];
		
		//[self setGradientEndColor:theGradientStart];
		//[self setGradientStartColor:theGradientEnd];
    }
    return self;
}

- (void) dealloc
{
	[cell release];
	[resource release];
	
	[super dealloc];
}

#pragma mark -

- (ResourceInfoAlignment) viewAlignment
{
	return viewAlignment;
}

- (void) setViewAlignment:(ResourceInfoAlignment)alignment
{
	viewAlignment = alignment;
}

- (JournlerResource*) resource
{
	return resource;
}

- (void) setResource:(JournlerResource*)aResource
{
	if ( resource != aResource )
	{
		[resource release];
		resource = [aResource retain];
	}
}

#pragma mark -

- (BOOL) isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	
	[super drawRect:rect];
	
	if ( [self resource] == nil )
		return;
	
	NSRect bds = [self bounds];
	NSSize cellSize = NSMakeSize(128,128);
	
	//[JournlerGradientView drawGradientInView:self rect:bds highlight:NO shadow:0];
	
	NSRect iconBoundary;
	if ( [self viewAlignment] == ResourceInfoAlignLeft )
		iconBoundary = NSMakeRect( 5, 5, cellSize.width+10, cellSize.height+10 );
	else if ( [self viewAlignment] == ResourceInfoAlignRight )
		iconBoundary = NSMakeRect( bds.size.width - cellSize.width - 15, 5, cellSize.width+10, cellSize.height+10 );
	
	NSRect iconRect;
	if ( [self viewAlignment] == ResourceInfoAlignLeft )
		iconRect = NSMakeRect( 10, 10, cellSize.width, cellSize.height );
	else if ( [self viewAlignment] == ResourceInfoAlignRight )
		iconRect = NSMakeRect( bds.size.width - cellSize.width - 10, 10, cellSize.width, cellSize.height );
	
	[cell setObjectValue:[resource valueForKey:@"icon"]];
	
	// draw a border around the icon
	//[NSColor colorWithDeviceWhite:0.13 alpha:1.0];
	//[[NSBezierPath bezierPathWithRoundedRect:iconBoundary cornerRadius:5.0] fill];
	
	// actually draw the icon cell
	[cell drawWithFrame:iconRect inView:self];
	
	// draw the information for the resource
	if ( [[self resource] representsFile] )
		[self _drawInfoForFile];
	else if ( [[self resource] representsABRecord] )
		[self _drawInfoForABRecord];
	else if ( [[self resource] representsURL] )
		[self _drawInfoForURL];
	else if ( [[self resource] representsJournlerObject] )
		[self _drawInfoForJournlerObject];
}

#pragma mark -

- (void) _drawInfoForFile
{
	unsigned long long kBytesInKilobyte = 1024;
	unsigned long long kBytesInMegabyte = 1048576;
	unsigned long long kBytesInGigabyte = 1073741824;
	
	NSString *path = [[self resource] originalPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	FSRef fsRef;
	FSCatalogInfo catInfo;
	// #warning returns 0 when the file is a package/directory
	
	if ( ![fm fileExistsAtPath:path] )
	{
		return;
	}
	
	NSSize cellSize = NSMakeSize(128,128);
	NSSize stringSize;
	NSRect stringRect;
	NSInteger  originaXOffset= ( viewAlignment == PDFileInfoAlignLeft ? 5*2 + cellSize.width + 10 : 5*2 );
	
	//NSUInteger xOffset = originaXOffset, yOffset = 20;
	//NSUInteger xOffset = 0, yOffset = [self bounds].size.height - 20;
	
	NSBundle *sproutedInterfaceBundle = [NSBundle bundleWithIdentifier:@"com.sprouted.interface"];
	
	NSMutableParagraphStyle *titleParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[titleParagraph setLineBreakMode:NSLineBreakByTruncatingMiddle];
	
	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	
	[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:0.96]];
	[textShadow setShadowOffset:NSMakeSize(0,-1)];
	
	NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		titleParagraph, NSParagraphStyleAttributeName, nil];
	
	NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:11], NSFontAttributeName,
		[NSColor colorWithCalibratedWhite:0.4 alpha:1.0], NSForegroundColorAttributeName, 
		textShadow, NSShadowAttributeName, nil];
	
	NSDictionary *propertyAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName, 
		titleParagraph, NSParagraphStyleAttributeName, 
		textShadow, NSShadowAttributeName, nil];
	
	MDItemRef mdItem = MDItemCreate(NULL,(CFStringRef)path);
	
	// derive an icon for the file based on the unique file system file number
	NSDictionary *fileAttributes = [fm fileAttributesAtPath:path traverseLink:NO];
	NSSize lwTitle, lwKind, lwSize, lwCreated, lwModified, lwLastOpened, lwMax;
	
	lwTitle = NSMakeSize(0, 0);
	lwKind = NSMakeSize(0, 0);
	lwSize = NSMakeSize(0, 0);
	lwCreated = NSMakeSize(0, 0);
	lwModified = NSMakeSize(0, 0);
	lwLastOpened = NSMakeSize(0, 0);
	lwMax = NSMakeSize(0, 0);
		
	//NSUInteger xOffset = 0, yOffset = infoRect.size.height - 20;
	NSInteger  xOffset = originaXOffset, yOffset = 35; // 30 for the image cell, 50 is a bit arbitrary
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	// first calculate all the label widths
	
	// labels
	NSString *titleLabel = NSLocalizedStringFromTableInBundle(@"mditem title name", @"FileInfo", sproutedInterfaceBundle, @"");
	NSString *typeLabel = NSLocalizedStringFromTableInBundle(@"mditem kind name", @"FileInfo", sproutedInterfaceBundle, @"");
	NSString *sizeLabel = NSLocalizedStringFromTableInBundle(@"mditem size name", @"FileInfo", sproutedInterfaceBundle, @"");
	NSString *dateLabel = NSLocalizedStringFromTableInBundle(@"mditem created name", @"FileInfo", sproutedInterfaceBundle, @"");
	NSString *dateModifiedLabel = NSLocalizedStringFromTableInBundle(@"mditem modified name", @"FileInfo", sproutedInterfaceBundle, @"");
	NSString *lastOpenedLabel = NSLocalizedStringFromTableInBundle(@"mditem lastopened name", @"FileInfo", sproutedInterfaceBundle, @"");
	
	// values
	NSString *displayName = /*[fm displayNameAtPath:path];*/ [[path lastPathComponent] stringByDeletingPathExtension];
	
	NSDate *dateCreated = [fileAttributes valueForKey:NSFileCreationDate];
	NSString *dateCreatedAsString = nil;
	if ( dateCreated != nil ) dateCreatedAsString = NoNullString([dateFormatter stringFromDate:dateCreated]);
	
	NSDate *dateModified = [fileAttributes valueForKey:NSFileModificationDate];
	NSString *dateModifiedAsString = nil;
	if ( dateModified != nil )dateModifiedAsString = NoNullString([dateFormatter stringFromDate:dateModified]);
	
	NSString *typeDescription = nil;
	NSString *lastOpenedAsString = nil;
	
	if ( mdItem != NULL ) 
	{
		typeDescription = [(NSString*)MDItemCopyAttribute(mdItem,(CFStringRef)kMDItemKind) autorelease];
		
		NSDate *lastOpened = (NSDate*)[(NSString*)MDItemCopyAttribute(mdItem,(CFStringRef)kMDItemLastUsedDate) autorelease];
		if ( lastOpened != nil ) lastOpenedAsString = NoNullString([dateFormatter stringFromDate:lastOpened]);
		
		CFRelease(mdItem);
		mdItem = NULL;
	}
	
	// actually calculate the sizes
	
	if ( titleLabel != nil ) lwTitle = [titleLabel sizeWithAttributes:labelAttrs];
	if ( lwTitle.width > lwMax.width ) lwMax.width = lwTitle.width;

	if ( typeLabel != nil ) lwKind = [typeLabel sizeWithAttributes:labelAttrs];
	if ( lwKind.width > lwMax.width ) lwMax.width = lwKind.width;
	
	if ( sizeLabel != nil ) lwSize = [sizeLabel sizeWithAttributes:labelAttrs];
	if ( lwSize.width > lwMax.width ) lwMax.width = lwSize.width;

	if ( dateLabel != nil ) lwCreated = [dateLabel sizeWithAttributes:labelAttrs];
	if ( lwCreated.width > lwMax.width ) lwMax.width = lwCreated.width;
	
	if ( dateModifiedLabel != nil ) lwModified = [dateModifiedLabel sizeWithAttributes:labelAttrs];
	if ( lwModified.width > lwMax.width ) lwMax.width = lwModified.width;
	
	if ( lastOpenedLabel != nil ) lwLastOpened = [lastOpenedLabel sizeWithAttributes:labelAttrs];
	if ( lwLastOpened.width > lwMax.width ) lwMax.width = lwLastOpened.width;
	
	// max widths
	NSInteger  maxWidth = [self bounds].size.width - ( xOffset + lwMax.width + 8 + 20 );
	float greatestWidth = 0;
	
	// do the drawing
	
	// display name
	if ( displayName != nil )
	{
		// label
		stringRect = NSMakeRect( xOffset + ( lwMax.width - lwTitle.width), yOffset, lwTitle.width, lwTitle.height );
		[titleLabel drawInRect:stringRect withAttributes:labelAttrs];
		
		if ( xOffset + lwTitle.width > greatestWidth )
			greatestWidth = xOffset + lwTitle.width;
		
		xOffset += lwMax.width;
		xOffset += 8;
		
		// value
		stringSize = [displayName sizeWithAttributes:titleAttrs];
		stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
		[displayName drawInRect:stringRect withAttributes:titleAttrs];
		
		if ( xOffset + stringSize.width > greatestWidth )
			greatestWidth = xOffset + stringSize.width;
	
		yOffset += stringSize.height;
		xOffset = originaXOffset;
	}
	
	// file type
	if ( typeLabel != nil && typeDescription != nil )
	{
		// label
		stringRect = NSMakeRect( xOffset + ( lwMax.width - lwKind.width), yOffset, lwKind.width, lwKind.height );
		[typeLabel drawInRect:stringRect withAttributes:labelAttrs];
		
		if ( xOffset + lwKind.width > greatestWidth )
			greatestWidth = xOffset + lwKind.width;
		
		xOffset += lwMax.width;
		xOffset += 8;
		
		// value
		stringSize = [typeDescription sizeWithAttributes:propertyAttrs];
		stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
		[typeDescription drawInRect:stringRect withAttributes:propertyAttrs];
		
		if ( xOffset + stringSize.width > greatestWidth )
			greatestWidth = xOffset + stringSize.width;

		yOffset += stringSize.height;
		xOffset = originaXOffset;
	} // file type

	// file size	
	if ( FSPathMakeRef((const UInt8 *)[path UTF8String] ,&fsRef,NULL) == noErr && 
				FSGetCatalogInfo(&fsRef,kFSCatInfoGettableInfo,&catInfo,NULL,NULL,NULL) == noErr ) 
	{
		// is it necessary to add the resource size?
		UInt64 file_size = catInfo.dataPhysicalSize + catInfo.rsrcPhysicalSize;
		NSString *fileSizeAsString;
		
		if ( file_size != 0 )
		{
			if ( file_size / kBytesInGigabyte > 1 ) 
			{
				NSNumber *gigabytes = [NSNumber numberWithInteger:(file_size / kBytesInGigabyte)];
				fileSizeAsString = NoNullString( [[gigabytes stringValue] stringByAppendingString:
				NSLocalizedStringFromTableInBundle(@"mditem size gb", @"FileInfo", sproutedInterfaceBundle, @"")] );
			}
			else 
			{
				if ( file_size / kBytesInMegabyte > 1 ) 
				{
					NSNumber *megabytes = [NSNumber numberWithInteger:(file_size / kBytesInMegabyte)];
					fileSizeAsString = NoNullString( [[megabytes stringValue] stringByAppendingString:
					NSLocalizedStringFromTableInBundle(@"mditem size mb", @"FileInfo", sproutedInterfaceBundle, @"")] );
				}
				else 
				{
					NSNumber *kilobytes = [NSNumber numberWithInteger:(file_size / kBytesInKilobyte)];
					fileSizeAsString = NoNullString( [[kilobytes stringValue] stringByAppendingString:
					NSLocalizedStringFromTableInBundle(@"mditem size kb", @"FileInfo", sproutedInterfaceBundle, @"")] );
				}
			}
			


			if ( sizeLabel != nil && fileSizeAsString != nil )
			{
				// label
				stringRect = NSMakeRect( xOffset + ( lwMax.width - lwSize.width), yOffset, lwSize.width, lwSize.height );
				[sizeLabel drawInRect:stringRect withAttributes:labelAttrs];
				
				if ( xOffset + lwSize.width > greatestWidth )
					greatestWidth = xOffset + lwSize.width;
				
				xOffset += lwMax.width;
				xOffset += 8;					
				
				// value
				stringSize = [fileSizeAsString sizeWithAttributes:propertyAttrs];
				stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
				[fileSizeAsString drawInRect:stringRect withAttributes:propertyAttrs];
				
				if ( xOffset + stringSize.width > greatestWidth )
					greatestWidth = xOffset + stringSize.width;
				
				yOffset += stringSize.height;
				xOffset = originaXOffset;
			}
		}
	} // file size

	
	// date created
	if ( dateLabel != nil && dateCreatedAsString != nil )
	{
		// label
		stringRect = NSMakeRect( xOffset + ( lwMax.width - lwCreated.width), yOffset, lwCreated.width, lwCreated.height );
		[dateLabel drawInRect:stringRect withAttributes:labelAttrs];
		
		if ( xOffset + lwCreated.width > greatestWidth )
			greatestWidth = xOffset + lwCreated.width;
		
		xOffset += lwMax.width;
		xOffset += 8;
		
		// value
		stringSize = [dateCreatedAsString sizeWithAttributes:propertyAttrs];
		stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
		[dateCreatedAsString drawInRect:stringRect withAttributes:propertyAttrs];
		
		if ( xOffset + stringSize.width > greatestWidth )
			greatestWidth = xOffset + stringSize.width;
		
		yOffset += stringSize.height;
		xOffset = originaXOffset;
	} // date created

	
	// date modified
	if ( dateModifiedLabel != nil && dateModifiedAsString != nil )
	{
		// label
		stringRect = NSMakeRect( xOffset + ( lwMax.width - lwModified.width), yOffset, lwModified.width, lwModified.height );
		[dateModifiedLabel drawInRect:stringRect withAttributes:labelAttrs];
		
		if ( xOffset + lwModified.width > greatestWidth )
			greatestWidth = xOffset + lwModified.width;
		
		xOffset += lwMax.width;
		xOffset += 8;
					
		// value
		stringSize = [dateModifiedAsString sizeWithAttributes:propertyAttrs];
		stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
		[dateModifiedAsString drawInRect:stringRect withAttributes:propertyAttrs];
		
		if ( xOffset + stringSize.width > greatestWidth )
			greatestWidth = xOffset + stringSize.width;
		
		yOffset += stringSize.height;
		xOffset = originaXOffset;
	} // date modified

	
	// last opened
	if ( lastOpenedLabel != nil && lastOpenedAsString != nil )
	{
		// label
		stringRect = NSMakeRect( xOffset + ( lwMax.width - lwLastOpened.width), yOffset, lwLastOpened.width, lwLastOpened.height );
		[lastOpenedLabel drawInRect:stringRect withAttributes:labelAttrs];
		
		if ( xOffset + lwLastOpened.width > greatestWidth )
			greatestWidth = xOffset + lwLastOpened.width;
		
		xOffset += lwMax.width;
		xOffset += 8;
		
		// value
		stringSize = [lastOpenedAsString sizeWithAttributes:propertyAttrs];
		stringRect = NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height );
		[lastOpenedAsString drawInRect:stringRect withAttributes:propertyAttrs];
		
		if ( xOffset + stringSize.width > greatestWidth )
			greatestWidth = xOffset + stringSize.width;
		
		yOffset += stringSize.height;
		xOffset = originaXOffset;
	} // last opened	
}

- (void) _drawInfoForABRecord
{
	// draw the name and the note
	ABPerson *person = [[self resource] person];
	if ( person == nil )
		return;
	
	NSMutableParagraphStyle *titleParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[titleParagraph setLineBreakMode:NSLineBreakByTruncatingTail];
	
	NSMutableParagraphStyle *noteParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[noteParagraph setLineBreakMode:NSLineBreakByWordWrapping];
	
	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	
	[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:0.96]];
	[textShadow setShadowOffset:NSMakeSize(0,-1)];
	
	NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:11], NSFontAttributeName,
		/*[NSColor whiteColor], NSForegroundColorAttributeName, */
		[NSColor blackColor], NSForegroundColorAttributeName, 
		textShadow, NSShadowAttributeName, 
		titleParagraph, NSParagraphStyleAttributeName, nil];
	
	NSDictionary *additionalAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		/*[NSColor whiteColor], NSForegroundColorAttributeName, */
		[NSColor blackColor], NSForegroundColorAttributeName, 
		textShadow, NSShadowAttributeName,
		titleParagraph, NSParagraphStyleAttributeName, nil];
	
	NSDictionary *noteAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		/*[NSColor whiteColor], NSForegroundColorAttributeName, */
		[NSColor blackColor], NSForegroundColorAttributeName, 
		textShadow, NSShadowAttributeName,
		noteParagraph, NSParagraphStyleAttributeName, nil];
		
	NSSize cellSize = NSMakeSize(128,128);
	NSSize stringSize;
	
	NSInteger  originaXOffset= ( [self viewAlignment] == ResourceInfoAlignLeft ? 5*2 + cellSize.width + 10 : 5*2 );
	
	NSInteger xOffset = originaXOffset, yOffset = 20;
	NSInteger  maxWidth = [self bounds].size.width - ( 5*2 + cellSize.width + 10*2 );
	
	NSString *entryName = [person fullname];
	if ( entryName != nil )
	{
		stringSize = [entryName sizeWithAttributes:titleAttrs];
		[entryName drawInRect:NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height ) withAttributes:titleAttrs];
		
		yOffset += stringSize.height;
	}
	
	NSString *additionalInfo = [person emailAddress];
	if ( additionalInfo == nil )
		additionalInfo = [person website];
	if ( additionalInfo != nil )
	{
		stringSize = [additionalInfo sizeWithAttributes:additionalAttrs];
		[additionalInfo drawInRect:NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height ) withAttributes:additionalAttrs];
		
		yOffset += stringSize.height;
	}
	
	// make a little extra space
	yOffset += 14;
	
	NSString *note = [person valueForProperty:kABNoteProperty];
	if ( note != nil )
	{
		NSRect noteRect = NSMakeRect( xOffset, yOffset, maxWidth, [self bounds].size.height - yOffset - 20 );
		[note drawInRect:noteRect withAttributes:noteAttrs];
	}
}

- (void) _drawInfoForURL
{
	// draw the url location
	NSMutableParagraphStyle *wrappingParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[wrappingParagraph setLineBreakMode:NSLineBreakByWordWrapping];
	
	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	
	[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:0.96]];
	[textShadow setShadowOffset:NSMakeSize(0,-1)];
	
	NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:11], NSFontAttributeName,
		/*[NSColor whiteColor], NSForegroundColorAttributeName, */
		[NSColor blackColor], NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName, 
		wrappingParagraph, NSParagraphStyleAttributeName, nil];
	
	NSDictionary *urlAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		/*[NSColor whiteColor], NSForegroundColorAttributeName, */
		[NSColor blackColor], NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName, 
		wrappingParagraph, NSParagraphStyleAttributeName, nil];
	
	NSSize cellSize = NSMakeSize(128,128);
	NSSize stringSize;
	
	NSInteger originaXOffset= ( [self viewAlignment] == ResourceInfoAlignLeft ? 5*2 + cellSize.width + 10 : 5*2 );
	
	NSInteger xOffset = originaXOffset, yOffset = 20;
	NSInteger maxWidth = [self bounds].size.width - ( 5*2 + cellSize.width + 10*2 );
	
	NSString *title = [[self resource] valueForKey:@"title"];
	if ( title != nil )
	{
		stringSize = [title sizeWithAttributes:titleAttrs];
		[title drawInRect:NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height ) withAttributes:titleAttrs];
		
		yOffset += stringSize.height;
		yOffset += 14;
	}
	
	NSString *location = [[self resource] urlString];
	if ( ![location isEqualToString:title] )
	{
		stringSize = [location sizeWithAttributes:urlAttrs];
		[location drawInRect:NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height ) withAttributes:urlAttrs];
		
		yOffset += stringSize.height;
	}
}

- (void) _drawInfoForJournlerObject
{
	// draw the title and number of entries or summary
	
	NSMutableParagraphStyle *truncateTailParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[truncateTailParagraph setLineBreakMode:NSLineBreakByTruncatingTail];
	
	NSMutableParagraphStyle *wordWrapParagraph = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
	[wordWrapParagraph setLineBreakMode:NSLineBreakByWordWrapping];
	
	NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:11], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		truncateTailParagraph, NSParagraphStyleAttributeName, nil];
	
	NSDictionary *infoAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:11], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName, 
		wordWrapParagraph, NSParagraphStyleAttributeName, nil];
	
	NSSize cellSize = NSMakeSize(128,128);
	NSSize stringSize;
	
	CGFloat originaXOffset= ( [self viewAlignment] == ResourceInfoAlignLeft ? 5*2 + cellSize.width + 10 : 5*2 );
	
	CGFloat xOffset = originaXOffset, yOffset = 20;
	CGFloat maxWidth = [self bounds].size.width - ( 5*2 + cellSize.width + 10*2 );
	
	NSString *title = [[self resource] valueForKey:@"title"];
	if ( title != nil )
	{
		stringSize = [title sizeWithAttributes:titleAttrs];
		[title drawInRect:NSMakeRect( xOffset, yOffset, ( stringSize.width < maxWidth ? stringSize.width : maxWidth ), stringSize.height ) withAttributes:titleAttrs];
		
		yOffset += stringSize.height;
		yOffset += 14;
	}
	
	id journlerObject = [[self resource] journlerObject];
	
	if ( [journlerObject isKindOfClass:[JournlerEntry class]] )
	{
		// 1. draw the summary for the entry
		NSString *plainContent = [journlerObject valueForKey:@"content"];
		if ( plainContent != nil )
		{
			SKSummaryRef summaryRef = SKSummaryCreateWithString((CFStringRef)plainContent);
			if ( summaryRef != NULL )
			{
				NSString *summary = [(NSString*)SKSummaryCopySentenceSummaryString(summaryRef,1) autorelease];
				if ( summary == nil )
					summary = [journlerObject valueForKey:@"title"];
					
				NSRect summaryRect = NSMakeRect( xOffset, yOffset, maxWidth, [self bounds].size.height - yOffset - 20 );
				[summary drawInRect:summaryRect withAttributes:infoAttrs];
			}
		}
	}
	else if ( [journlerObject isKindOfClass:[JournlerCollection class]] )
	{
		
		// 2. draw the hierarchy
		JournlerCollection *parent = [(JournlerCollection*)journlerObject valueForKey:@"parent"];
		JournlerCollection *rootCollection = [journlerObject valueForKeyPath:@"journal.rootCollection"];
		
		if ( parent != nil && parent != rootCollection )
		{
			NSMutableString *hierarchyString = [NSMutableString string];
			[hierarchyString appendString:[journlerObject valueForKey:@"title"]];
			
			while ( parent != nil && parent != rootCollection )
			{
				[hierarchyString insertString:@" > " atIndex:0];
				[hierarchyString insertString:[parent valueForKey:@"title"] atIndex:0];
				
				parent = [parent valueForKey:@"parent"];
			}
			
			//NSLog(hierarchyString);
			
			NSSize hierarchSize = [hierarchyString sizeWithAttributes:infoAttrs];
			NSRect hierarchyRect = NSMakeRect( xOffset, yOffset, ( hierarchSize.width < maxWidth ? hierarchSize.width : maxWidth ), hierarchSize.height );
			
			[hierarchyString drawInRect:hierarchyRect withAttributes:infoAttrs];
			yOffset += hierarchSize.height;
			//yOffset += 14;
		}
		
		// 1. draw the count info -> # entries # resources
		NSString *countInfo = [NSString stringWithFormat:
			NSLocalizedString(@"num entries num resources", @""), 
			[[journlerObject valueForKey:@"entries"] count],
			[[[journlerObject valueForKey:@"entries"] valueForKeyPath:@"@distinctUnionOfArrays.resources"] count]];
		
		NSSize countSize = [countInfo sizeWithAttributes:infoAttrs];
		NSRect countRect = NSMakeRect( xOffset, yOffset, ( countSize.width < maxWidth ? countSize.width : maxWidth ), countSize.height );
		
		[countInfo drawInRect:countRect withAttributes:infoAttrs];
		yOffset += countSize.height;
		//yOffset += 14;
	}
}

@end
