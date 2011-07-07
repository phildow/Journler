-- showentry.applescript
-- Journler

--  Created by Philip Dow on 3/10/06.
--  Copyright 2006 Sprouted, Philip Dow. All rights reserved.

tell application "Journler"
	set anEntry to entry id %i
	set the selected entry to anEntry
	activate
end tell