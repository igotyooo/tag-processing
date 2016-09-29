import os
import os.path as osp
import multiprocessing
import functools
import json
import shutil


def _run_single(x, modules=None, log_dir=None):
	'''Move out from the class so that we can use multiprocessing'''
	ox = x[0] if len(x) == 2 else x
	log_path = osp.join(log_dir, ox + '.done')
	if osp.exists(log_path):
		return None

	try:
		for module in modules:
			x = module.run(x)
			if x is None:
				open(osp.join(log_dir, ox + '.failed'), 'w').close()
				break
			else:
				open(log_path, 'w').close()

		for module in modules:
			module.close()

	except IOError:
		pass

	return x


class VideoPipeline:
	'''Pipeline for video processing.'''

	def __init__(self, n_job=1, log_dir='/tmp/'):
		self.modules = []
		self.n_job = n_job
		self.log_dir = log_dir
		try:
			os.makedirs(self.log_dir)
		except:
			pass

	def add(self, module):
		self.modules.append(module)

	def run(self, ilist):
		_run_single_arg = functools.partial(_run_single,
											modules=self.modules,
											log_dir=self.log_dir)
		if self.n_job == 1:
			out = map(_run_single_arg, ilist)
		else:
			out = multiprocessing.Pool(self.n_job).map(_run_single_arg, ilist)
		print 'final output length: ', len(out)


class ProcessVideo:
	'''Archiving frames by tar'''

	def __init__(self, work_dir='/tmp/', *args, **kwargs):
		self.work_dir = work_dir

	def run(self, key):
		cid = key

		print(cid)

		## extract frames

                cmd = 'tar xf /mnt/ilcompf2d1/user/jolee/dataset/stock/videos/tars/{}.tar -C /mnt/ssd/tmp/doyoo/stock-frames/'.format(cid)
		ret = os.system(cmd)
	#	print cmd
		if ret != 0:
			return None

		return 1

	def close(self):
		pass


def main():
	print "Loading metadata..."
	keys = []
	with open('./data_ml/video-labels.txt') as f:
		for i in f:
			cid = i[:8]
			keys.append(cid)

	print "Start extracting..."
	vp = VideoPipeline(n_job=8, log_dir='/mnt/ssd/tmp/doyoo/logs_tars/')
	vp.add(ProcessVideo('./'))
	vp.run(keys)


if __name__ == '__main__':
	main()
