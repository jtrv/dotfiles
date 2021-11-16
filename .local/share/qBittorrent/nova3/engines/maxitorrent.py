#VERSION: 1.25
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

class maxitorrent(object):
    url = 'https://atomixhq.com'
    name = 'MaxiTorrent'
    size = ""
    count = 1
    list = [] 
    
    class HTMLParser1(HTMLParser):
        indicador = 0
        def handle_starttag(self, tag, attrs):
            if tag == 'a' and self.indicador == 1:
                Dict = dict(attrs)
                print("30 "+Dict["href"])
                maxitorrent.get_torrent3(self, Dict["href"])
                self.indicador = 0
            elif tag == "div":
                Dict = dict(attrs)
                if "style" in Dict and Dict["style"] == "float:left;width:100%;height:auto;text-align:center;":
                    self.indicador = 1

    class HTMLParser3(HTMLParser):
        indicador = 0
        def handle_starttag(self, tag, attrs):
            if tag == 'a' and self.indicador == 1:
                Dict = dict(attrs)
                #print("44 "+Dict["href"])                
                maxitorrent.get_torrent2(self, Dict["href"])
            elif tag == "ul":
                Dict = dict(attrs)
                if "class" in Dict and Dict["class"] == "buscar-list":
                    #print("indicador 1")
                    self.indicador = 1

        def handle_endtag(self, tag):
            if tag == 'ul':
                #print("end tag")
                self.indicador = 0

    class HTMLParser2(HTMLParser):
        indicador = 0
        def handle_starttag(self, tag, attrs):
            if tag == 'a' and self.indicador == 1:
                Dict = dict(attrs)
                print("44 "+Dict["href"])
                maxitorrent.get_torrent2(self, Dict["href"])
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
        #print("montar_torrent")
        num = -1
        name = link
        if (name[-1] == "/"):
            name = name[:-1]
        
        #print(name)
        while name.find("/") >= 0 and name.split("/")[num].split('.')[0] != "":
            name = name.split("/")[num].split('.')[0]
            num = num - 1
            #print(name)
        
        link = maxitorrent.url + link[link.find("/"):]
        
        item = {}
        item['seeds'] = '-1'
        item['leech'] = '-1'
        item['name'] = name
        item['size'] = maxitorrent.size
        item['link'] = link
        item['engine_url'] = maxitorrent.url
        item['desc_link'] = link

        
        prettyPrinter(item)
        maxitorrent.count = maxitorrent.count + 1
        
    def get_torrent_core(self, link):
        if link not in maxitorrent.list: 
            print("ya está en lista")
            maxitorrent.list.append(link) 
        else:
            return
        
        html_virgen = maxitorrent.retrieve_url2(self, link)
        html_virgen = str(html_virgen)
        
        print("112 "+link)
        idx = html_virgen.find("window.location.href = \"//")
        print("114" + str(idx))
        html = html_virgen[idx:]
        html = html[:html.find("\";")]
        html = html[26:]
        if html == "":
            print("html vacio 1")
            idx = html_virgen.find("window.location.href = \"")
            html = html_virgen[idx-2:]
            html = html[:html.find("\";")]
            html = html[26:]
            if html != "":
                print("NO VACIO html vacio 1")
                maxitorrent.get_torrent3(self,html)
                return
        if html == "":
            print("html vacio 2")
            if html_virgen.find("float:left;width:100%;height:auto;text-align:center;") != -1:
                print("Parser1")
                parser = maxitorrent.HTMLParser1()
                parser.feed(str(html_virgen))
            if html_virgen.find(" style=\"color:#000;font-size:23px;\"") != -1:
                print("Parser3")
                #print(html_virgen)
                parser = maxitorrent.HTMLParser3()
                parser.feed(str(html_virgen))
            else:
                print("Parser2")
                parser = maxitorrent.HTMLParser2()
                parser.feed(str(html_virgen))
        else:
            print("Montar torrent")
            maxitorrent.montar_torrent(self,html)
        return
    
    def get_torrent2(self, link):
        maxitorrent.get_torrent_core(self, link)

    def get_torrent3(self, link):
        maxitorrent.get_torrent_core(self, maxitorrent.url + link)
    
    def get_torrent(self, guid):
        #print(guid)
        link = self.url + "/" +  guid
        maxitorrent.get_torrent_core(self, link)
    
    def search(self, what, cat='all'):
        self.pg = 1
        #print("search")
            
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
                            maxitorrent.size = v3
                        if k3 == 'guid':
                            self.get_torrent(v3)
                            
                            
            self.pg = self.pg + 1
        #print(maxitorrent.count)

if __name__ == "__main__":
    m = maxitorrent()
    m.search('calamar')
