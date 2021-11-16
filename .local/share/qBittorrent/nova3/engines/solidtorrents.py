# VERSION: 1.00
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

from helpers import download_file, retrieve_url
from novaprinter import prettyPrinter
import json


class solidtorrents(object):
    url = 'https://solidtorrents.net'
    name = 'Solid Torrents'
    supported_categories = {'all': 'all', 'music': 'Audio', 'books': 'eBook'}

    def print_torrents(self, torrents):
        for torrent in torrents:
            prettyPrinter({
                "link": torrent['magnet'],
                "name": torrent['title'],
                "size": str(torrent['size'])+" B",
                "seeds": str(torrent['swarm']["seeders"]),
                "leech": str(torrent['swarm']["leechers"]),
                "engine_url": self.url,
                "desc_link": str(-1),
            })

    def request(self, searchTerm, category, skip):
        datastr = retrieve_url(self.url + '/api/v1/search?sort=seeders&q=' +
                               searchTerm+'&category='+category+'&skip='+str(skip)+'&fuv=yes')
        data = json.loads(datastr)

        totalHits = data['hits']['value']
        resultsLength = len(data['results'])
        results = data['results']
        return totalHits, resultsLength, results

    def search(self, what, cat='all'):
        category = self.supported_categories[cat]
        total, step, results = self.request(what, category, 0)

        self.print_torrents(results)
        totalTorrents = step

        while(totalTorrents < total):
            total, step, results = self.request(
                what, category, totalTorrents + step)
            if(step == 0):
                break
            self.print_torrents(results)
            totalTorrents += step
            print(totalTorrents)
