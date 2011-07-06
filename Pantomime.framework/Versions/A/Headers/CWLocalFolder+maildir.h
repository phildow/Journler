/*
**  CWLocalFolder+maildir.h
**
**  Copyright (c) 2004-2006
**
**  Author: Ujwal S. Sathyam <ujwal@setlurgroup.com>
**          Ludovic Marcotte <ludovic@Sophos.ca>
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

#ifndef _Pantomime_H_CWLocalFolder_maildir
#define _Pantomime_H_CWLocalFolder_maildir

#include <Pantomime/CWLocalFolder.h>

@interface CWLocalFolder (maildir)

- (void) expunge_maildir;

- (BOOL) parse_maildir: (NSString *) theDirectory;

@end

#endif // _Pantomime_H_CWLocalFolder_maildir
