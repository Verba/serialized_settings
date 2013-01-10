require 'rubygems'
require 'bundler'
require 'active_record'

Bundler.require :default, :development

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :test_models, :force => true do |t|
    t.text :settings
    t.text :other_settings
  end
end
