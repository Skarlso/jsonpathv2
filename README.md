# Travis Build
[![Build Status](https://travis-ci.org/Skarlso/jsonpathv2.svg?branch=master)](https://travis-ci.org/Skarlso/jsonpathv2)

# JsonPathV2

This is an implementation of http://goessner.net/articles/JsonPathV2/.

## What is JsonPathV2?

JsonPathV2 is a way of addressing elements within a JSON object. Similar to xpath of yore, JsonPathV2 lets you
traverse a json object and manipulate or access it.

## Usage

### Command-line

There is stand-alone usage through the binary `jsonpathv2`

    jsonpathv2 [expression] (file|string)

    If you omit the second argument, it will read stdin, assuming one valid JSON object
    per line. Expression must be a valid jsonpathv2 expression.

### Library

To use JsonPathV2 as a library simply include and get goin'!

~~~~~ {ruby}
require 'jsonpathv2'

json = <<-HERE_DOC
{"store":
  {"bicycle":
    {"price":19.95, "color":"red"},
    "book":[
      {"price":8.95, "category":"reference", "title":"Sayings of the Century", "author":"Nigel Rees"},
      {"price":12.99, "category":"fiction", "title":"Sword of Honour", "author":"Evelyn Waugh"},
      {"price":8.99, "category":"fiction", "isbn":"0-553-21311-3", "title":"Moby Dick", "author":"Herman Melville","color":"blue"},
      {"price":22.99, "category":"fiction", "isbn":"0-395-19395-8", "title":"The Lord of the Rings", "author":"Tolkien"}
    ]
  }
}
HERE_DOC
~~~~~

Now that we have a JSON object, let's get all the prices present in the object. We create an object for the path
in the following way.

~~~~~ {ruby}
path = JsonPathV2.new('$..price')
~~~~~

Now that we have a path, let's apply it to the object above.

~~~~~ {ruby}
path.on(json)
# => [19.95, 8.95, 12.99, 8.99, 22.99]
~~~~~

Or on some other object ...

~~~~~ {ruby}
path.on('{"books":[{"title":"A Tale of Two Somethings","price":18.88}]}')
# => [18.88]
~~~~~

You can also just combine this into one mega-call with the convenient `JsonPathV2.on` method.

~~~~~ {ruby}
JsonPathV2.on(json, '$..author')
# => ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "Tolkien"]
~~~~~

Of course the full JsonPathV2 syntax is supported, such as array slices

~~~~~ {ruby}
JsonPathV2.new('$..book[::2]').on(json)
# => [
#      {"price"=>8.95, "category"=>"reference", "author"=>"Nigel Rees", "title"=>"Sayings of the Century"},
#      {"price"=>8.99, "category"=>"fiction", "author"=>"Herman Melville", "title"=>"Moby Dick", "isbn"=>"0-553-21311-3"}
#    ]
~~~~~

...and evals.

~~~~~ {ruby}
JsonPathV2.new('$..price[?(@ < 10)]').on(json)
# => [8.95, 8.99]
~~~~~

There is a convenience method, `#first` that gives you the first element for a JSON object and path.

~~~~~ {ruby}
JsonPathV2.new('$..color').first(object)
# => "red"
~~~~~

As well, we can directly create an `Enumerable` at any time using `#[]`.

~~~~~ {ruby}
enum = JsonPathV2.new('$..color')[object]
# => #<JsonPathV2::Enumerable:...>
enum.first
# => "red"
enum.any?{ |c| c == 'red' }
# => true
~~~~~

You can optionally prevent eval from being called on sub-expressions by passing in :allow_eval => false to the constructor.

### Manipulation

If you'd like to do substitution in a json object, you can use `#gsub` or `#gsub!` to modify the object in place.

~~~~~ {ruby}
JsonPathV2.for('{"candy":"lollipop"}').gsub('$..candy') {|v| "big turks" }.to_hash
~~~~~

The result will be

~~~~~ {ruby}
{'candy' => 'big turks'}
~~~~~

If you'd like to remove all nil keys, you can use `#compact` and `#compact!`. To remove all keys under a certain path, use `#delete` or `#delete!`. You can even chain these methods together as follows:

~~~~~ {ruby}
json = '{"candy":"lollipop","noncandy":null,"other":"things"}'
o = JsonPathV2.for(json).
  gsub('$..candy') {|v| "big turks" }.
  compact.
  delete('$..other').
  to_hash
# => {"candy" => "big turks"}
~~~~~
