module Spec
  module DSL
    module BehaviourMethods
      include BehaviourCallbacks
      attr_accessor :description

      def initialize(*args, &behaviour_block)
        init_description(*args)
        before_eval
        module_eval(&behaviour_block)
      end

      def included(mod) # :nodoc:
        if mod.is_a?(Behaviour)
          examples.each          { |e| mod.examples << e; }
          before_each_parts.each { |p| mod.before_each_parts << p }
          after_each_parts.each  { |p| mod.after_each_parts << p }
          before_all_parts.each  { |p| mod.before_all_parts << p }
          after_all_parts.each   { |p| mod.after_all_parts << p }
          included_modules.each  { |m| mod.include m }
        end
      end

      # Use this to pull in examples from shared behaviours.
      # See Spec::Runner for information about shared behaviours.
      def it_should_behave_like(behaviour_description)
        behaviour = SharedBehaviour.find_shared_behaviour(behaviour_description)
        unless behaviour
          raise RuntimeError.new("Shared Behaviour '#{behaviour_description}' can not be found")
        end
        include(behaviour)
      end

      # :call-seq:
      #   predicate_matchers[matcher_name] = method_on_object
      #   predicate_matchers[matcher_name] = [method1_on_object, method2_on_object]
      #
      # Dynamically generates a custom matcher that will match
      # a predicate on your class. RSpec provides a couple of these
      # out of the box:
      #
      #   exist (or state expectations)
      #     File.should exist("path/to/file")
      #
      #   an_instance_of (for mock argument constraints)
      #     mock.should_receive(:message).with(an_instance_of(String))
      #
      # == Examples
      #
      #   class Fish
      #     def can_swim?
      #       true
      #     end
      #   end
      #
      #   describe Fish do
      #     predicate_matchers[:swim] = :can_swim?
      #     it "should swim" do
      #       Fish.new.should swim
      #     end
      #   end
      def predicate_matchers
        @predicate_matchers ||= {:exist => :exist?, :an_instance_of => :is_a?}
      end

      # Creates an instance of Spec::DSL::ExampleRunner and adds
      # it to a collection of examples of the current behaviour.
      def it(description=:__generate_description, opts={}, &block)
        examples << create_example_runner(description, opts, &block)
      end
      alias_method :specify, :it

      def behaviour_type #:nodoc:
        description[:behaviour_type]
      end

      def described_type
        description.described_type
      end

      def examples
        @examples ||= []
      end

      def number_of_examples
        examples.length
      end

      private

      def init_description(*args)
        unless self.class == Behaviour
          args << {} unless Hash === args.last
          args.last[:behaviour_class] = self.class
        end
        self.description = BehaviourDescription.new(*args)
        if described_type.class == Module
          include described_type
        end
      end

      protected

      def before_eval
      end

      public

      def matches?(specified_examples)
        matcher ||= ExampleMatcher.new(description.to_s)

        examples.each do |example|
          return true if example.matches?(matcher, specified_examples)
        end
        return false
      end

      def create_example_runner(description, options={}, &block)
        ExampleRunner.new(description, options, &block)
      end
    end
  end
end