#VERSION: 1.6
# AUTHORS: iordic (iordicdev@gmail.com)
import re
import base64
import codecs
from datetime import datetime
from html.parser import HTMLParser

from novaprinter import prettyPrinter
from helpers import download_file, retrieve_url

MAX_DEPTH = 10

def deobfuscate_magnet(obfuscated):
    try:
        for i in range(MAX_DEPTH):
            obfuscated = base64.b64decode(obfuscated)
            decoded_value = codecs.decode(obfuscated.decode(encoding='utf-8'), 'rot_13')
            if 'magnet' in decoded_value:
                return decoded_value
    except:
        return None

def format_info(info):
    info['title'] = info['title'].group(0).lstrip('<h1>Descargar').rstrip('por torrent</h1>').strip() if info['title'] is not None else None
    info['link'] = deobfuscate_magnet(info['link'][1].lstrip('i=').rstrip('"')) if info['link'] is not None else None
    info['size'] = info['size'].group(0).split("</b>")[1].strip() if info['size'] is not None else '0'
    info['quality'] = info['quality'].group(0).lstrip('Calidad:</b>').strip() if info['quality'] is not None else None
    info['language'] = info['language'].group(0).lstrip('Idioma:</b>').strip() if info['language'] is not None else None
    info['date'] = info['date'].group(0).replace(' ', '').lstrip('Fecha:</b>') if info['date'] is not None else -1
    info['seeds'] = info['seeds'].group(0).split(":")[-1].strip() if info['seeds'] is not None else -1
    info['leech'] = info['leech'].group(0).split(":")[-1].strip() if info['leech'] is not None  else -1
    
    info['formatted_name'] = info['title']
    info['formatted_name'] += ' [{}]'.format(info['language']) if info['language'] is not None else ''
    info['formatted_name'] += ' {} '.format(info['quality']) if info['quality'] is not None else ''
    info['formatted_name'] += '({})'.format(info['date']) if info['date'] is not None else ''

class elitetorrent(object):
    url = 'https://www.elitetorrent.com'
    name = 'Elitetorrent'
    # Page has only movies and tv series. Search box has no filters
    supported_categories = {'all': '0', 'movies': 'peliculas', 'tv': 'series'}

    def __init__(self):
        self.pages_limit = 2     # Limit of pages, more pages increase the time it takes

    def download_torrent(self, info):
        """ Unused :( """
        print(download_file(info))

    def search(self, what, cat='all'):
        search_url = "{}/?s={}".format(self.url, what.replace('%20', '+'))
        html = retrieve_url(search_url)

        # Get number of pages
        if "paginacion" in html:
            pages = re.findall(r'<a.*?class="pagina.*?</a>', html)
            if len(pages) > 0:
                last_page = pages[-1]
                last_page = re.findall(r'page/.*?/', last_page)[0]
                last_page = last_page.replace('/', '').replace('page', '')
                number_pages = int(last_page)

        # Only one page but there are results
        elif "Resultado de buscar" in html:
            number_pages = 1
        else:
            # A little trick to avoid entering the pages loop
            number_pages = 0

        # Set number of pages depending by limit
        number_pages = number_pages if number_pages < self.pages_limit else self.pages_limit

        links = []
        
        for page in range(1, number_pages + 1):
            # Each page's url looks like: https://www.example.com/page/[1-9]*/?s=WHAT
            url = "{}/page/{}/?s={}".format(self.url, page, what.replace('%20', '+'))
            html = retrieve_url(url).replace('\n','')   # Replace newline to help the regex
            # I hate regex, check if selected category is films or tv, if its 'all' get both
            pattern = r'({0}/series/.*?/|{0}/peliculas/.*?/)'.format(self.url) if cat == "all" \
                        else r'{0}/{1}/.*?/'.format(self.url, self.supported_categories[cat])
            # Get all ocurrencies
            items = re.findall(pattern, html)
            for item in items:
                if item not in links:
                    links.append(item)

        for i in links:
            # Visiting individual results to get its attributes makes it so slow
            data = retrieve_url(i).replace('\n','')
            info = {}
            info['title'] = re.search(r'<h1>Descargar .+ por torrent</h1>', data)
            info['link'] = re.findall(r'i=[-A-Za-z0-9+/]+\={0,3}\"', data)
            info['size'] = re.search("Tama.?o:</b> [0-9\.]+[\ GM]+B", data)
            info['quality'] = re.search(r'Calidad:</b> [0-9\.a-z\-]+', data)
            info['language'] = re.search(r'Idioma:</b>[a-zA-Zñ\ ]+', data)
            info['date'] = re.search(r'Fecha:</b>[\ 0-9\-]+', data)
            info['seeds'] = re.search(r'<b>Semillas</b>:[\ 0-9]*', data)
            info['leech'] = re.search(r'<b>Clientes</b>:[\ 0-9]*', data)
            format_info(info)                

            if info['title'] is None or info['link'] is None:
                continue    # decoding has failed, skip           

            pub_date = info['date']
            if pub_date != -1:
                # there are 2 format dates: YYYY-MM-DD or DD-MM-YYYY
                if int(pub_date.split("-")[0]) > 1000:
                    parsed_date = datetime.strptime(pub_date, "%Y-%m-%d")
                else:
                    parsed_date = datetime.strptime(pub_date, "%d-%m-%Y")
                pub_date = round(datetime.timestamp(parsed_date))

            item = {
                'seeds' : int(info['seeds']) if info['seeds'] != '' else -1,
                'leech' : int(info['leech']) if info['leech'] != '' else -1,
                'name' : info['formatted_name'],
                'size' : info['size'],
                'desc_link' : i,
                'engine_url' : self.url,
                'link' : info['link'],
                'pub_date' : pub_date
            }
            # Prints in this format: link|name|size|seeds|leech|engine_url|desc_link|pub_date
            prettyPrinter(item)
