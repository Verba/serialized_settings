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
end
