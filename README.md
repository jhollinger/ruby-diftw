# DiFtw

Dependency Injection For The Win! A small gem for simple, yet flexible, dependency injection in Ruby.

Some say you don't need DI in Ruby. Perhaps. Others say you don't need a DI *library* in Ruby. Probably true, but only in the pedantic sense that you don't a DI library for *any* language. But I'll take a nice, idiomatic DI library over "just pass every dependency to all your constructors!" any day. But I couldn't find one, so I wrote this.

## Basic Use

    # Create your injector
    Injector = DiFtw::Injector.new do
      # Register some dependencies
      register :foo do
        OpenStruct.new(message: "Foo")
      end
    end

    # Or register them like this
    Injector.register :bar do
      OpenStruct.new(message: "Bar")
    end

    # Or this
    Injector[:baz] = -> { OpenStruct.new(message: "Baz") }

    # Manually grab a dependency
    puts Injector[:foo].message
    => "Foo"

    # Inject some dependencies into your class
    class Widget
      include Injector.inject(:foo, :bar)
      
      def initialize(random_arg)
        # Unlike most DI, it doesn't hijack your initializer! Because Ruby!!1!
        @random_arg = random_arg
      end
    end

    # Now they're instance methods!
    widget = Widget.new
    puts widget.bar.message
    => "Bar"

## Singleton Injector

By default the injector *does not* use singletons. Observe:

    widget1, widget2 = Widget.new, Widget.new
    widget1.bar.object_id == widget2.bar.object_id
    => false

If you want to use singleton objects, initialize your injector like this:

    Injector = DiFtw::Injector.new(singleton: true)
    Injector[:bar] = -> { OpenStruct.new(message: 'Bar') }
    ...
    widget1, widget2 = Widget.new, Widget.new
    widget1.bar.object_id == widget2.bar.object_id
    => true

Accessing injected singletons **is thread safe**. However, registering them is not.

## Lazy, Nested Dependencies

    # Define your class and tell it to inject :ab into instances
    class Spline
      include Injector.inject(:ab)
    end
    
    # Init a Spline instance. Doesn't matter that :ab isn't registered; just don't call spline.ab yet.
    spline = Spline.new

    # Register :ab, which uses :a and :b. The order you register them in doesn't matter.
    Injector[:ab] = -> { Injector[:a] + Injector[:b] }
    Injector[:a] = -> { 'A' }
    Injector[:b] = -> { 'B' }

    # The :ab dependency isn't actually injected until .ab is called!
    puts spline.ab
    => 'AB'
## DI in tests

    # Presumably your injector is already initialized.
    # Simply re-register the dependencies you need for your tests.
    Injector[:foo] = -> { OpenStruct.new(message: 'Test Foo') }
