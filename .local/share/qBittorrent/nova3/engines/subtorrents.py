#VERSION: 1.00
#AUTHORS: Jose Lorenzo (josee.loren@gmail.com)

from helpers import download_file, retrieve_url, headers
from novaprinter import prettyPrinter
import re
import json
import urllib.error
import urllib.parse
import urllib.request

try:
    #python3
    from html.parser import HTMLParser
except ImportError:
    #python2
    from HTMLParser import HTMLParser


class subtorrents(object):
    name = 'SubTorrents'
    url = 'https://www.subtorrents.la'
    
    class HTMLParser1(HTMLParser):
            enable = 0
            
            class HTMLParser2(HTMLParser):
                url = 'https://www.subtorrents.la'
                list = [] 
                
                def get_torrent(self, torrent):
                    if torrent not in self.list: 
                        self.list.append(torrent) 
                    else:
                        return
                    
                    idx = torrent.split("/")[-1].rfind('.')
                    name = torrent.split("/")[-1][0:idx]
                    link = torrent
                    
                    item = {}
                    item['seeds'] = '-1'
                    item['leech'] = '-1'
                    item['name'] = name
                    item['size'] = '-1'
                    item['link'] = link
                    item['engine_url'] = self.url
                    item['desc_link'] = link

                    prettyPrinter(item)
        
                def handle_starttag(self, tag, attrs):
                    if tag == 'a':
                        Dict = dict(attrs)
                        if 'href' in Dict and Dict['href'].find(".torrent")>0:
                            self.get_torrent(Dict['href'])
                    
            def handle_starttag(self, tag, attrs):
                if tag == 'a':
                    Dict = dict(attrs)
                    if Dict['href'].find("?filtro=subs-integrados") > 0:
                        self.enable = 1
                    elif Dict['href'].find("/?s=") > 0 or Dict['href'].find("check/referer") > 0:
                        self.enable = 0
                    elif self.enable == 1:
                        html = retrieve_url(Dict['href'])
                        parser = self.HTMLParser2()
                        parser.feed(html)
                       
            
    
    
    def search(self, what, cat='all'):
        self.pg = 1
            
        while self.pg > 0:
            html = retrieve_url(self.url + '/page/'+str(self.pg)+'/?s=' + what)
            if html == "":
                return
               
            parser = self.HTMLParser1()
            parser.feed(html)
            
                            
            self.pg = self.pg + 1
            
            
if __name__ == "__main__":
    m = subtorrents()
    m.search('mr+robot')