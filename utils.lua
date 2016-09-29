function sizeof( tab )
	local cnt = 0
	for _,_ in pairs( tab ) do cnt = cnt + 1 end
	return cnt
end
function max( tab )
	local val = -1e300
	for _,v in pairs( tab ) do if v > val then val = v end end
	return val
end
function min( tab )
	local val = 1e300
	for _,v in pairs( tab ) do if v < val then val = v end end
	return val
end
function unique( tab, sort )
	local v2k, k2v, k = {  }, {  }, 0
	for _,v in pairs( tab ) do v2k[ v ] = true end
	for v,_ in pairs( v2k ) do k2v[ #k2v + 1 ] = v end
	if sort then table.sort( k2v ) end
	return k2v
end
function concat( t1, t2 )
	for i = 1, #t2 do table.insert( t1, t2[ i ] ) end
	return t1
end
