# DiFtw

Dependency Injection For The Win! A small, yet surprisingly powerful, dependency injection library for Ruby.

**NOTE** This library is pre-1.0 and under active development. It's perfectly usable, but expect breaking API or behavior changes until 1.0.

### Why DI in Ruby?

If your only concern is testing, mocks/stubs and `webmock` might be all you need. But if you're working on a large project that hooks into all kinds of enterprisey services, and those services aren't always available in dev/testing/staging, a dash of DI might be just the thing.

### Features

* Dead-simple registration API
* Lazy injection (by default)
* Inject into all instances, a single instance, a class, or a module
* Injects singletons (by default)
* Uses parent-child injectors for max flexibility
* Threadsafe, except for registration

## Dead-simple registration API

    # Create your root injector
    DI = DiFtw::Injector.new do
      # Register some dependencies in here
      register :foo do
        OpenStruct.new(message: "Foo")
      end
    end

    # Or register them out here
    DI.register :bar do
      OpenStruct.new(message: "Bar")
    end

    # Or register them with procs
    DI[:baz] = -> { OpenStruct.new(message: "Baz") }

## Lazy injection (by default)

    class Widget
      include DI.inject :foo, :bar
    end
    
    widget = Widget.new
    # foo isn't actually injected until it's first called
    puts widget.foo.message
    => "Foo"

Lazy injection is usually fine. But if it isn't, use `inject!`:

    class Widget
      include DI.inject :foo, :bar
      
      def initialize
        inject!
      end
    end
    
    # foo and bar are immediately injected
    widget = Widget.new

## Inject into all instances, a single instance, a class, or a module

    # Inject :baz into all Widget instance objects
    class Widget
      include DI.inject :baz
    end
    puts Widget.new.baz.message
    => 'Baz'
    
    # Inject :baz into one specific instance
    x = SomeClass.new
    DI.inject_instance x, :baz
    puts x.baz.message
    => 'Baz'
    
    # Inject :baz as a class method
    class SomeClass
      DI.inject_instance self, :baz
    end
    puts SomeClass.baz.message
    => 'Baz'

    # Inject :baz as a module method 
    module SomeModule
      DI.inject_instance self, :baz
    end
    puts SomeModule.baz.message
    => 'Baz'

## Injects singletons (by default)

    Widget.new.bar.object_id == Widget.new.bar.object_id
    => true

If you *don't* want your injector to return singletons (i.e. get a new copy each time you inject something), initialize your injector like this:

    DI = DiFtw::Injector.new(singleton: false)
    DI[:bar] = -> { OpenStruct.new(message: 'Bar') }
    ...
    Widget.new.bar.object_id == Widget.new.bar.object_id
    => false

Accessing injected singletons **is thread safe**. However, registering them is not.

## Parent-Child injectors

This is maybe the coolest part. TODO

## DI in tests

    # Presumably your injector is already initialized.
    # Simply re-register the dependencies you need for your tests.
    Injector[:foo] = -> { OpenStruct.new(message: 'Test Foo') }
