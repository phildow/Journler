/*
**  CWPOP3CacheManager.h
**
**  Copyright (c) 2001-2004
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

#ifndef _Pantomime_H_CWPOP3CacheManager
#define _Pantomime_H_CWPOP3CacheManager

#include <Pantomime/CWCacheManager.h>

@class CWPOP3CacheObject;

/*!
  @class CWPOP3CacheManager
  @discussion This class provides trivial extensions to the
              CWCacheManager superclass for CWPOP3Folder instances.
	      This cache manager makes use of CWPOP3CacheObject
	      instances instead of CWPOP3Message instance for
	      speed and size requirements restrictions.
*/
@interface CWPOP3CacheManager: CWCacheManager

/*!
  @method cacheObjectWithUID:
  @discussion This method is used to obtain the CWPOP3CacheObject
              instance using the specified UID.
  @param theUID The UID of the instance to obtain.
  @result The instance, nil if not found in the receiver's cache.
*/
- (CWPOP3CacheObject *) cacheObjectWithUID: (NSString *) theUID;

@end

#endif // _Pantomime_H_CWPOP3CacheManager
