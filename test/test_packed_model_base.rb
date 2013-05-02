require 'helper'

class TestPackedModelBase < Test::Unit::TestCase
  should "create a PackedModel::Base with different columns" do
    class TestModel < PackedModel::Base
      attribute :magic, :type => :marker, :value => 20130501
      attribute :name, :type => :char, :size => 20
      attribute :count, :type => :integer
    end
    TestModel.fixed_width?.should be_true
  end
end
