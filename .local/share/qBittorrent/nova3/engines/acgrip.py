# -*- coding: utf-8 -*-
# VERSION: 1.0
# AUTHORS: Yun (chenzm39@gmail.com)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.


try:
    from HTMLParser import HTMLParser
except ModuleNotFoundError:
    from html.parser import HTMLParser

# import qBT modules
try:
    from novaprinter import prettyPrinter
    from helpers import retrieve_url
except ModuleNotFoundError:
    pass


class acgrip(object):
    """Class used by qBittorrent to search for torrents."""

    url = 'https://acg.rip'
    name = 'acg.rip'

    ###########################################################################

    # defines which search categories are supported by this search engine
    # and their corresponding id. Possible categories are:
    # 'all', 'movies', 'tv', 'music', 'games', 'anime', 'software', 'pictures',
    # 'books'
    supported_categories = {'all': '0_0'}

    class acgripParser(HTMLParser):
        """Parses acg.rip browse page for search results and stores them."""

        def __init__(self, res, url):
            """Construct a acgrip html parser.

            Parameters:
            :param list res: a list to store the results in
            :param str url: the base url of the search engine
            :param str use_magnet: whether to link to magnet links or torrent
                                   files
            """
            try:
                super().__init__()
            except TypeError:
                #  See: http://stackoverflow.com/questions/9698614/
                HTMLParser.__init__(self)

            self.engine_url = url
            self.results = res
            self.curr = None
            self.td_counter = -1
            self.find_title = False
            self.span_counter = -1

        def handle_starttag(self, tag, attr):
            """Tell the parser what to do with which tags."""
            if tag == 'a':
                self.start_a(attr)
            if tag == 'span':
                self.start_span(attr)

        def handle_endtag(self, tag):
            """Handle the closing of table cells."""
            if tag == 'td':
                self.start_td()

        def start_a(self, attr):
            """Handle the opening of anchor tags."""
            params = dict(attr)
            # get torrent name
            if 'class' not in params and not params['href'].endswith(".torrent")\
                    and params['href'].startswith('/t/'):
                hit = {'desc_link': self.engine_url + params['href']}
                self.td_counter += 1
                if not self.curr:
                    hit['engine_url'] = self.engine_url
                    self.curr = hit
            elif 'href' in params and self.curr:
                # skip unrelated links
                if not params['href'].endswith(".torrent"):
                    return

                # check whether to use torrent files or magnet links,
                # then search for a matching download link, and move on
                if params['href'].endswith(".torrent"):
                    self.curr['link'] = self.engine_url + params['href']

        def start_span(self, attr):
            """Handle the starting of a table"""
            params = dict(attr)
            if 'class' in params and \
                    params['class'] == 'title':
                self.find_title = True
            elif 'class' in params and not params['class'].startswith('label'):
                if self.span_counter == -1:
                    self.span_counter += 1
                elif self.span_counter == 2:
                    self.span_counter -= 1
            else:
                pass

        def start_td(self):
            """Handle the opening of a table cell tag."""
            # Keep track of timers
            if self.td_counter >= 0:
                self.td_counter += 1

            # Add the hit to the results,
            # then reset the counters for the next result
            if self.td_counter >= 4:
                self.results.append(self.curr)
                self.curr = None
                self.td_counter = -1
                self.find_title = False
                self.span_counter = -1

        def handle_data(self, data):
            """Extract data about the torrent."""
            # These fields matter
            if self.td_counter > -1\
                    and self.td_counter <= 4:
                # Catch the name
                if self.find_title and self.td_counter == 0:
                    self.curr['name'] = data.strip()
                    self.find_title = False
                # Catch the size
                elif self.td_counter == 2:
                    self.curr['size'] = data.strip()
                elif self.td_counter == 3:
                    # Catch the seeds
                    if self.span_counter == 0:
                        try:
                            self.span_counter += 2
                            self.curr['seeds'] = int(data.strip())
                        except ValueError:
                            self.curr['seeds'] = -1
                    # Catch the leech
                    elif self.span_counter == 1:
                        try:
                            self.span_counter += 2
                            self.curr['leech'] = int(data.strip())
                        except ValueError:
                            self.curr['leech'] = -1
                    else:
                        pass
                # The rest is not supported by prettyPrinter
                else:
                    pass

    # DO NOT CHANGE the name and parameters of this function
    # This function will be the one called by nova2.py

    def search(self, what, cat='all'):
        """
        Retreive and parse engine search results by category and query.

        Parameters:
        :param what: a string with the search tokens, already escaped
                     (e.g. "Ubuntu+Linux")
        :param cat:  the name of a search category, see supported_categories.
        """
        url = self.url

        hits = []
        page = 1
        parser = self.acgripParser(hits, self.url)
        while True:
            res = retrieve_url(f'{url}/page/{page}?term={what}')
            parser.feed(res)
            for each in hits:
                prettyPrinter(each)

            if len(hits) < 30:
                break
            del hits[:]
            page += 1

        parser.close()
