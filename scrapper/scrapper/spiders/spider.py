import scrapy
import json
import re
import datetime

with open("urls.json") as f:
    urls = json.load(f)


class LaCentraleSpider(scrapy.Spider):
    name = "lacentrale"

    def start_requests(self):
        for url in urls:
            yield scrapy.Request(
                url,
                callback=self.parse,
                meta={"proxy": "http://p.webshare.io:9999"},
            )

    def parse(self, response):
        for ad in response.xpath(
            "//a[@class='Vehiculecard_Vehiculecard_vehiculeCard Containers_Containers_containers Containers_Containers_borderRadius Containers_Containers_darkShadowWide']"
        ):
            url = ad.attrib["href"]
            region = ad.xpath(
                ".//div[@class='Text_Text_text Vehiculecard_Vehiculecard_city Text_Text_body2']/text()"
            ).get()

            yield response.follow(
                url,
                callback=self.parse_ad,
                meta={"region": region},
            )
        next_page_url = response.xpath(
            ".//a[@class='page active']/following-sibling::a[1]"
        ).attrib["href"]
        if next_page_url:
            yield response.follow(next_page_url, callback=self.parse)

    def parse_ad(self, response):
        model = response.xpath(
            "//div[@class='Text_Text_text SummaryInformation_title__5CYhW Text_Text_headline2']/text()"
        ).get()
        trim = response.xpath(
            "//div[@class='Text_Text_text SummaryInformation_subtitle__M7MAb Text_Text_body2']/text()"
        ).get()
        price = response.xpath(
            "//span[@class='PriceInformation_classifiedPrice__b-Jae']/text()"
        ).get()
        registered_on = response.xpath(
            "//li[@id='firstCirculationDate']/span[2]/span/text()"
        ).get()
        year = response.xpath(
            "//div[@class='SummaryInformation_information__pf4ga']/div[1]/text()[2]"
        ).get()
        km = response.xpath(
            "//div[@class='SummaryInformation_information__pf4ga']/div[2]/text()[2]"
        ).get()
        transmission = response.xpath(
            "//div[@class='SummaryInformation_information__pf4ga']/div[3]/text()[2]"
        ).get()
        engine = response.xpath(
            "//div[@class='SummaryInformation_information__pf4ga']/div[4]/text()[2]"
        ).get()
        hp = "".join(
            response.xpath("//li[@id='powerDIN']/span[2]/span[1]/text()").getall()
        )
        color = response.xpath("//li[@id='externalColor']/span[2]/span[1]/text()").get()
        efficiency = "".join(
            response.xpath("//li[@id='consumption']/span[2]/text()").getall()
        )
        co2 = "".join(response.xpath("//li[@id='co2']/span[2]//span/text()").getall())
        site_rec = response.xpath(
            "//div[@class='PriceInformation_goodDealBadge__FynOP']//div[@class='Text_Text_text Text_Text_bold Text_Text_label2']/text()"
        ).get()
        published_since = response.xpath(
            "//div[@class='Text_Text_text SummaryInformation_publishInformation__Sgz6b Text_Text_body3']/text()[2]"
        ).get()
        region = response.meta.get("region")
        seller = response.xpath(
            "//span[@class='carousel-pictures-info customer-type']//span[@class='Tag_Tag_tag Tag_Tag_extratiny Tag_Tag_image Tag_Tag_left']/text()"
        ).get()

        yield {
            "id": re.findall(r"\d+", response.url)[0],
            "url": response.url,
            "model": model,
            "trim": trim,
            "price": price,
            "seller": seller,
            "registered_in": registered_on,
            "year": year,
            "km": km,
            "transmission": transmission,
            "engine": engine,
            "hp": hp,
            "color": color,
            "efficiency": efficiency,
            "co2": co2,
            "site_rec": site_rec,
            "region": region,
            "published_since": published_since,
            "scraped_at": datetime.datetime.now(),
        }
