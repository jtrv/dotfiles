#VERSION: 1.2
#AUTHOR: msagca
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
				prettyPrinter(self.queue.get(timeout=3))
			except:
				return
			self.queue.task_done()

class btmulu(object):

	name = "BTmulu"
	url = "https://www.btmulu.com"
	supported_categories = {"all": ""}

	class BTmuluParser(HTMLParser):

		def __init__(self, url):
			super().__init__()
			self.engine_url = url
			self.torrent_info = {
				"link": "",
				"name": "",
				"size": "-1",
				"seeds": "-1",
				"leech": "-1",
				"engine_url": self.engine_url,
				"desc_link": ""
			}
			self.results_per_page = 20
			self.total_results = 0
			self.print_queue = Queue()
			self.print_worker = PrettyWorker(self.print_queue)
			self.find_summary = True
			self.find_results_per_page = False
			self.find_total_results = False
			self.find_torrent = False
			self.find_link = False
			self.find_info = False
			self.find_extension = False
			self.find_size = False
			self.parse_results_per_page = False
			self.parse_total_results = False
			self.parse_name = False
			self.parse_size = False
			self.print_result = False
			self.skip_extension = False

		def handle_starttag(self, tag, attrs):
			if self.find_summary:
				if tag == "div":
					attributes = dict(attrs)
					if "class" in attributes:
						if attributes["class"] == "summary":
							self.find_summary = False
							self.find_results_per_page = True
			elif self.find_results_per_page:
				if tag == "b":
					self.find_results_per_page = False
					self.parse_results_per_page = True
			elif self.find_total_results:
				if tag == "b":
					self.find_total_results = False
					self.parse_total_results = True
			elif self.find_torrent:
				if tag == "article":
					attributes = dict(attrs)
					if "data-key" in attributes:
						self.find_torrent = False
						self.find_link = True
			elif self.find_link:
				if tag == "a":
					attributes = dict(attrs)
					if "href" in attributes:
						if attributes["href"].startswith("/hash"):
							torrent_link = attributes["href"]
							self.torrent_info["desc_link"] = f"{self.engine_url}{torrent_link}"
							magnet_id = torrent_link.split("hash/")[1].split(".html")[0]
							self.torrent_info["link"] = f"magnet:?xt=urn:btih:{magnet_id}"
							self.find_link = False
							self.find_info = True
			elif self.find_info:
				if tag == "h4":
					self.find_info = False
					self.find_extension = True
			elif self.find_extension:
				if tag == "span":
					attributes = dict(attrs)
					if "class" in attributes:
						if attributes["class"].startswith("label"):
							self.find_extension = False
							self.skip_extension = True
			elif self.find_size:
				if tag == "p":
					self.find_size = False
					self.parse_size = True

		def handle_data(self, data):
			if self.parse_results_per_page:
				results_per_page = data.split("-")[1].strip()
				self.results_per_page = int(results_per_page)
				self.parse_results_per_page = False
				self.find_total_results = True
			elif self.parse_total_results:
				total_results = "".join(c for c in data if c.isdigit())
				self.total_results = int(total_results)
				self.parse_total_results = False
				self.find_torrent = True
			elif self.parse_name:
				self.torrent_info["name"] = data.strip()
				self.parse_name = False
				self.find_size = True
			elif self.parse_size:
				try:
					size, unit = [x.strip() for x in data.split("Size：")[1].split("Created")[0].split(" ")]
				except:
					try:
						size, unit = [x.strip() for x in data.split("ファイルサイズ：")[1].split("創建時期")[0].split(" ")]
					except:
						try:
							size, unit = [x.strip() for x in data.split("文件大小：")[1].split("创建时间")[0].split(" ")]
						except:
							try:
								size, unit = [x.strip() for x in data.split("文件大小：")[1].split("創建時間")[0].split(" ")]
							except:
								size, unit = "-1", ""
				self.torrent_info["size"] = size + unit
				self.parse_size = False
				self.print_result = True

		def handle_endtag(self, tag):
			if self.print_result:
				self.print_queue.put(self.torrent_info)
				self.torrent_info = {
					"link": "",
					"name": "",
					"size": "-1",
					"seeds": "-1",
					"leech": "-1",
					"engine_url": self.engine_url,
					"desc_link": ""
				}
				self.print_result = False
				self.find_torrent = True
			elif self.skip_extension:
				self.skip_extension = False
				self.parse_name = True

	def search(self, what, cat="all"):
		parser = self.BTmuluParser(self.url)
		parser.print_worker.start()
		parser.print_queue.join()
		page_number = 1
		torrent_count = 0
		while True:
			search_url = f"{self.url}/search/page-{page_number}.html?name={what}"
			try:
				retrieved_page = retrieve_url(search_url)
				parser.feed(retrieved_page)
			except:
				break
			torrent_count += 20
			if torrent_count < parser.total_results:
				page_number += 1
				if page_number > 50:
					break
			else:
				break
		parser.close()

if __name__ == "__main__":
	engine = btmulu()
	engine.search("ubuntu", "all")
