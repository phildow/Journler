/*
**  CWFolderInformation.h
**
**  Copyright (c) 2002-2004
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

#ifndef _Pantomime_H_CWFolderInformation
#define _Pantomime_H_CWFolderInformation

#import <Foundation/NSObject.h>

/*!
  @class CWFolderInformation
  @discussion This class provides a container to cache folder information like
              the number of messages and unread messages the folder holds, and
	      its total size. Normally you won't use this class directly but
	      CWFolder's subclasses return instances of this class, when
	      calling -folderStatus on a CWFolder instance.
*/      
@interface CWFolderInformation : NSObject
{
  @private
    unsigned int _nb_of_messages;
    unsigned int _nb_of_unread_messages;
    unsigned int _size;
}

/*!
  @method nbOfMessages
  @discussion This method is used to get the total number of messages value
              from this container object.
  @result The total number of messages.
*/
- (unsigned int) nbOfMessages;

/*!
  @method setNbOfMessages:
  @discussion This method is used to set the total number of messages
              of this container object.
  @param theValue The number of messages.
*/
- (void) setNbOfMessages: (unsigned int) theValue;

/*!
  @method nbOfUnreadMessages
  @discussion This method is used to get the total number of unread messages value
              from this container object.
  @result The total number of unread messages.
*/
- (unsigned int) nbOfUnreadMessages;

/*!
  @method setNbOfUnreadMessages:
  @discussion This method is used to set the total number of unread messages
              of this container object.
  @param theValue The number of unread messages.
*/
- (void) setNbOfUnreadMessages: (unsigned int) theValue;

/*!
  @method size
  @discussion This method is used to get the total size of this container object.
  @result The total size.
*/
- (unsigned int) size;

/*!
  @method setSize:
  @discussion This method is used to set the total size of this container object.
  @param theSize The total size.
*/
- (void) setSize: (unsigned int) theSize;

@end

#endif // _Pantomime_H_CWFolderInformation
