/*
**  CWLocalFolder+mbox.h
**
**  Copyright (c) 2004-2006
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#ifndef _Pantomime_H_CWLocalFolder_mbox
#define _Pantomime_H_CWLocalFolder_mbox

#include <Pantomime/CWLocalFolder.h>

@interface CWLocalFolder (mbox)

- (void) close_mbox;

- (void) expunge_mbox;

- (FILE *) open_mbox;

- (int) parse_mbox: (NSString *) theFile 
            stream: (FILE *) aStream 
             index: (int) theIndex;

- (NSData *) unfoldLinesStartingWith: (char *) firstLine
                          fileStream: (FILE *) theStream;

+ (unsigned) numberOfMessagesFromData: (NSData *) theData;

- (NSArray *) messagesFromMailSpoolFile;

@end

#endif // _Pantomime_H_CWLocalFolder_mbox
