require 'utils'
require 'kmeans'
require 'torch'

function printl( str )
	print( 'CLUSTERING) ' .. str )
end
function clusterWords( 
	tid2tag, 
	tid2vids, 
	tid2vec, 
	clusteringFactor, 
	iteration )
	printl( 'Make training set for Kmeans clustering.' )
	-- Get minimum # of videos per tag.
	local numTag = tid2vec:size( 1 )
	local minNumVid = 1e300
	local k = math.floor( numTag / clusteringFactor )
	for _, vids in pairs( tid2vids ) do
		local num = sizeof( vids )
		if num < minNumVid then minNumVid = num end
	end
	-- Estimate # of training samples.
	local sampleSize = 0
	for _, vids in pairs( tid2vids ) do
		local num = sizeof( vids )
		sampleSize = sampleSize + math.floor( num / minNumVid )
	end
	-- Duplicate word vectors according to their #occurences.
	local dim = tid2vec:size( 2 )
	local sid2vec = tid2vec.new( sampleSize, dim ):fill( 0 )
	local tid2sid = {  }
	local e = 0
	for tid, vids in pairs( tid2vids ) do
		local num = math.floor( sizeof( vids ) / minNumVid )
		local s = e + 1
		e = s + num - 1
		tid2sid[ tid ] = s
		sid2vec[ { { s, e } } ]:copy( tid2vec[ tid ]:view( 1, dim ):expand( num, dim ) )
	end
	-- Kmeans.
	printl( ( 'Run kmeans clustering with %d samples.' ):format( sampleSize ) )
	local _, sid2cid = kmeans( sid2vec, k, iteration, nil, nil, nil )
	printl( 'Done.' )
	tid2cid = {  }
	for tid = 1, numTag do
		tid2cid[ tid ] = sid2cid[ tid2sid[ tid ] ]
	end
	-- Assign tags into clusters.
	printl( 'Assign tags to clusters.' )
	local cid2name = {  }
	local cid2vids = {  }
	for tid, tag in pairs( tid2tag ) do
		local cid = tid2cid[ tid ]
		if cid2name[ cid ] == nil then 
			cid2name[ cid ] = tag .. ', '
			cid2vids[ cid ] = tid2vids[ tid ]
		else
			cid2name[ cid ] = cid2name[ cid ] .. tag .. ', '
			cid2vids[ cid ] = concat( cid2vids[ cid ], tid2vids[ tid ] )
		end
		if tid % math.floor( numTag / 50 ) == 0 then
			collectgarbage(  )
			printl( ( 'Tag %06d/%d assigned to clusters.' ):format( tid, numTag ) )
		end
	end
	-- Remove holes.
	local cid_, cid2name_, cid2vids_ = 0, {  }, {  }
	for cid, name in pairs( cid2name ) do
		cid_ = cid_ + 1
		cid2name_[ cid_ ] = cid2name[ cid ]:match( '(.+),%s$' )
		cid2vids_[ cid_ ] = unique( cid2vids[ cid ], true )
	end
	cid2name, cid2vids = cid2name_, cid2vids_
	collectgarbage(  )
	printl( 'Done.' )
	return cid2name, cid2vids
end
