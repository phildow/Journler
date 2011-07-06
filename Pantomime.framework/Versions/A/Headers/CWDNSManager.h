/*
**  CWDNSManager.h
**
**  Copyright (c) 2004
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

#ifndef _Pantomime_H_CWDNSManager
#define _Pantomime_H_CWDNSManager

#include <Pantomime/CWConnection.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>

/*!
  @class CWDNSManager
  @discussion This class is used in Pantomime to perform DNS resolution.
              Currently, it does not do asynchronous lookups but implements
	      a simple cache to speedup repetitive requets.
*/
@interface CWDNSManager : NSObject
{
  @private
    NSMutableDictionary *_cache;
}

/*!
  @method addressesForName:
  @discussion This method is used to get obtain an array of IP
              addresses from a fully qualified domain name.
  @param theName The fully qualified domain name.
  @result The array of addresses encoded as NSData instances.
*/
- (NSArray *) addressesForName: (NSString *) theName;

/*!
  @method singleInstance
  @discussion This method is used to obtain the shared
              CWDNSManager instance for DNS resolution.
  @result The shared instance.
*/
+ (id) singleInstance;

@end

#endif // _Pantomime_H_CWDNSManager
