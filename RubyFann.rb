require 'open-uri'
require 'nokogiri'
#for Nokogiri

require 'json'
#for json parsing
#gem list (if no json)
#gem install json -> Gems like PECL/PEAR for PHP

require 'httparty'
#gem install httparty

require 'mongo'
#for mongo stuff

require 'csv'
#for csv parsing

class GoogleFinanceNokogiri
	def openHtml()
		doc = Nokogiri::HTML(open("http://www.google.com/search?q=doughnuts"))
		#html page, xpath query html
		doc.xpath('//h3/a').each do |node|
  		puts node.text
		end
	end

	def extractAndStoreTickers(coll)
		#num=2000
		url = "http://www.google.com/finance?start=0&num=2000&q=%5B((exchange%20%3D%3D%20%22NYSEARCA%22)%20%7C%20(exchange%20%3D%3D%20%22NYSEAMEX%22)%20%7C%20(exchange%20%3D%3D%20%22NYSE%22)%20%7C%20(exchange%20%3D%3D%20%22NASDAQ%22))%20%26%20(market_cap%20%3E%3D%206.99)%20%26%20(market_cap%20%3C%3D%20522390000000)%20%26%20(pe_ratio%20%3E%3D%200)%20%26%20(pe_ratio%20%3C%3D%201070000)%20%26%20(dividend_yield%20%3E%3D%200)%20%26%20(dividend_yield%20%3C%3D%2066.48)%20%26%20(price_change_52week%20%3E%3D%20-99.93)%20%26%20(price_change_52week%20%3C%3D%20899)%5D&restype=company&output=json&noIL=1&"
		json = HTTParty.get(url)
		#json = JSON.parse(open(doc)) -> didnt work
		#grab url content
		#all tickers
		#JSON of all companies under all Stock Exchanges
		
		json_searchresults = json["searchresults"]
		#puts json_searchresults
		#json array, grab 'searchresults' column
		
		#foreach ticker add to mongo ticker
		json_searchresults.each { |ticker|
		 #foreach item in searchresults (ticker)
		 #puts ticker["exchange"]+":"+ticker["ticker"]
		 ##data = {"name" => ticker["exchange"] , "ticker" => ticker["ticker"], "test" => "poo"}
		 ##coll.insert(data)
		 #foreach ticker run below function
		 extractTickerHistory(ticker["ticker"],ticker["exchange"], coll)
		}
		#view all with 'db.tickers.find().toArray()'
		
			
	end

	def setupMongo()
		connection = Mongo::Connection.new("localhost", 27017)
		db = connection.db("finance")
		db = Mongo::Connection.new.db("finance")
		coll = db.collection("google")
		#db.google.remove({}) -> empty all from collection

		#fake insert...can run several times and MONGO DOESNT DUPLICATE
		#data = {"name" => "RICH" , "count" => "I AM"} 
		#id = coll.insert(data) 
		puts 'Mongo Done'
		return coll

		#db.google.cont() -> count
		#db.google.find({"ticker": "TIP"}).toArray() -> query 
		#db.google.find({"ticker": "TIP", "date":"28-Apr-11"}).toArray() -> AND query
	end

	def extractTickerHistory(ticker, exchange, coll)
		#ticker => company
		#exchange => stock exchange belongs to
		company_details = "http://www.google.com/finance?q="+exchange+"%3A"+ticker+"&client=fss&"
		historical_prices = "http://www.google.com/finance/historical?q="+exchange+":"+ticker+"&output=csv"
		#above is same as getting from:
		#http://www.google.com/finance/historical?cid=657469&startdate=Apr+26%2C+2011&enddate=Apr+24%2C+2012&num=230
		#exactly 1 year of data for that ticker

		#csv data
		company_history_csv = HTTParty.get(historical_prices)		
		#ignore first item
		csv_counter = 1;
		#parse csv data into arrays
		CSV.parse(company_history_csv) do |row|
			#puts row[0]
			#row array: 0 => date, 1=> open, 2=> high, 3=> low, 4=> close, 5=> volume
			#puts '----'
	
			if csv_counter == 1
			else 
			 #add new row to mongo, exchange-ticker-date-open-high-low-close-volumn
			 data = {"exchange" => exchange , "ticker" => ticker, "date"=> row[0], "open" => row[1], "high" => row[2], "low" => row[3], "close" => row[4], "volume" => row[5]}
                 	 coll.insert(data)	
			end
			csv_counter+=1		
		end
	end

	def internal()
		puts 'called internal'
		#called from another function with internal()
	end

end

finance = GoogleFinanceNokogiri.new()

#finance.openHtml() -> testing

mongo = finance.setupMongo()
finance.extractAndStoreTickers(mongo)

#testing csv extractor
#finance.extractTickerHistory('MMM','NYSE')


puts 'DONE'
