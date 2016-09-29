require 'torch'
require 'paths'

------------------
-- 1. SET PATHS --
------------------
local srcTagPath = '/home/doyoo/workspace/datain/STOCK/video1m_meta_keywords.txt'
local srcCatPath = '/home/doyoo/workspace/datain/STOCK/category.csv'
local srcNumFramePath = '/home/doyoo/stock/videos/video1m_meta_simple_frames.txt'
local srcWord2VecPath = '/home/doyoo/workspace/src/word2vec.torch/word2vec.t7'
local dstDir = './data_ml'
local dstDataRawName = 'dataRaw.t7'
local dstDataAfterClusterName = 'dataAfterCluster.t7'
local dstVideoLabelListName = 'video-labels.txt'
local dstLabelListName = 'classes.txt'
local dstDataRawPath = paths.concat( dstDir, dstDataRawName )
local dstDataAfterClusterPath = paths.concat( dstDir, dstDataAfterClusterName )
local dstVideoLabelListPath = paths.concat( dstDir, dstVideoLabelListName )
local dstLabelListPath = paths.concat( dstDir, dstLabelListName )
os.execute( 'mkdir -p ' .. dstDir )

-------------------
-- 2. SET PARAMS --
-------------------
local minNumVideoPerTag    = 20  -- early screening.
local minNumCharPerTag     = 3   -- early screening.
local minNumFramePerVideo  = 40  -- post screening.
local maxNumFramePerVideo  = 90  -- post screening.
local minNumClassPerVideo  = 1   -- post screening.
local minNumVideoPerClass  = 100 -- post screening.
local clusteringFactor     = 3
local iteration            = 20

-------------------------
-- GIVE STARTING POINT --
-------------------------
local data = nil
if paths.filep( dstDataAfterClusterPath ) then 
	print( 'Load data after word clustering.' )
	data = torch.load( dstDataAfterClusterPath )
	print( 'Done.' )
	goto postscreen
end
if paths.filep( dstDataRawPath ) then
	print( 'Load raw data.' )
	data = torch.load( dstDataRawPath )
	print( 'Done.' )
	goto earlyscreen
end

----------------------
-- 3. READ RAW DATA --
----------------------
::rawdata::
do
	require( 'read_raw_tags' )
	data = {  }
	data.tid2tag, 
	data.tid2vids,
	data.vid2code, 
	data.vid2numf = readRawTags( 
		srcCatPath,
		srcTagPath,
		srcNumFramePath,
		minNumVideoPerTag, 
		minNumCharPerTag )
	printl( 'Save.' )
	torch.save( dstDataRawPath, data )
	printl( 'Done.' )
end

------------------------
-- 4. EARLY SCREENING --
------------------------
::earlyscreen::
do
	require( 'early_screen' )
	printl( 'Load word2vec db.' )
	local word2vec = torch.load( srcWord2VecPath )
	printl( 'Done.' )
	data.tid2tag, 
	data.tid2vids, 
	data.tid2vec = earlyScreen( 
		data.tid2tag,
		data.tid2vids,
		word2vec,
		minNumVideoPerTag,
		minNumCharPerTag )
	collectgarbage(  )
end

----------------------------
-- 5. WORD2VEC CLUSTERING --
----------------------------
do
	require( 'cluster_words' )
	data.cid2name, 
	data.cid2vids = clusterWords( 
		data.tid2tag, 
		data.tid2vids, 
		data.tid2vec, 
		clusteringFactor, 
		iteration )
	data.tid2tag = nil
	data.tid2vids = nil
	data.tid2vec = nil
	collectgarbage(  )
	printl( 'Save.' )
	torch.save( dstDataAfterClusterPath, data )
	printl( 'Done.' )
end

-----------------------
-- 6. POST-SCREENING --
-----------------------
::postscreen::
do
	require( 'post_screen' )
	data.cid2name,
	data.cid2vids,
	data.vid2code,
	data.vid2numf,
	data.vid2cids,
	data.vid2bow = postScreen( 
		data.cid2name,
		data.cid2vids,
		data.vid2code,
		data.vid2numf,
		minNumFramePerVideo,
		maxNumFramePerVideo,
		minNumClassPerVideo,
		minNumVideoPerClass )
	collectgarbage(  )
end

-------------------------------
-- 7. WRITE VIDEO-LABEL LIST --
-------------------------------
::writelist::
do
	require( 'write_list' )
	writeList( 
		data.vid2cids,
		data.vid2code,
		data.vid2numf,
		data.cid2name,
		dstVideoLabelListPath,
		dstLabelListPath )
end
