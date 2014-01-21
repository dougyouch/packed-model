require 'helper'

describe PackedModel::Base do
  context "fixed width model testing" do
    class TestFixedPackedModel < PackedModel::Base
      attribute :magic, :type => :marker, :value => 20130501
      attribute :id, :type => :integer
      attribute :name, :type => :char, :size => 20, :strip => true
      attribute :blob, :type => :char, :size => 4, :default => 'MP3'
      attribute :count, :type => :integer, :default => 1

      def self.test_packed_string
        "\0013*\305\000\000\000Ztester\000\000\000\000\000\000\000\000\000\000\000\000\000\000WAV\000\000\000\000\005"
      end

      def self.test_hash
        {:name => "tester", :id => '90', :count => 5, :blob => 'WAV'}
      end
    end

    it "should be a fixed width model" do
      TestFixedPackedModel.fixed_width?.should be_true
    end

    it "should have a bytesize of 36" do
      TestFixedPackedModel.bytesize.should == 36
    end

    it "should construct a pack string based on the order of the attributes" do
      TestFixedPackedModel.pack_string.should == "NNa20a4N"
    end

    it "should be able to get the index for a field" do
      TestFixedPackedModel.keys.should == [:magic, :id, :name, :blob, :count]
      TestFixedPackedModel.field_index(:blob).should == 3
    end

    it "should default the count to 1" do
      TestFixedPackedModel.new.tap do |m|
        m.changed?.should be_true
        m.id.should == 0
        m.name.should be_nil
        m.blob.should == "MP3"
        m.count.should == 1
      end
    end

    it "should pack the model data into a binary string" do
      TestFixedPackedModel.new(TestFixedPackedModel.test_hash).tap do |m|
        m.changed?.should be_true
        m.id.should == 90
        m.name.should == "tester"
        m.blob.should == "WAV"
        m.count.should == 5
        m.pack.should == TestFixedPackedModel.test_packed_string
        m.pack.bytesize.should == TestFixedPackedModel.bytesize
      end
    end

    it "should not be changed if initialized from a packed string" do
      TestFixedPackedModel.new(TestFixedPackedModel.test_packed_string).tap do |m|
        m.changed?.should be_false
        m.id.should == 90
        m.name.should == "tester"
        m.blob.should == "WAV\000" # expected not stripping after unpacking
        m.count.should == 5
        m.pack.should == TestFixedPackedModel.test_packed_string
        m.pack.bytesize.should == TestFixedPackedModel.bytesize
      end
    end

    it "should raise BadMarkerException marker values do not match" do
      TestFixedPackedModel.new.tap do |m|
        str = m.pack
        str[0] = 'z'

        expect {
          TestFixedPackedModel.new str
        }.to raise_exception(PackedModel::BadMarkerException)
      end
    end

    it "should not accept strings that do not have enough data to unpack" do
      expect {
        TestFixedPackedModel.new 'bad data'
      }.to raise_exception(PackedModel::InvalidDataException)
    end

    it "should be changed of a field value changes" do
      TestFixedPackedModel.new(TestFixedPackedModel.test_packed_string).tap do |m|
        m.changed?.should be_false
        m.name = "tester"
        m.changed?.should be_false
        m.name = "different"
        m.changed?.should be_true
        m.pack.should == "\0013*\305\000\000\000Zdifferent\000\000\000\000\000\000\000\000\000\000\000WAV\000\000\000\000\005"
        m.changed?.should be_true
        m.not_changed!
        m.changed?.should be_false
      end
    end

    it "should be able to_hash the model data" do
      TestFixedPackedModel.new(TestFixedPackedModel.test_hash).to_hash.should ==
        { :magic => 20130501,
          :name => 'tester',
          :id => 90,
          :blob => "WAV",
          :count => 5
        }
    end
  end

  context "custom field model testing" do
    class TestCustomPackedModel < PackedModel::Base
      attribute :magic, :type => :marker, :value => 20130501
      attribute :id, :type => :integer
      attribute :special, :type => :custom, :pack_directive => 'n', :filter => :to_i, :bytesize => 2 # 16-bit integer
      attribute :name, :type => :char, :size => 4

      def self.test_packed_string
        "\0013*\305\000\000\000Z\000Y\000\000\000\000"
      end

      def self.test_hash
        {:id => '90', :special => '89'}
      end
    end

    it "should be a fixed width model" do
      TestCustomPackedModel.fixed_width?.should be_true
    end

    it "should have a bytesize of 14" do
      TestCustomPackedModel.bytesize.should == 14
    end

    it "should properly transform values for the special field to integers" do
      TestCustomPackedModel.new(:special => '90').tap do |m|
        m.id.should == 0
        m.special.should == 90
        m.pack.bytesize.should == TestCustomPackedModel.bytesize
      end
    end

    it "should be able to pack/unpack custom fields" do
      m1 = TestCustomPackedModel.new TestCustomPackedModel.test_hash
      m1.pack.should == TestCustomPackedModel.test_packed_string
      m1.id.should == 90
      m1.special.should == 89

      m2 = TestCustomPackedModel.new TestCustomPackedModel.test_packed_string
      m2.id.should == 90
      m2.special.should == 89
    end
  end

  context "non fixed width model testing" do
    class TestNonFixedWidthPackedModel < PackedModel::Base
      attribute :magic, :type => :marker, :value => 20130502
      attribute :name, :type => :string
      attribute :count, :type => :integer
      attribute :description, :type => :string
      attribute :summary, :type => :string
      attribute :ratings, :type => :integer

      def self.test_packed_string
        "\0013*\306Mr. Foo Bar\000\000\000\000P\000Foobartastic\000\000\000\000\000"
      end

      def self.test_hash
        {:name => "Mr. Foo Bar", :count => '80', :summary => 'Foobartastic'}
      end
    end

    it "should not be a fixed width" do
      TestNonFixedWidthPackedModel.fixed_width?.should be_false
      TestNonFixedWidthPackedModel.bytesize.should be_nil
    end

    it "should be able to pack/unpack non fixed with models" do
      m1 = TestNonFixedWidthPackedModel.new TestNonFixedWidthPackedModel.test_hash
      m1.name.should == "Mr. Foo Bar"
      m1.count.should == 80
      m1.description.should be_nil
      m1.summary.should == 'Foobartastic'
      m1.ratings.should == 0
      m1.pack.should == TestNonFixedWidthPackedModel.test_packed_string
      m1.bytesize.should == 38

      m2 = TestNonFixedWidthPackedModel.new TestNonFixedWidthPackedModel.test_packed_string
      m2.name.should == "Mr. Foo Bar"
      m2.count.should == 80
      m2.description.should be_nil
      m2.summary.should == 'Foobartastic'
      m2.ratings.should == 0
      m2.bytesize.should == 38
    end
  end

  context "bit vector" do
    class TestBitVectorPackedModel < PackedModel::Base
      bit_vector :supports, [:bit1, :bit2, :bit3, :bit4, :bit5, :bit6, :bit7, :bit8,
                             :bit9, :bit10, :bit11, :bit12, :bit13, :bit14, :bit15, :bit16,
                             :bit17, :bit18, :bit19, :bit20, :bit21, :bit22, :bit23, :bit24,
                             :bit25, :bit26, :bit27, :bit28, :bit29, :bit30, :bit31, :bit32]
    end

    it "should set all flags to false" do
      m = TestBitVectorPackedModel.new
      m.supports.should == 0
      m.bit1.should be_false
      m.bit8.should be_false
      m.bit32.should be_false
    end

    it "should be able to set individual flags" do
      m = TestBitVectorPackedModel.new
      m.bit7.should be_false
      m.bit7 = true
      m.bit7.should be_true

      m = TestBitVectorPackedModel.new m.pack
      m.bit7.should be_true

      m.supports.should == (1 << 6)
    end

    it "should be able to set and unset individual flags" do
      m = TestBitVectorPackedModel.new
      m.bit1 = true
      m.bit7 = 1
      m.bit10 = 'true'
      m.bit17 = 'on'
      m.bit20 = 'yes'

      m = TestBitVectorPackedModel.new m.pack
      m.bit1.should be_true
      m.bit7.should be_true
      m.bit10.should be_true
      m.bit17.should be_true
      m.bit20.should be_true

      m.bit2.should be_false
      m.bit16.should be_false
      m.bit18.should be_false
      m.bit32.should be_false

      m.bit10 = false
      m.bit10.should be_false
      m.bit32 = true
      m.bit32.should be_true

      m = TestBitVectorPackedModel.new m.pack
      m.bit1.should be_true
      m.bit7.should be_true
      m.bit10.should be_false
      m.bit17.should be_true
      m.bit20.should be_true
      m.bit32.should be_true
    end

    it "should default all flags to true" do
      m = TestBitVectorPackedModel.new
      m.supports = 0xFFFFFFFF
      (1..32).each do |n|
        m.send("bit#{n}").should be_true
      end
    end

    it "should not break on ||= false" do
      m = TestBitVectorPackedModel.new
      m.bit1.should be_false
      m.bit1 ||= false
      m.bit1.should be_false
    end
  end
end
