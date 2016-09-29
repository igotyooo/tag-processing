require 'utils'

function printl( str )
	print( 'RAW_DATA) ' .. str )
end
local function tagFilter( tag )
	local tags = {  }
	local cnt = 0
	while true do
		local word = tag:match( '%a+' )
		if word == nil then break end
		local _, n = tag:find( word, 1 )
		tag = tag:sub( n + 1 )
		cnt = cnt + 1
		tags[ cnt ] = word
	end
	return tags
end
function readRawTags( 
	srcCatPath,
	srcTagPath,
	srcNumFramePath,
	minNumVideoPerTag, 
	minNumCharPerTag )
	local vid = 0
	local numTag = 0
	local tag2tid = {  }
	local tid2tag = {  }
	local tid2vids = {  }
	local vid2code = {  }
	local vid2numf = {  }
	local ccode2name = {  }
	-- Read category codes.
	printl( 'Read category codes.' )
	for line in io.lines( srcCatPath ) do
		local ccode, name = line:match( '^(%d+),(.-),.-,%d-,%d-$' )
		if ccode == nil or name == nil then
			ccode, name = line:match( '^(%d+),"(.-)",.-,.-,.-$' )
		end
		assert( ccode ~= nil and name ~= nil )
		assert( ccode:len(  ) ~= 0 and name:len(  ) ~= 0 )
		ccode2name[ ccode ] = name
	end
	collectgarbage(  )
	printl( 'Done.' )
	-- Read number of frames per video.
	printl( 'Read number of frames per video.' )
	local vid = 0
	for line in io.lines( srcNumFramePath ) do
		vid = vid + 1
		local vcode, numim = line:match( '^(%d+),(%d+),' )
		vid2code[ vid ] = vcode
		vid2numf[ vid ] = tonumber( numim )
	end
	collectgarbage(  )
	printl( 'Done.' )
	-- Read category/tag information per video.
	printl( 'Read category/tag information per video.' )
	vid = 0
	for line in io.lines( srcTagPath ) do
		vid = vid + 1
		-- Video code processing.
		local vcode = line:match( '(%d+),' )
		assert( vid2code[ vid ] == vcode )
		subLine = line:sub( line:match( '%d+,' ):len(  ) + 1 )
		-- Category processing.
		local tcnt = 0
		for c = 1, 9 do
			local ccode = subLine:match( '(%--%d+),' )
			subLine = subLine:sub( subLine:match( '%--%d+,' ):len(  ) + 1 )
			if ccode == '-1' then goto continue end
			local tag = ccode2name[ ccode ]:lower(  )
			assert( ccode ~= nil and tag ~= nil )
			tags = tagFilter( tag )
			for _, tag in pairs( tags ) do
				tcnt = tcnt + 1
				tid = tag2tid[ tag ]
				if tid == nil then
					numTag = numTag + 1
					tid = numTag
					tag2tid[ tag ] = tid
					tid2tag[ tid ] = tag
					tid2vids[ tid ] = {  }
				end
				table.insert( tid2vids[ tid ], vid )
				printl( ( 'V%06d T%02d: (category) %s' ):format( vid, tcnt, tag ) )
			end
			::continue::
		end
		subLine = subLine:sub( subLine:match( '%d+%.-%d-,%d+,' ):len(  ) + 1 )
		-- Tag processing.
		local isLastTag = false
		while true do
			local tag = subLine:match( '(.-):%d+:' )
			if tag == nil or tag:match( '.-:%d-,.+' ) ~= nil then
				tag = subLine:match( '(.-):%d-,.+' )
				isLastTag = true
			end
			assert( tag ~= nil )
			tag = tag:lower(  )
			tags = tagFilter( tag )
			for _, tag in pairs( tags ) do
				tcnt = tcnt + 1
				local tid = tag2tid[ tag ]
				if tid == nil then
					numTag = numTag + 1
					tid = numTag
					tag2tid[ tag ] = tid
					tid2tag[ tid ] = tag
					tid2vids[ tid ] = {  }
				end
				table.insert( tid2vids[ tid ], vid )
				printl( ( 'V%06d T%02d: %s' ):format( vid, tcnt, tag ) )
			end
			if isLastTag then break end
			subLine = subLine:sub( subLine:match( '.-:%d+:' ):len(  ) + 1 )
		end
		if vid % 10000 == 0 then collectgarbage(  ) end
	end
	for tid, vids in pairs( tid2vids ) do tid2vids[ tid ] = unique( vids, true ) end
	tag2tid = nil
	collectgarbage(  )
	printl( ( '%d videos, %d tags found in total.' ):format( vid, numTag ) )
	return tid2tag, tid2vids, vid2code, vid2numf
end
