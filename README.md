# json_test

I've come to Gleam from Python, where you don't need to think as much about the JSON files you're parsing. 

With its strong type system and errors as values, Gleam makes it loud and clear if something doesn't look right. Though helpful, I needed a bit of extra effort to understand how to build these parsers. 

So, here is a small, slightly vague, tutorial that I put together to teach myself how to do it! Maybe it'll help someone else too.

## Purpose
In this repo, I show how to parse JSON of the form:
```json
[
    {"id": 0, "name":"Whiskers", "age":7, "biometrics": {"height": 0.2, "weight": 4.5}, "colour":"White", "fuzzy": true, "children": null},
    {"id": 1, "name": "Archimedes", "age": 12, "biometrics": {"height": 0.3, "weight": 4.0}, "colour": "Black", "fuzzy": false, "children": [0]}
]
```

Into the Gleam types:
```gleam
pub type Cat {
  Cat(
    id: Int,
    name: String,
    age: Int,
    biometrics: CatBiometrics,
    colour: Colour,
    fuzzy: Bool,
    children: Option(List(Int)),
  )
}

pub type Cats {
  Cats(cats: List(Cat))
}

pub type CatBiometrics {
  CatBiometrics(height: Float, weight: Float)
}

pub type Colour {
  Black
  White
}
```

The following are notes that assist in building these parsers.

## gleam_json
The [Gleam JSON library](https://hexdocs.pm/gleam_json/1.0.1/index.html) holds the useful `json_decode` function that takes a string and decoder and either gives you back the data you want, or some very clear `DecodeError` statements.

## Dynamic
The [Gleam Dynamic library](https://hexdocs.pm/gleam_stdlib/gleam/dynamic.html#int) is extensively used to write a JSON parser.

I found the `dynamic.decodeN` (`decode1`, `decode2`, `decode7`) most useful for constructing these decoders.

### Decoder
The type `Decoder` is a function of the following form:

```gleam
fn(Dynamic) ->  Result(a, List(DecodeError))
```

This is a function that translates a `Dynamic` into type `a`, or gives a stack trace of `DecodeError` statements.

In this example, we have:
```gleam
// The Cat decoder
fn cat_decoder() -> fn(Dynamic) -> Result(Cat, List(DecodeError)) ...

// The Cats decoder
fn cats_decoder -> fn(Dyanmic) -> Result(Cats, List(DecodeError)) ...

```

### Simple fields
A `field` is a key-value pair in the JSON data that we wish to extract. Utilising the `field` function in the Dynamic library, we can get simple values easily: 

```gleam
// Collecting an integer
field("id", int)

// Collecting a string
field("name", string)

// Collecting a float
field("height", float)

// Collecting a bool
field("fuzzy", bool)
```

It should be noted that the arguments `int`, `string`, `float`, `bool` are not the Gleam types `Int`, `String`, `Float`, `Bool`, but Decoders themselves. For example:

```gleam
fn int(data: Dynamic) -> Result(Int, List(Decode Errors)) ...
```

These can be found in the [Dynamic Hex docs](https://hexdocs.pm/gleam_stdlib/gleam/dynamic.html#int).

### Less simple fields / decoders

`field` can also parse `optional` and `list` items. As `Option` and `List` need a inner type, `optional` and `list` need an inner Decoder.
```gleam
// Collecting an optional address string, could be None
field("address", optional(string))

// Collecting a list of primes
field("primes", option(int))
```

### Conversion to Gleam types

In my code, I have the type `Colour` defined as:

```gleam
type Colour {
  Black, 
  White
}
```

To translate the JSON data:
```json
{"colour": "Black"}
```

to the desired type, I use the following: 
```gleam
// A constructor 
fn colour(colour: String) -> Colour {
  case colour {
    "Black" -> Black
    "White" -> White
    _ -> panic
  }
}

fn parse_colour(json_string: String) -> Result(Colour, List(DecodeError)) {
  let colour_decoder = dynamic.decode1(colour, string)
  json.decode(json_string, colour_decoder)
}
```

In the above we see that the `decodeN` functions take a constructor as their first argument. The remainder of the arguments are decoders. 

### Nested data
The most difficult part of parsing JSON, is building nested parsers. Gleam's Dynamic library helps us do this by allowing us to build decoders that we can put into other decoders.

To translate:
```json
{"first": 0, "second": {"third": 1}}
```
into the Gleam types:
```gleam 
type Base {
  Base(first: Int, second: Inner)
}

type Inner {
  Inner(third: Int)
}
```

we build the following: 

```gleam
fn parser(json_string: String) -> Result(Base, List(DecodeError)) {
  let inner_parser = dynamic.decode1(Inner, field("third", int))
  let base_parser = dynamic.decode2(Base, field("first", int), field("second", inner_parser))
  json.decode(json_string, base_parser)
}
```

### Errors
If we build a type and parser to transform JSON data into that type, we can run into errors.

For the type:
```gleam
type BadCat {
  BadCat(name: String, paws: 4)
}
```

and the data:
```json
{"name": "Whiskers", "paws": 4}
```

the parser:
```gleam
dynamic.decode2(BadCat, field("name", string), field("legs", int))
```

would return the error:
```gleam
Error(UnexpectedFormat([DecodeError("field", "nothing", ["legs"])]))
```

## Fin
From here, it feels a little more possible to build complex JSON parsers in Gleam for your everyday payload needs!