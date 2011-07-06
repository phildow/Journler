/*
**  CWLocalMessage.h
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

#ifndef _Pantomime_H_CWLocalMessage
#define _Pantomime_H_CWLocalMessage

#include <Pantomime/CWMessage.h>

#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

/*!
  @class CWLocalMessage
  @discussion This class, which extends CWMessage, adds local specific
              information and redefines the behavior of some methods
	      from its superclass.
*/
@interface CWLocalMessage : CWMessage <NSCoding>
{
  @private
    NSString *_mailFilename; // Name of file in which the message is stored (if using maildir)
    int _type;	             // PantomimeFormatMbox or PantomimeFormatMaildir
    long _filePosition;      
    long _bodyFilePosition;  
}

/*!
  @method filePosition
  @discussion This method is used to obtain the position in the mbox file
              from which the message begins at. This method isn't really
	      helpful if -type returns something other than PantomimeFormatMbox.
  @result The position in the file.
*/
- (long) filePosition;

/*!
  @method setFilePosition:
  @discussion This method is used to set the position in the mbox file
              from which the message begins at. This method isn't really
	      helpful if -type returns something other than PantomimeFormatMbox.
  @param theFilePosition The position in the file.
*/
- (void) setFilePosition: (long) theFilePosition;

/*!
  @method bodyFilePosition
  @discussion This method is used to obtain the position of the beginning of
              the message body in the file where is stored the message.
  @result The position in the file.
*/
- (long) bodyFilePosition;

/*!
  @method setBodyFilePosition:
  @discussion This method is used to set the position of the beginning of
              the message body in the file where is stored the message.
  @param The position in the file.
*/
- (void) setBodyFilePosition: (long) theBodyFilePosition;

/*!
  @method type
  @discussion This method is used to obtain the type of receiver.
              Possible values are part of the PantomimeFolderFormat enum.
  @result The type of the message.
*/
- (PantomimeFolderFormat) type;

/*!
  @method setType:
  @discussion This method is used to set the type of receiver.
              Accepted values are part of the PantomimeFolderFormat enum.
  @param theType The type of the receiver.
*/
- (void) setType: (PantomimeFolderFormat) theType;

/*!
  @method mailFilename
  @discussion This method is used to obtain the associated filename
              of the receiver, if -type is PantomimeFormatMaildir.
  @result The filename, nil if none was defined or if -type returns
          something other than PantomimeFormatMaildir.
*/
- (NSString *) mailFilename;

/*!
  @method setMailFilename:
  @discussion This method is used to set the associated filename
              for the receiver. This is useful and required if
	      -type returns PantomimeFormatMaildir.
  @param theFilename The name of the file.
*/
- (void) setMailFilename: (NSString *) theFilename;

@end

#endif // _Pantomime_H_CWLocalMessage
