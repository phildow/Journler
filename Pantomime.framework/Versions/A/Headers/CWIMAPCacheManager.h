/*
**  CWIMAPCacheManager.h
**
**  Copyright (c) 2001-2005
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

#ifndef _Pantomime_H_CWIMAPCacheManager
#define _Pantomime_H_CWIMAPCacheManager

#import <Foundation/NSMapTable.h>

#include <Pantomime/CWCacheManager.h>

@class CWIMAPMessage;

/*!
  @class CWIMAPCacheManager
  @discussion This class provides trivial extensions to the
              CWCacheManager superclass for CWIMAPFolder instances.
*/
@interface CWIMAPCacheManager: CWCacheManager
{
  @private
    NSMapTable *_table;
    unsigned int _UIDValidity;
}

/*!
  @method messageWithUID:
  @discussion This method is used to obtain the CWIMAPMessage instance
              from the receiver's cache.
  @param theUID The UID of the message to obtain from the cache.
  @result The instance, nil if not present in the receiver's cache.
*/
- (CWIMAPMessage *) messageWithUID: (unsigned int) theUID;

/*!
  @method UIDValidity
  @discussion This method is used to obtain the UID validity
              value of the receiver's cache. If it doesn't
	      match the UID validity of its associated
	      CWIMAPFolder instance, you should invalidate the cache.
  @result The UID validity.
*/
- (unsigned int) UIDValidity;

/*!
  @method setUIDValidity:
  @discussion This method is used to set the UID validity value
              of the receiver's cache.
  @param theUIDValidity The value to set.
*/
- (void) setUIDValidity: (unsigned int) theUIDValidity;

@end

#endif // _Pantomime_H_CWIMAPCacheManager
