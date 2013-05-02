require 'helper'

describe PackedModel::List do
  class TestListPackedModel < PackedModel::Base
    attribute :magic, :type => :marker, :value => 20130501
    attribute :id, :type => :integer
    attribute :name, :type => :char, :size => 20, :strip => true

    def self.test_list_packed_string
      "\0013*\305\000\000\000\005foo\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\0013*\305\000\000\002\274bar\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\0013*\305\000\000\000\006game\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
    end

    def self.test_list_with_models
      PackedModel::List.new(TestListPackedModel).tap do |list|
        list << TestListPackedModel.new(:id => 5, :name => "foo")
        list << TestListPackedModel.new(:id => 700, :name => "bar")
        list << TestListPackedModel.new(:id => 6, :name => "game")
      end
    end
  end

  class TestInvalidListPackedModel < PackedModel::Base
    attribute :magic, :type => :marker, :value => 20130501
    attribute :id, :type => :integer
    attribute :name, :type => :string
  end

  context "initialize" do
    it "should only allow fixed width PackedModels" do
      TestListPackedModel.fixed_width?.should be_true
      PackedModel::List.new TestListPackedModel

      TestInvalidListPackedModel.fixed_width?.should be_false
      expect {
        PackedModel::List.new TestInvalidListPackedModel
      }.to raise_exception(PackedModel::InvalidPackedModelException)
    end

    it "should be able to pack a list of models" do
      list = TestListPackedModel.test_list_with_models
      list.pack.should == TestListPackedModel.test_list_packed_string
      list.size.should == 3
    end

    it "should be able to initialize a list from a packed string" do
      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list.map(&:name).should == ['foo', 'bar', 'game']
        list.size.should == 3
      end
    end

    it "should not perform any operations on the buffer unless the data is accessed" do
      PackedModel::List.new(TestListPackedModel, 'bad data').tap do |list|
        list.pack.should == 'bad data'
        expect {
          list[0].name
        }.to raise_exception(PackedModel::InvalidDataException)
      end
    end
  end

  context "pack/unpack" do
    it "should only update the buffer if the row has changed" do
      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list[1].name = 'changed'
        list[1].changed?.should be_true
        list.pack.should_not == TestListPackedModel.test_list_packed_string
      end

      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list[1].name = 'changed'
        list[1].changed?.should be_true

        # change the model state to not changed
        list[1].not_changed!
        list[1].changed?.should be_false

        # when packing the data the list skips over unchanged rows
        list.pack.should == TestListPackedModel.test_list_packed_string
      end
    end

    it "should be able to add new rows to the list" do
      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list << (item = TestListPackedModel.new(:name => "new item", :id => 500))
        list.pack.should == "#{TestListPackedModel.test_list_packed_string}#{item.pack}"
      end

      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list[list.size] = (item = TestListPackedModel.new(:name => "new item", :id => 500))
        list.pack.should == "#{TestListPackedModel.test_list_packed_string}#{item.pack}"
      end
    end
  end

  context "find_in_buffer" do
    it "should be able to find rows in the buffer" do
      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        list.find_in_buffer(700).tap do |item|
          item.should_not be_nil
          item.name.should == "bar"
        end

        list.find_in_buffer(999999).tap do |item|
          item.should be_nil
        end

        # only the row found is unpacked
        list.send(:rows).tap do |rows|
          rows[0].is_a?(String)
          rows[1].is_a?(TestListPackedModel)
          rows[2].is_a?(String)
        end

        list.find_in_buffer(700).tap do |item|
          item.should_not be_nil
          item.name.should == "bar"
        end
      end
    end
  end

  context "remove" do
    it "should be able to remove a row from the list" do
      PackedModel::List.new(TestListPackedModel, TestListPackedModel.test_list_packed_string).tap do |list|
        item1 = list[0]
        item1.name.should == "foo"
        item2 = list[2]
        item2.name.should == "game"
        list.remove 1
        list.pack.should == "#{item1.pack}#{item2.pack}"
        list.map(&:name).should == ["foo", "game"]

        PackedModel::List.new(TestListPackedModel, list.pack).tap do |list2|
          list2.map(&:name).should == ["foo", "game"]
        end
      end
    end
  end
end
