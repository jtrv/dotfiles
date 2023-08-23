# VERSION: 2.1
# AUTHORS: Scare! (https://Scare.ca/dl/qBittorrent/)

# Tabstop: 4
# No spaces around operators. Deal with it.

import re
import urllib.parse
from helpers import retrieve_url
from novaprinter import prettyPrinter

class magnetdl(object):
	url='https://www.magnetdl.com'
	name='MagnetDL w. categories'
	query='{self.url}/{what[0]}/{what}/se/desc/{page}/'	# order by seeds desc
	pages=30						# engine max: 30 pages. Early-out if no Next link

# MagnetDL doesn't let you search within categories, but it does have a results column called Type, which is what this plugin uses. Here are the ones I've seen:
# E-Book, Game, Movie, Music, Other, Software, TV
# qBittorrent doesn't have a category that fits MagnetDL's "Other" type. Maybe Porn? You could add it to a line below if you want, ie: 'Movie|Other'. Or as "anime".
# MagnetDL doesn't have types resembling qBittorrent's "anime" or "pictures" categories.

	supported_categories={
		'all':		'.*?',			# match any type instead of specifying one/some
#		'anime':	'',
		'books':	'E-Book',
		'games':	'Game',
		'movies':	'Movie',
		'music':	'Music',
#		'pictures':	'',
		'software':	'Software',		# but not games
		'tv':		'TV'
	}

	# A line of the search results, formatted to be easy to read, with named capturing subpatterns for the useful data. Will be made into a regular expression. This might have to be changed if the site changes its output format:
	row=r"""
	<tr>
		<td class="m">
			<a href="(?P<magnet>magnet:[^"]*)" title="Direct Download" rel="nofollow">
				<img src="/img/m\.gif" alt="Magnet Link" width="\d+" height="\d+" />
			</a>
		</td>
		<td class="n">
			<a href="(?P<link>/file/[^"]*)" title="(?P<title>[^"]*)">\s*(?P<name>[^"]*?)\s*</a>
		</td>
		<td>(?P<age>.*?)</td>
		<td class="t\d+">(?P<type>{cat})</td>
		<td>(?P<files>\d*?)</td>
		<td>(?P<size>[\d,.]*?\s*(?:TB|GB|MB|KB|B|))</td>
		<td class="s">(?P<seeds>[\d,]*?)</td>
		<td class="l">(?P<leech>[\d,]*?)</td>
	</tr>
	"""

	rowFlags=re.I|re.S		# don't specify Ungreedy unless you adjust "edits" too

	# Link to next page, if there is one.
#	nextPage=r'<a href=".*?" title="Downloads \| Page \d+">Next Page &gt;</a>'
	nextPage=r'<a href=".*?" title="Downloads \| Page \d+">Next Page .*?</a>'
	nextFlags=re.I|re.S

	# Magnet link on torrent details page.
	dl=r'<a href="(magnet:.*?)" title="Download: '
	dlFlags=re.I

	# How to get link, name, size, seeds, leech, engine_url, and desc_link from captured subpatterns above:
	fields={
		'link':			'magnet',
		'name':			lambda s,x: x['name']+' \xbb '+x['type'],
		'size':			'size',
		'seeds':		'seeds',
		'leech':		'leech',
		'engine_url':	lambda s,x: s.url,
		'desc_link':	lambda s,x: s.url+x['link']
	}

	# convert "row" to RE
	edits=[
		[r'^\s*(.*?)\s*$',	r'\1',	re.S],	# trim
		[r'>\s*<',			r'>\\s*<'],		# optional whitespace between tags
		[r'\s+',			r'\\s+']		# any whitespace can be multiple \s \t \r \n
	]


	def search(self,what,cat='all'):
		what=re.sub(r'(?:\s|%20|\+)','-',what).lower()
		row=self.row.format(cat=self.supported_categories[cat])
		for x in self.edits:
			flags=0
			if len(x)>2:
				flags=x[2]
			row=re.sub(x[0],x[1],row,flags=flags)
		r=re.compile(row,self.rowFlags)
		n=re.compile(self.nextPage,self.nextFlags)
		for page in range(1,self.pages+1):
			url=self.query.format(self=self,what=what,page=page)
			html=retrieve_url(url)
			for x in r.finditer(html):
				data={}
				for k,v in self.fields.items():
					if isinstance(v,(str,int)):
						data[k]=x[v]
					elif callable(v):
						data[k]=v(self,x)
				for k in ['size','seeds','leech']:			# remove commas from numbers
					data[k]=data[k].replace(',','')
				for k in ['name']:							# remove tags from strings
					data[k]=re.sub('<[^>]*>','',data[k])
				prettyPrinter(data)
			if not n.search(html):
				break

	def download_torrent(self,info):
		html=retrieve_url(urllib.parse.unquote(info))
		m=re.search(self.dl,html,self.dlFlags)
		if m and m.groups():
			print('{0} {1}'.format(m.groups(1),info))
		else:
			raise Exception('Error in download_torrent({info})'.format(info=info))
