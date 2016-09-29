require 'utils'

function printl( str )
	print( 'EARLY_SCREEN) ' .. str )
end
function earlyScreen( 
	tid2tag, 
	tid2vids, 
	word2vec,
	minNumVideoPerTag,
	minNumCharPerTag )
	local tid2tag_, tid2vids_ = {  }, {  }
	local tid_, gbg, ind = 0, 0, 0
	local numTag = sizeof( tid2tag )
	local dimWordVec = word2vec.M[ 1 ]:size( 1 )
	local tid2vec = torch.FloatTensor( numTag, dimWordVec ):fill( 0 )
	for tid, tag in pairs( tid2tag ) do
		if sizeof( tid2vids[ tid ] ) < minNumVideoPerTag then
			gbg = gbg + 1
			goto continue
		end
		if tag:len(  ) < minNumCharPerTag then
			gbg = gbg + 1
			goto continue
		end
		ind = word2vec.w2vvocab[ tag ]
		if ind == nil then 
			tag = tag:gsub( '^%a', string.upper ) 
			ind = word2vec.w2vvocab[ tag ]
		end
		if ind == nil then 
			tag = tag:upper(  ) 
			ind = word2vec.w2vvocab[ tag ]
		end
		if ind == nil then 
			gbg = gbg + 1
			goto continue
		end
		tid_ = tid_ + 1
		tid2tag_[ tid_ ] = tid2tag[ tid ]
		tid2vids_[ tid_ ] = tid2vids[ tid ]
		tid2vec[ tid_ ]:copy( word2vec.M[ ind ] )
		::continue::
		if tid % math.floor( numTag / 10 ) == 0 then
			printl( ( '%d/%d tags embedded.' ):format( tid, numTag ) )
		end
	end
	assert( tid_ + gbg == numTag )
	tid2tag, tid2vids = tid2tag_, tid2vids_
	tid2vec = tid2vec[ { { 1, tid_ } } ]
	collectgarbage(  )
	printl( ( '%d tags in total. (%d/%d tags rejected)' ):format( tid_, gbg, numTag ) )
	return tid2tag, tid2vids, tid2vec
end
