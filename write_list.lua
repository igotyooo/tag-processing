function printl( str )
	print( 'WRITE) ' .. str )
end
function writeList( 
	vid2cids,
	vid2code,
	vid2numf,
	cid2name,
	dstVideoLabelListPath,
	dstLabelListPath )
	printl( 'Write video-labels list.' )
	local fp = io.open( dstVideoLabelListPath, 'w' )
	for vid, code in pairs( vid2code ) do
		fp:write( ( '%s %d %d ' ):format( code, vid2numf[ vid ], sizeof( vid2cids[ vid ] ) ) )
		for _, cid in pairs( vid2cids[ vid ] ) do
			fp:write( ( '%d ' ):format( cid ) )
		end
		fp:write( '\n' )
	end
	fp.close(  )
	printl( 'Done.' )
	printl( 'Write labels list.' )
	local fp = io.open( dstLabelListPath, 'w' )
	for _, class in pairs( cid2name ) do
		fp:write( ( '%s\n' ):format( class ) )
	end
	fp.close(  )
	printl( 'Done.' )
end
