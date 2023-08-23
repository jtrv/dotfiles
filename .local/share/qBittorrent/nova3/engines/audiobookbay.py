# VERSION: 0.1
# AUTHORS: nKlido

# LICENSING INFORMATION
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from helpers import retrieve_url
from novaprinter import prettyPrinter
from html.parser import HTMLParser
import urllib.parse
import math


class audiobookbay(object):
    url = 'http://audiobookbay.fi'
    name = 'AudioBook Bay (ABB)'
    supported_categories = {'all': 'all'}


    class TorrentInfoParser(HTMLParser):

        def __init__(self,url):
            HTMLParser.__init__(self)
            self.url = url
            self.foundResult = False
            self.foundTitle = False
            self.parseTitle = False
            self.torrentReady = False
            self.totalPages = 0
            self.torrent_info = self.empty_torrent_info()


        def empty_torrent_info(self):
            return {
                'link': '',
                'name': '',
                'size': '100 MB',
                'seeds': '1',
                'leech': '1',
                'engine_url': self.url,
                'desc_link': ''
            }



        def handle_starttag(self, tag, attrs):
            params = dict(attrs)

            if 'post' in params.get('class', ''):
                self.foundResult = True

            if(self.foundResult and 'postTitle' in params.get('class','')):
                self.foundTitle = True

            if(self.foundTitle and tag == 'a'):
                self.torrent_info['desc_link'] = self.url + params.get('href')
                self.parseTitle = True

            if(tag == 'a' and '»»' in params.get('title','')):
                self.totalPages = int(params.get('href').split('/')[2])

        def handle_endtag(self, tag):
            if(self.torrentReady):
                size,magnet = self.fetchTorrentDetails(self.torrent_info['name'],self.torrent_info['desc_link'])
                self.torrent_info['link'] = magnet
                if(bool(size)):
                    self.torrent_info['size'] = size

                prettyPrinter(self.torrent_info)
                self.torrent_info = self.empty_torrent_info()                
                self.foundResult = False
                self.torrentReady = False

        def handle_data(self, data):
                
            if(self.parseTitle):
                if(bool(data.strip()) and data != '\n'):
                    self.torrent_info['name'] = data
                self.parseTitle = False
                self.foundTitle = False
                self.torrentReady = True

        class TorrentPageParser(HTMLParser):

            def __init__(self):
                HTMLParser.__init__(self)
                self.hash = ''
                self.size = ''
                self.parseFileSize = False
                self.parseHash = False

            def handle_data(self, data):
                if(data.strip() == 'Info Hash:'):
                    self.parseHash = True
                    return

                if(self.parseHash):
                    if(bool(data.strip())):
                        self.hash = data.strip()
                        self.parseHash = False
                        return

                if(data.strip() == 'Combined File Size:'):
                    self.parseFileSize = True
                    return

                if(self.parseFileSize):
                    if(bool(data.strip())):

                        if(bool(self.size)):
                            self.size = self.size + data.replace('s','')
                            self.parseFileSize = False
                            return
                        self.size = data


        def fetchTorrentDetails(self,title,url):
            html = retrieve_url(url)
            parser = self.TorrentPageParser()
            parser.feed(html)



            link = "magnet:" \
            + "?xt=urn:btih:" + parser.hash \
            + "&dn=" + urllib.parse.quote(title) \
            + "&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969" \
            + "&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969" \
            + "&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce" \
            + "&tr=udp%3A%2F%2Ftracker.open-internet.nl%3A6969%2Fannounce" \
            + "&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A69691337%2Fannounce" \
            + "&tr=udp%3A%2F%2Ftracker.vanitycore.co%3A6969%2Fannounce" \
            + "&tr=http%3A%2F%2Ftracker.baravik.org%3A6970%2Fannounce" \
            + "&tr=http%3A%2F%2Fretracker.telecom.by%3A80%2Fannounce" \
            + "&tr=http%3A%2F%2Ftracker.vanitycore.co%3A6969%2Fannounce"

            parser.close()

            return parser.size,link


    def request(self, searchTerm, category, page=1):
        return retrieve_url(self.url + '/page/'+str(page)+'?s='+searchTerm+'&cat='+category)

    def search(self, what, cat='all'):
        category = self.supported_categories[cat]

        parser = self.TorrentInfoParser(self.url)
        parser.feed(self.request(what,category,1))
        
        totalPages = parser.totalPages
        for page in range(2,totalPages + 1):
            parser.feed(self.request(what,category,page))

        parser.close()
