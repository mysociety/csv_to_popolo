#!/usr/bin/ruby

require 'csv_to_popolo'
require 'minitest/autorun'

describe "blank headers" do

  subject { Popolo::CSV.new('t/data/empty_headers.csv') }

  it "should warn about the empty name column" do
    subject.data[:warnings][:blank].must_equal 1
  end

  it "should parse the rest fine" do
    subject.data[:persons].first[:given_name].must_equal 'Tom'
  end

end

