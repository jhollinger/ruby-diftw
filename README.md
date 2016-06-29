# DiFtw

Dependency Injection For The Win! A small gem for simple, yet flexible, dependency injection in Ruby.

Some say you don't need DI in Ruby. Perhaps. Others say you don't need a DI *library* in Ruby. True enough. But sometimes having a "thing" to use is helpful mentally. And if it's well-designed, it won't get in your way. DiFtw doesn't even hijack your `initialize` methods. That means it works with ActiveRecord models and anything else that already has an `initialize` method.

## Basic Use

    # Create your injector
    Injector = DiFtw::Injector.new do
      # Register some dependencies
      register :foo do
        OpenStruct.new(message: "Foo")
      end
    end

    # Or like this
    Injector.register :bar do
      OpenStruct.new(message: "Bar")
    end

    # Or this
    Injector[:baz] = -> { OpenStruct.new(message: "Baz") }

    # Manually grab a dependency
    puts Injector[:foo].message
    => "Foo"

    # Inject some dependencies into a class
    class Widget
      include Injector.inject(:foo, :bar)
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

## DI in tests

    # Presumably your injector is already initialized.
    # Just re-register the dependencies you need for your tests.
    Injector[:foo] = -> { OpenStruct.new(message: 'Test Foo') }
