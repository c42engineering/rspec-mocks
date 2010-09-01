module RSpec
  module Mocks
    module AnyInstance
      class Recorder
        attr_reader :messages
        InvocationOrder = {
          :with => [:stub],
          :and_return => [:with, :stub]
        }
        def initialize
          @messages = []
        end

        def stub(*args, &block)
          record(:stub, args, block)
        end

        def with(*args, &block)
          record(:with, args, block)
        end

        def and_return(*args, &block)
          record(:and_return, args, block)
        end

        def record(method_name, args, block)
          if method_name != :stub && !InvocationOrder[method_name].include?(last_message)
            raise(NoMethodError, "Undefined method #{method_name}")
          end
          @messages << [args.unshift(method_name), block]
          self
        end
        
        def last_message
          @messages.last.first.first
        end
        
        def playback!(target)
          @messages.inject(target) do |target, message|
            target.__send__(*message.first, &message.last)
          end
        end
      end

      def any_instance
        RSpec::Mocks::space.add(self) if RSpec::Mocks::space
        __decorate_new! unless respond_to?(:__new_without_any_instance__)
        __recorder
      end
            
      def rspec_reset
        @__recorder = nil
        response = super
        __undecorate_new! if __send__(:methods).include?(:__new_without_any_instance__)
        response
      end
      
      def reset?
        !@__recorder && super
      end

    private

      def __recorder
        @__recorder ||= AnyInstance::Recorder.new
      end
      
      def __undecorate_new!
        self.class_eval do
          class << self
            alias_method  :new, :__new_without_any_instance__
            remove_method :__new_without_any_instance__
          end
        end
      end
      
      def __decorate_new!
        self.class_eval do
          class << self
            alias_method :__new_without_any_instance__, :new

            def new(*args, &blk)
              instance = __new_without_any_instance__(*args, &blk)
              return instance if instance.is_a?(RSpec::Mocks::AnyInstance::Recorder)
              __recorder.__send__(:playback!, instance)
              instance
            end
          end
        end
      end
    end
  end
end
