require 'spec_helper'

module RSpec
  module Mocks
    describe AnyInstance do
      let(:klass) { Class.new }

      describe "#any_instance" do 
        context "with #stub" do
          it "should not suppress an exception when a method that doesn't exist is invoked" do
            klass.any_instance.stub(:foo)
            lambda{ klass.new.bar }.should raise_error(NoMethodError)
          end
        end
        
        context "with #and_return" do
          it "stubs a method on any instance of a particular class" do
            klass.any_instance.stub(:foo).and_return(1)
            klass.new.foo.should == 1
          end

          it "returns the same object for calls on different instances" do
            return_value = Object.new
            klass.any_instance.stub(:foo).and_return(return_value)
            klass.new.foo.should be(return_value)
            klass.new.foo.should be(return_value)
          end
        end
        
        context "with a block" do
          it "stubs a method on any instance of a particular class" do
            klass.any_instance.stub(:foo) { 1 }
            klass.new.foo.should == 1
          end

          it "returns the same computed value for calls on different instances" do
            klass.any_instance.stub(:foo) { 1 + 2 }
            klass.new.foo.should == klass.new.foo
          end
        end

        it "should raise an error if the method chain is in the wrong order" do
          lambda{ klass.any_instance.with("1").stub(:foo) }.should raise_error(NoMethodError)
        end
        
        it "should restore the class to its original state after each example" do
          space = RSpec::Mocks::Space.new
          space.add(klass)
          klass.any_instance.stub(:foo).and_return(1)
          space.reset_all
          lambda{ klass.new.foo }.should raise_error(NoMethodError)
        end
      end
    end
  end
end
