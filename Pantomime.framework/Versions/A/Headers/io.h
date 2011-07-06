/*
**  io.h
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

#ifndef _Pantomime_H_io
#define _Pantomime_H_io

#include <sys/types.h>

/*!
  @function read_block
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method blocks until it read all bytes or if
	      an error different from EINTR occurs.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t read_block(int fd, void *buf, size_t count);

/*!
  @function safe_close
  @discussion This function is used to safely close a file descriptor.
              This function will block until the file descriptor
	      is close, or if the error is different from EINTR.
  @param fd The file descriptor to close.
  @result Returns 0 on success, -1 if an error occurs.
*/
int safe_close(int fd);

/*!
  @function safe_read
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t safe_read(int fd, void *buf, size_t count);

/*!
  @function safe_recv
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read. Options can be
	      passed through <i>flags</i>.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @param flags The flags to use.
  @result The number of bytes that have been read.
*/
ssize_t safe_recv(int fd, void *buf, size_t count, int flags);

#endif //  _Pantomime_H_io
