#VERSION: 1.22
#AUTHORS: Jose Lorenzo (josee.loren@gmail.com)

from helpers import download_file, headers
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

class pctreload(object):
    url = 'https://pctreload1.com'
    name = 'PCTReload'
    size = ""
    count = 1
    list = [] 
    
    class HTMLParser1(HTMLParser):
        indicador = 0
        def handle_starttag(self, tag, attrs):
            if tag == 'a' and self.indicador == 1:
                Dict = dict(attrs)
                pctreload.get_torrent2(self, Dict["href"])
                self.indicador = 0
            elif tag == "span":
                Dict = dict(attrs)
                if "class" in Dict and Dict["class"] == "color":
                    self.indicador = 1

    def retrieve_url2(self, url):
        req = urllib.request.Request(url, headers=headers)
        try:
            response = urllib.request.urlopen(req)
            dat = response.read()
            response.close()
            return dat
        except urllib.error.URLError as errno:
            response.close()
            return ""
        return ""

    def do_post(self, full_url, what):
        query_args = {'s': what, 'pg': self.pg}
        encoded_args = urllib.parse.urlencode(query_args).encode('ascii')
        req = urllib.request.Request(full_url, data=encoded_args, headers=headers)
        req2 = urllib.request.urlopen(req)
        with req2 as response:
            the_page = response.read()
            self.pg = self.pg + 1
            req2.close()
            return the_page
        req2.close()
            
    def montar_torrent(self, link):
        num = -1
        name = ""
        while link.split("/")[num].split('.')[0] == "":
            num = num - 1
            name = link.split("/")[num].split('.')[0]
        
        link = pctreload.url + link[link.find("/"):]
        
        
        item = {}
        item['seeds'] = '-1'
        item['leech'] = '-1'
        item['name'] = name
        item['size'] = pctreload.size
        item['link'] = link
        item['engine_url'] = pctreload.url
        item['desc_link'] = link

        #print(item)
        prettyPrinter(item)
        pctreload.count = pctreload.count + 1
        
    def get_torrent_core(self, link):
        if link not in pctreload.list: 
            pctreload.list.append(link) 
        else:
            return
        
        html_virgen = pctreload.retrieve_url2(self, link)
        html_virgen = str(html_virgen)
        idx = html_virgen.find("window.location.href = \"//")
        html = html_virgen[idx:]
        html = html[:html.find("\";")]
        html = html[26:]
        if html == "":
            parser = pctreload.HTMLParser1()
            parser.feed(str(html_virgen))
        else:
            pctreload.montar_torrent(self,html)
        return
    
    def get_torrent2(self, link):
        pctreload.get_torrent_core(self, link)
    
    def get_torrent(self, guid):
        link = self.url + "/" +  guid
        pctreload.get_torrent_core(self, link)
    
    def search(self, what, cat='all'):
        self.pg = 1
            
        while self.pg > 0:
            json_data = self.do_post(self.url+'/get/result/', what)
            torrents = json.loads(json_data)['data']['torrents']
            #print (torrents)
            
            for k, v in torrents.items():
                if v == None:
                    return
                for k2, v2 in v.items():
                    for k3, v3 in v2.items():
                        if k3 == 'torrentSize':
                            pctreload.size = v3
                        if k3 == 'guid':
                            self.get_torrent(v3)
                            
                            
            self.pg = self.pg + 1
        print(pctreload.count)

if __name__ == "__main__":
    m = pctreload()
    m.search('star wars')
