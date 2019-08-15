require 'rails_helper'

describe Date, 'between functions' do
  it 'returns valid months_between for given periods' do
		expect(Date.months_between(Date.parse("2017-06-03"), Date.parse("2017-08-01"))).to eq(1)
		expect(Date.months_between(Date.parse("2017-06-03"), Date.parse("2017-08-03"))).to eq(2)
		expect(Date.months_between(Date.parse("2017-06-03"), Date.parse("2017-08-05"))).to eq(2)
		expect(Date.months_between(Date.parse("2016-06-03"), Date.parse("2017-08-05"))).to eq(14)
		expect(Date.months_between(Date.parse("2016-06-03"), Date.parse("2017-08-01"))).to eq(13)
	end
	
	it 'returns valid years_between for given periods' do
	  expect(Date.years_between(Date.parse("2016-06-03"), Date.parse("2017-08-01"))).to eq(1)
		expect(Date.years_between(Date.parse("2016-06-03"), Date.parse("2017-06-01"))).to eq(0)
		expect(Date.years_between(Date.parse("2010-06-03"), Date.parse("2017-05-31"))).to eq(6)
		expect(Date.years_between(Date.parse("2010-06-03"), Date.parse("2017-06-03"))).to eq(7)
		expect(Date.years_between(Date.parse("2010-06-03"), Date.parse("2017-06-04"))).to eq(7)
	end
	
	it 'returns valid information on monthly returns' do
	  expect(try_monthly("2017-05-01", "2017-05-31", "2017-04-12")).to eq(true)
		expect(try_monthly("2017-05-20", "2017-05-31", "2017-04-12")).to eq(false)
		expect(try_monthly("2017-05-20", "2017-06-05", "2017-04-21")).to eq(true)
		expect(try_monthly("2017-05-20", "2017-06-05", "2017-04-12")).to eq(false)
		# self
		expect(try_monthly("2017-05-01", "2017-05-31", "2017-05-12")).to eq(true)
	end
	
	it 'returns valid information on yearly returns' do
	  expect(try_yearly("2017-05-01", "2017-05-31", "2016-05-12")).to eq(true)
		expect(try_yearly("2017-05-01", "2017-05-31", "2016-04-12")).to eq(false)
		expect(try_yearly("2016-12-20", "2017-02-05", "2015-01-21")).to eq(true)
		expect(try_yearly("2016-12-20", "2017-02-05", "2015-02-06")).to eq(false)
		expect(try_yearly("2016-12-20", "2017-02-05", "2015-10-06")).to eq(false)
		# self
		expect(try_yearly("2017-05-01", "2017-05-31", "2017-05-12")).to eq(true)
	end
	
	def try_monthly(date1, date2, date3)
	  Date.includes_monthly_on_day(Date.parse(date1), Date.parse(date2), Date.parse(date3).mday)
	end
	
	def try_yearly(date1, date2, date3)
	  Date.includes_yearly_on_day(Date.parse(date1), Date.parse(date2), Date.parse(date3).yday)
	end
end
