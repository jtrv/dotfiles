# VERSION: 0.06
# AUTHORS: nindogo (nindogo@gmail.com)

# LICENSING INFORMATION

import re
import math
import threading
from helpers import retrieve_url
from novaprinter import prettyPrinter
# some other imports if necessary
try:
    # Python 3
    from html.parser import HTMLParser
except ImportError:
    # Python 2
    from HTMLParser import HTMLParser


class torrentgalaxy(object):
    url = 'https://torrentgalaxy.to/'
    name = 'TorrentGalaxy'
    supported_categories = {
        'all': '',
        'movies': 'c3=1&c46=1&c45=1&c42=1&c4=1&c1=1&',
        'tv': 'c41=1&c5=1&c6=1&c7=1&',
        'music': 'c23=1&c24=1&c25=1&c26=1&c17=1&',
        'games': 'c43=1&c10=1&',
        'anime': 'c28=1&',
        'software': 'c20=1&c21=1&c18=1&',
        'pictures': 'c37=1&',
        'books': 'c13=1&c19=1&c12=1&c14=1&c15=1&',
    }

    class TorrentGalaxyParser(HTMLParser):
        DIV, A, SPAN, FONT, SMALL, = 'div', 'a', 'span', 'font', 'small'
        count_div, = -1,
        get_size, get_seeds, get_leechs = False, False, False
        this_record = {}
        url = 'https://torrentgalaxy.to'

        def handle_starttag(self, tag, attrs):
            if tag == self.DIV:
                my_attrs = dict(attrs)
                if (my_attrs.get('class') == 'tgxtablerow'):
                    self.count_div = 0
                    self.this_record = {}
                    self.this_record['engine_url'] = self.url
                if (my_attrs.get('class') == 'tgxtablecell') and \
                        self.count_div >= 0:
                    self.count_div += 1

            if tag == self.A and self.count_div < 9:
                my_attrs = dict(attrs)
                if 'title' in my_attrs and ('class' not in my_attrs):
                    self.this_record['name'] = my_attrs['title']
                    self.this_record['desc_link '] = \
                        self.url + my_attrs['href']
                if 'role' in my_attrs and my_attrs.get('role') == 'button':
                    self.this_record['link'] = my_attrs['href']

            if tag == self.SPAN:
                my_attrs = dict(attrs)
                if 'class' in my_attrs and \
                        my_attrs.get('class') == 'badge badge-secondary':
                    self.get_size = True

            if tag == self.FONT:
                my_attrs = dict(attrs)
                if my_attrs.get('color') == 'green':
                    self.get_seeds = True
                elif my_attrs.get('color') == '#ff0000':
                    self.get_leechs = True

            if self.count_div == 9 and tag == self.SMALL:
                prettyPrinter(self.this_record)
                self.this_record = {}
                self.count_div = -1

        def handle_data(self, data):
            if self.get_size is True and self.count_div < 9:
                self.this_record['size'] = data.strip().replace(',', '')
                self.get_size = False
            if self.get_seeds is True:
                self.this_record['seeds'] = data.strip().replace(',', '')
                self.get_seeds = False
            if self.get_leechs is True:
                self.this_record['leech'] = data.strip().replace(',', '')
                self.get_leechs = False

    def do_search(self, url):
        webpage = retrieve_url(url)
        tgParser = self.TorrentGalaxyParser()
        tgParser.feed(webpage)

    def search(self, what, cat='all'):
        query = str(what).replace(r' ', '+')
        search_url = 'https://torrentgalaxy.to/torrents.php?'
        full_url = \
            search_url + \
            self.supported_categories[cat.lower()] + \
            'sort=seeders&order=desc&search=' + \
            query

        webpage = retrieve_url(full_url)
        tgParser = self.TorrentGalaxyParser()
        tgParser.feed(webpage)

        all_results_re = re.compile(r'steelblue[^>]+>(.*?)<')
        all_results = all_results_re.findall(webpage)[0]
        all_results = all_results.replace(' ', '')
        pages = math.ceil(int(all_results) / 50)
        threads = []
        for page in range(1, pages):
            this_url = full_url + '&page=' + str(page)
            t = threading.Thread(args=(this_url,), target=self.do_search)
            threads.append(t)
            t.start()
            # self.do_search(this_url)
        
        for thread in threads:
            thread.join()

if __name__ == '__main__':
    a = torrentgalaxy()
    a.search('ncis new', 'all')
