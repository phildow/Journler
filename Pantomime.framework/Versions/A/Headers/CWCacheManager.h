/*
**  CWCacheManager.h
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

#ifndef _Pantomime_H_CWCacheManager
#define _Pantomime_H_CWCacheManager

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

/*!
  @class CWCacheManager
  @discussion This class is used to provide a generic superclass for
              cache management with regard to various CWFolder sub-classes.
	      CWIMAPFolder, CWLocalFolder and CWPOP3Folder can make use of a
	      cache in order to speedup lots of operations.
*/
@interface CWCacheManager : NSObject <NSCoding>
{
  @protected
    NSMutableArray *_cache;
    NSString *_path;
}

/*!
  @method initWithPath:
  @discussion This method is the designated initializer for the
              CWCacheManager class.
  @param thePath The complete path where the cache will be eventually
                 saved to.
  @result A CWCacheManager subclass instance, nil on error.
*/
- (id) initWithPath: (NSString *) thePath;

/*!
  @method path
  @discussion This method is used to obtain the path where the
              cache has been loaded for or where it'll be saved to.
  @result The path.
*/
- (NSString *) path;

/*!
  @method setPath:
  @discussion This method is used to set the path where the
              cache will be loaded from or where it'll be saved to.
  @param thePath The complete path.
*/
- (void) setPath: (NSString *) thePath;

/*!
  @method invalidate
  @discussion This method is used to invalide all cache entries.
*/
- (void) invalidate;

/*!
  @method synchronize
  @discussion This method is used to save the cache on disk.
              If the cache is empty, this method does not
	      write it on disk and returns YES.
  @result YES on success, NO otherwise.
*/
- (BOOL) synchronize;

/*!
  @method cache
  @discussion This method is used to obtain the NSMutableArray
              instance holding all cache entries. You might want
	      to manipulate objects directly in the cache, at
	      your own risk.
  @result The instance holding all cache entries.
*/
- (NSMutableArray *) cache;

/*!
  @method setCache:
  @discussion This method is used to add the objects contained
              in <i>theCache</i> to the receiver's cache. This method
	      will remove all existing entries before doing so.
  @param theCache The array holding all entries to add to the cache.
*/
- (void) setCache: (NSArray *) theCache;

/*!
  @method addObject:
  @discussion This method is used to add an entry to the cache.
  @param theObject The entry to add.
*/
- (void) addObject: (id) theObject;

/*!
  @method removeObject:
  @discussion This method is used to remove an entry from the cache.
  @param theObject The entry to remove.
*/
- (void) removeObject: (id) theObject;

/*!
  @method cacheWithPath:
  @discussion This method is used to unarchive the cache
              at the specifed path. If the cache at <i>thePath</i>
	      does not exist, a new instance will be created
	      holding an empty cache. Same thing will happen if
	      the archived cache is corrupted.
  @param thePath The path of the cache to unarchive.
  @result An autoreleased instance of a CWCacheManager subclass.
*/
+ (id) cacheWithPath: (NSString *) thePath;

@end

#endif // _Pantomime_H_CWCacheManager
