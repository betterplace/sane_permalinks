# encoding: utf-8
require './lib/sane_permalinks'


module ActiveRecord
  class Base

    def to_param ; '23' ; end

  end

  class RecordNotFound < Exception ; end
end

describe SanePermalinks do

  before(:all) { SanePermalinks.init }

  let(:fake_class) { Class.new(ActiveRecord::Base) }

  let(:fake_model) { fake_class.new }


  describe "the default behaviour" do

    it "should implement #find_by_param to call #find_by_id"  do
      expect(fake_class).to receive(:find_by_id).with(123).and_return('hello')
      expect(fake_class.find_by_param(123)).to eq 'hello'
    end

    it "should just call the superclass to get the param" do
      expect(fake_model.to_param).to eq '23'
    end

  end

  describe "the behaviour when using a permalink field" do

    it "should implement #find_by_param to call #find_by_{field_name}" do
      fake_class.send(:make_permalink, :with => :foobar)
      expect(fake_class).to receive(:find_by_foobar).with('helloworld').and_return('hello')
      expect(fake_class.find_by_param('helloworld')).to eq 'hello'
    end

    it "should implement the #to_param method to return the field content" do
      fake_class.send(:make_permalink, :with => 'barfoo')

      expect(fake_model).to receive(:barfoo).with(no_args).and_return('hello')
      expect(fake_model.to_param).to eq 'hello'
    end

  end

  describe "the behaviour when using prepend_id" do

    it "should search by id" do
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true)

      expect(fake_class).to receive(:find_by_id).with(23).and_return('hello')
      expect(fake_class.find_by_param('23-barfoo')).to eq 'hello'
    end

    it "should generate a nice param" do
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true)

      expect(fake_model).to receive(:foobar).and_return('helloworld')

      expect(fake_model.to_param).to eq '23-helloworld'
    end

    it "should raise an error when finding by a wrong permalink, if required" do
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true, :raise_on_wrong_permalink => true)
      fake_result = fake_class.new

      expect(fake_class).to receive(:find_by_id).and_return(fake_result)
      allow(fake_result).to receive(:to_param).and_return('23-abc')

      expect { fake_class.find_by_param('23-hello') }.to raise_error(SanePermalinks::WrongPermalink) { |error| expect(error.obj).to eq fake_result }
    end

    it "should always work normally if the permalink is correct" do
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true, :raise_on_wrong_permalink => true)
      fake_result = fake_class.new

      expect(fake_class).to receive(:find_by_id).and_return(fake_result)
      expect(fake_result).to receive(:to_param).and_return('23-hello')

      expect(fake_class.find_by_param('23-hello')).to eq fake_result
    end

    it "should always work normally if the permalink is just an integer" do # Yes, that is highly weird, but it was our requirement...
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true, :raise_on_wrong_permalink => true)
      fake_result = fake_class.new

      expect(fake_class).to receive(:find_by_id).and_return(fake_result)
      expect(fake_result).to receive(:to_param).and_return('23-hello')

      expect(fake_class.find_by_param('23')).to eq fake_result
    end

    it "should still work normally if nothing is found" do
      fake_class.send(:make_permalink, :with => :foobar, :prepend_id => true, :raise_on_wrong_permalink => true)
      fake_result = fake_class.new

      expect(fake_class).to receive(:find_by_id).and_return(nil)

      expect(fake_class.find_by_param('23-hello')).to be_nil
    end

  end

  describe "find_by_param as an exclamation mark method" do

    it "should raise an exception if nothing is found" do
      expect(fake_class).to receive(:find_by_param).and_return(nil)

      expect { fake_class.find_by_param!(123) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should work normally if a record is found" do
      expect(fake_class).to receive(:find_by_param).and_return('something')
      expect(fake_class.find_by_param!(123)).to eq 'something'
    end

  end

  describe "sanitizing params" do

    it "should do the standard escaping" do
      expect(fake_model.sanitize_param("Ín der Öder pf'ügén … víé-le Hüöänér!\"!_:;§$%»")).to match(/in-der-oder-pf-ugen-vie-le-huoaner-_/)
    end

    it "should sanely handle nil values" do
      expect(fake_model.sanitize_param(nil)).to be_nil
    end

    it "should call the sanitizer during #to_param" do
      fake_class.send(:make_permalink, :with => :foobar)
      expect(fake_model).to receive(:foobar).and_return('hello_world')
      expect(fake_model).to receive(:sanitize_param).with('hello_world').and_return('foo')

      expect(fake_model.to_param).to eq 'foo'
    end

  end


end
