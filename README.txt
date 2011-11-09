//
//  Journler
//  Created by Philip Dow
//  Copyright Philip Dow / Sprouted. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*

Journler uses the following open source software, many of whose source
files are contained within the Journler code base. The Journler open source 
license does not supersede any licenses imposed by the included 3rd party code.
If you find unaccredited code or improperly used licenses, please let me know.

	- RBSplitView by Rainer Brockerhoff
	- LJKit by Benjamin Peter Ragheb
	- ID3 Framework by Chris Drew
	- XMLRPCCocoa by Brent Simmons
	- CURLHandle+extras by Dan Wood
	- The LAME encoder by the lame group at mp3dev.org
	- The LAME Framework and Quicktime Component by Lynn Pye
	- NDAlias by Nathan Day
	- KFAppleScript Additions by Ken Ferry
	- iMediaBrowser by Greg Hulands and the crew / Karelia
	- L0iPod by Emanuele Vulcano
	- CocoaSequenceGrabber by Tim Omernick
	- Sparkle framework by Andy Matuschak
	- Cool windows and other visual candy by Matt Gemmell
	- More cool windows and candy by Chad Weider
	- MUPhotoView by Blake Seely
	- The Pantomime framework by Ludovic Marcotte
	- UKKQueue by M. Uli Kusterer
	- GTResourceFork by Jonathan Grynspan
	- KBWordCountingTextStorage by Keith Blount

*/

//
//	SPROUTED DEPENDENCIES
//
//	1. SproutedUtilities
//	2. SproutedInterface
//	3. SproutedAVI
//
//	Journler relies on a three additional frameworks from Sprouted. SproutedAVI handled\s
//	audio-visual input and is already available at github. The Utilities and
//	Interface frameworks are forthcoming.
//
//	Initially I thought it wise to collect generic code used in Journler into these two
//	separate frameworks to improve their re-usability. I no longer believe this was 
//	necessary, and a portion of the open sourcing effort includes the decomposition of these
//	frameworks into their constituent parts and the re-incorporation of that code back
//	into the main Journler project.
//
//	The issue is not so much that the code is kept separate. In fact I will likely continue
//	to maintain separate repositories for re-usable code. The issue is that I combined this
//	code into a framework, whereas I should have just grabbed the source files from the
//	repository as I required them.
//


//
//	ABOUT JOURNLER OPEN SOURCE
//
//	This is the complete Xcode project for the Journler application, including source code,
//	interface files and application resources, and it is the same code I am currently developing
//	for the 2.6 Mac OS compatibility update . Compiling this project will produce an application
//	identical to the current version of the publicly available 2.6b update. As I make improvements
//	to the code I will push them to github so that this repository should reflect changes to the 
//	latest binaries.
//	
//	The 2.6 compatibility update is a significant undertaking. In addition to the Journler code
//	itself, I am also updating local frameworks on which the application is dependent as well as
//	incorporating newer versions of other 3rd party code and frameworks. The update mostly consists
//	of refactoring existing code and replacing deprecated API calls. To get an idea of just how much
//	work is involved, simply compile the application and have a look at the warnings.
//
//	Moreover, the code is a mess, and much of it is four, five and even six years old, written
//	before I had developed solid object-oriented coding practices. Object coupling is a problem,
//	although the application does have clearly defined data and interface layers, and an overall
//	hierarchy should become evident upon investigation of the code. I may try to produce a diagram
//	detailing the relationships and spheres of influence for future development.
//
//	A word about the data layer: it was written in the days before Core Data. If all you've ever
//	known is Core Data, welcome to the painful world of writing a quasi-relational database layer
//	from scratch in a time before you even realized that's what you were doing.
//
//	Journler is not being open source for any specific reason. Although there is a hope that other
//	developers may pick up the code and customize it for their own use or improve it for general
//	use, I believe the significance of the application lies not so much in the implementation but
//	in the idea. The code is mostly obsolete, and a much more efficient project could be begun
// 	from scratch to realize the Journler vision.
//
//	The 2.6 update, however, is being completed specifically to ensure compatibility with new and
//	future versions of the Mac OS. I'm continually astonished by just how many people used and 
//	continue to use Journler. Updating the code so that they may keep using it, even if no new
//	features are added, is the right thing to do.
//