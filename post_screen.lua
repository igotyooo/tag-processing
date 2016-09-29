require 'utils'
require 'torch'

function printl( str )
	print( 'POST_SCREEN) ' .. str )
end
function postScreen( 
	cid2name,
	cid2vids,
	vid2code,
	vid2numf,
	minNumFramePerVideo,
	maxNumFramePerVideo,
	minNumClassPerVideo,
	minNumVideoPerClass )
	assert( sizeof( vid2code ) == sizeof( vid2numf ) )
	assert( sizeof( cid2name ) == sizeof( cid2vids ) )
	local vid2cids = nil
	while true do
		local numTag = sizeof( cid2name )
		local numVideo = sizeof( vid2code )
		-- Tag filtering.
		local cid2name_, cid2vids_, cid_ = {  }, {  }, 0
		for cid, class in pairs( cid2name ) do
			if sizeof( cid2vids[ cid ] ) < minNumVideoPerClass then goto continue end
			cid_ = cid_ + 1
			cid2name_[ cid_ ] = class
			cid2vids_[ cid_ ] = cid2vids[ cid ]
			::continue::
		end
		printl( ( 'Remove classes: %d > %d' ):format( sizeof( cid2name ), sizeof( cid2name_ ) ) )
		cid2name, cid2vids = cid2name_, cid2vids_
		collectgarbage(  )
		-- Update video.
		vid2cids = {  }
		for vid = 1, sizeof( vid2code ) do vid2cids[ vid ] = {  } end
		for cid, vids in pairs( cid2vids ) do
			for _, vid in pairs( vids ) do 
				table.insert( vid2cids[ vid ], cid )
			end
		end
		collectgarbage(  )
		-- Video filtering.
		local vid2code_, vid2numf_, vid2cids_, vid_ = {  }, {  }, {  }, 0
		for vid, numf in pairs( vid2numf ) do
			if numf < minNumFramePerVideo then goto continue end
			if numf > maxNumFramePerVideo then goto continue end
			if sizeof( vid2cids[ vid ] ) < minNumClassPerVideo then goto continue end
			vid_ = vid_ + 1
			vid2code_[ vid_ ] = vid2code[ vid ]
			vid2cids_[ vid_ ] = vid2cids[ vid ]
			vid2numf_[ vid_ ] = numf
			::continue::
		end
		printl( ( 'Remove videos: %d > %d' ):format( sizeof( vid2code ), sizeof( vid2code_ ) ) )
		vid2code, vid2numf, vid2cids = vid2code_, vid2numf_, vid2cids_
		collectgarbage(  )
		-- Update class.
		cid2vids = {  }
		for cid = 1, sizeof( cid2name ) do cid2vids[ cid ] = {  } end
		for vid, cids in pairs( vid2cids ) do
			for _, cid in pairs( cids ) do
				table.insert( cid2vids[ cid ], vid )
			end
		end
		collectgarbage(  )
		-- Check condition.
		assert( sizeof( cid2name ) == sizeof( cid2vids ) )
		assert( sizeof( vid2code ) == sizeof( vid2numf ) )
		assert( sizeof( vid2code ) == sizeof( vid2cids ) )
		if numTag == sizeof( cid2name ) and numVideo == sizeof( vid2code ) then break end
	end
	collectgarbage(  )
	printl( 'Done.' )
	return cid2name, cid2vids, vid2code, vid2numf, vid2cids, vid2bow
end
