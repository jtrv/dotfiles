# VERSION: 1.2
# AUTHOR: msagca
# -*- coding: utf-8 -*-

from helpers import retrieve_url
from html.parser import HTMLParser
from novaprinter import prettyPrinter
from queue import Queue
from threading import Thread


class PrettyWorker(Thread):
    def __init__(self, queue):
        super().__init__()
        self.queue = queue

    def run(self):
        while True:
            try:
                prettyPrinter(self.queue.get(timeout=2))
            except:
                return
            self.queue.task_done()


class uniondht:
    name = 'UnionDHT'
    url = 'http://uniondht.org'
    supported_categories = {'all': ''}

    class UnionDHTParser(HTMLParser):
        def __init__(self, url):
            super().__init__()
            self.engine_url = url
            self.torrent_info = self.default_torrent_info()
            self.total_results = 0
            self.print_queue = Queue()
            self.print_worker = PrettyWorker(self.print_queue)
            self.find_total_results = True
            self.find_torrent = False
            self.find_desc_link = False
            self.find_name = False
            self.find_link = False
            self.find_seeds = False
            self.find_leech_class = False
            self.find_leech = False
            self.parse_total_results = False
            self.parse_name = False
            self.parse_size = False
            self.parse_seeds = False
            self.parse_leech = False
            self.print_result = False

        def default_torrent_info(self):
            return {'link': '', 'name': '', 'size': '-1', 'seeds': '-1', 'leech': '-1', 'engine_url': self.engine_url, 'desc_link': ''}

        def handle_starttag(self, tag, attrs):
            if self.find_total_results:
                if tag == 'p':
                    attributes = dict(attrs)
                    if 'class' in attributes:
                        if attributes['class'] == 'floatR':
                            self.find_total_results = False
                            self.parse_total_results = True
            elif self.find_torrent:
                if tag == 'tr':
                    attributes = dict(attrs)
                    if 'id' in attributes:
                        if attributes['id'].startswith('tor'):
                            self.find_torrent = False
                            self.find_desc_link = True
            elif self.find_desc_link:
                if tag == 'a':
                    attributes = dict(attrs)
                    if 'href' in attributes:
                        if attributes['href'].startswith('/topic'):
                            self.torrent_info['desc_link'] = self.engine_url + attributes['href']
                            self.find_desc_link = False
                            self.find_name = True
            elif self.find_name:
                if tag == 'b':
                    self.find_name = False
                    self.parse_name = True
            elif self.find_link:
                if tag == 'wbr':
                    self.find_link = False
                    self.parse_name = True
                elif tag == 'a':
                    attributes = dict(attrs)
                    if 'href' in attributes:
                        if attributes['href'].startswith('/dl.'):
                            self.torrent_info['link'] = self.engine_url + attributes['href']
                            self.find_link = False
                            self.parse_size = True
            elif self.find_seeds:
                if tag == 'td':
                    attributes = dict(attrs)
                    if 'class' in attributes:
                        if attributes['class'].find('seed') != -1:
                            self.find_seeds = False
                            self.parse_seeds = True
            elif self.find_leech_class:
                if tag == 'td':
                    attributes = dict(attrs)
                    if 'class' in attributes:
                        if attributes['class'].find('leech') != -1:
                            self.find_leech_class = False
                            self.find_leech = True
            elif self.find_leech:
                if tag == 'b':
                    self.find_leech = False
                    self.parse_leech = True

        def handle_data(self, data):
            if self.parse_total_results:
                total_results = data.split(':')[1].split('(')[0].strip()
                self.total_results = int(total_results)
                self.parse_total_results = False
                self.find_torrent = True
            elif self.parse_name:
                self.torrent_info['name'] += data.strip()
                self.parse_name = False
                self.find_link = True
            elif self.parse_size:
                self.torrent_info['size'] = data.replace('\xa0', '').strip()
                self.parse_size = False
                self.find_seeds = True
            elif self.parse_seeds:
                self.torrent_info['seeds'] = data.strip()
                self.parse_seeds = False
                self.find_leech_class = True
            elif self.parse_leech:
                self.torrent_info['leech'] = data.strip()
                self.parse_leech = False
                self.print_result = True

        def handle_endtag(self, tag):
            if self.print_result:
                self.print_queue.put(self.torrent_info)
                self.torrent_info = self.default_torrent_info()
                self.print_result = False
                self.find_torrent = True

    def search(self, what, cat='all'):
        parser = self.UnionDHTParser(self.url)
        parser.print_worker.start()
        page_number = 1
        torrent_count = 0
        while True:
            search_url = f'{self.url}/tracker.php?nm={what}&start={torrent_count}'
            try:
                retrieved_page = retrieve_url(search_url)
                parser.feed(retrieved_page)
            except:
                break
            torrent_count += 50
            if torrent_count < parser.total_results:
                page_number += 1
                if page_number > 20:
                    break
            else:
                break
        parser.print_queue.join()
        parser.close()


if __name__ == '__main__':
    engine = uniondht()
    engine.search('ubuntu')
