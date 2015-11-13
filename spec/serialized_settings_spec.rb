require 'spec_helper'

describe SerializedSettings do
  class TestModel < ActiveRecord::Base
    include SerializedSettings
    serialize_settings :settings,       :defaults => {"cat" => "banana", "sushi" => "fish"}
    serialize_settings :other_settings, :defaults => lambda {|record| {record.class.name => "people"} },
                       :reader_name => "my_settings"
  end

  subject { TestModel.new(settings: YAML::dump("cat" => "dog", "penguin" => "capybara"), other_settings: YAML::dump("cat" => "banana")) }

  describe "reader" do
    it "returns a Serializer" do
      subject.settings.should be_a(SerializedSettings::Serializer)
    end

    it "contains the values in the column" do
      subject.settings.value("cat").should == "dog"
    end

    it "works with the defaults" do
      subject.settings.value("sushi").should == "fish"
    end

    it "works with the other reader_name" do
      subject.my_settings.value("cat").should == "banana"
    end

    it "works with proc defaults" do
      subject.my_settings.value("TestModel").should == "people"
    end
  end

  describe "before_save" do
    it "writes to the attribute" do
      subject.settings.update("cat" => "pig")
      subject.run_callbacks(:save)
      subject.read_attribute(:settings).should == YAML::dump("cat" => "pig", "penguin" => "capybara")
    end
  end

  describe "finder" do
    before { subject.save! }

    it "takes a string and returns models that have that setting" do
      expect(subject.class.find_by_settings("cat")).to include(subject)
      expect(subject.class.find_by_settings("gecko")).not_to include(subject)
    end

    it "takes a hash with a value of true and returns models that have that setting" do
      expect(subject.class.find_by_settings("cat" => true)).to include(subject)
      expect(subject.class.find_by_settings("gecko" => true)).not_to include(subject)
    end

    it "takes a hash with a value of false and returns models that don't have that setting" do
      expect(subject.class.find_by_settings("cat" => false)).not_to include(subject)
      expect(subject.class.find_by_settings("gecko" => false)).to include(subject)
    end

    it "takes a hash with a key and value and returns models which match that setting" do
      expect(subject.class.find_by_settings("cat" => "dog")).to include(subject)
      expect(subject.class.find_by_settings("cat" => "ferret")).not_to include(subject)
    end

    it "takes a hash with multiple entries and returns models that match all of them" do
      expect(subject.class.find_by_settings("cat" => "dog", "penguin" => "capybara")).to include(subject)
      expect(subject.class.find_by_settings("cat" => "dog", "penguin" => "anteater")).not_to include(subject)
    end

    it "takes multiple arguments and returns models that match all of them" do
      expect(subject.class.find_by_settings("cat", "penguin" => "capybara")).to include(subject)
      expect(subject.class.find_by_settings("gecko", "penguin" => "capybara")).not_to include(subject)
    end
  end
end
