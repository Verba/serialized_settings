require 'spec_helper'

describe SerializedSettings::Serializer do
  let :data do
    {"pc" => {"settings" => {"term_length" => 11}}, "cats" => "coool!"}
  end

  let :defaults do
    {"pc" => {"settings" => {"comments_text" => {"in_store_kiosk" => "Buy Me!"}, "term_length" => 85}}, "store_name" => "The Campus Store"}
  end

  subject do
    described_class.new(data, defaults)
  end

  describe "#value" do
    it "outputs the value for the selector" do
      subject.value("cats").should == "coool!"
    end

    it "doesn't output one with a similar name" do
      subject.value("pc.awesome.cats").should be_nil
    end

    it "returns nil if it can't find the selector" do
      subject.value("pc.junk.other").should be_nil
    end

    it "returns a hash (with indifferent access) if this is an intermediate node" do
      subject.value("pc")["settings"][:term_length].should == 11
      subject.value("pc")[:settings][:term_length].should == 11
    end

    it "uses defaults if available" do
      subject.value("store_name").should == "The Campus Store"
    end

    it "privileges the user's locale info" do
      subject.value("pc.settings.term_length").should == 11
    end

    it "merges default and normal intermediate nodes" do
      subject.update("pc.settings.comments_text.cats" => "black")
      settings = subject.value("pc.settings")
      settings[:term_length].should == 11
      settings[:comments_text][:in_store_kiosk].should_not be_nil
      settings[:comments_text][:cats].should == "black"
    end
  end

  describe "#update" do
    it "modifies the data in place" do
      subject.update(:pc => {:settings => {:term_length => 12}})
      subject.value("pc.settings.term_length").should == 12
    end

    it "works with string hash keys" do
      subject.update("pc" => {"settings" => {"term_length" => 12}})
      subject.value("pc.settings.term_length").should == 12
    end

    it "works with the locale style keys" do
      subject.update("cats" => "cool", "pc.cats" => 5)
      subject.value("cats").should == "cool"
      subject.value("pc.cats").should == 5
    end

    it "keeps other selectors the same" do
      subject.update(:pc => {:settings => {:awesomesauce => 12}})
      subject.value("cats").should == "coool!"
      subject.value("pc.settings.term_length").should == 11
      subject.value("store_name").should == "The Campus Store"
    end

    it "doesn't save values that are the same as the defaults" do
      subject.update("pc" => {"settings" => {"term_length" => 85}})
      subject.value("pc.settings.term_length").should == 85
      subject.value("pc.settings.term_length", false).should be_nil
    end
  end

  describe "#output" do
    it "serializes keys as YAML strings" do
      subject = described_class.new(:a => {:b => "c"})
      subject.output.should == "---\na:\n  b: c\n"
    end
  end

  describe "#output_with_defaults" do
    it "returns a serialized hash that merges defaults with overridden values" do
      defaults = described_class.new({"a" => {"b" => 5, "c" => 6}})
      subject  = described_class.new({"a" => {"b" => 4}, "d" => 7}, defaults)
      subject.output_with_defaults.should == "---\na:\n  b: 4\n  c: 6\nd: 7\n"
    end
  end
end