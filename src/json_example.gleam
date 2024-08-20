// A somewhat comprehensive example of writing and utilising parsers to read Json data
// into gleam types
//
// functions:
// - cat_decoder()
// - cats_decoder()
// - parse_single()
// - parse_list()
// - parse_error()
import gleam/dynamic.{
  type DecodeError, type Dynamic, DecodeError, bool, field, float, int, list,
  optional, string,
}
import gleam/json.{UnexpectedFormat}
import gleam/option.{None, Some}
import gleeunit/should
import simplifile
import types.{
  type Cat, type CatBiometrics, type Cats, BadCat, Black, Cat, CatBiometrics,
  Cats, White, colour,
}

// cat_decoder
// 
// Utilisation of dynamic library to parse fields.
// Includes nested fields for more complex JSON structures.
fn cat_decoder() -> fn(Dynamic) -> Result(Cat, List(DecodeError)) {
  dynamic.decode7(
    Cat,
    // An int example
    field("id", int),
    // A string example
    field("name", string),
    field("age", int),
    // A decoder within a decoder!
    // I.E nested JSON!
    field(
      "biometrics",
      dynamic.decode2(
        CatBiometrics,
        // A Float example
        field("height", float),
        field("weight", float),
      ),
    ),
    // A decoder within a decoder!
    // I.E string value -> Gleam type!
    field("colour", dynamic.decode1(colour, string)),
    // A bool example
    field("fuzzy", bool),
    // A optional (null) example
    field("children", optional(list(int))),
  )
}

// cats_decoder
//
// Utilisation of the original cat_decoder to parse lists of JSON.
fn cats_decoder() -> fn(Dynamic) -> Result(Cats, List(DecodeError)) {
  // A list example
  dynamic.decode1(Cats, list(cat_decoder()))
}

// parse_single
//
// Test of cat_decoder.
fn parse_single() {
  let assert Ok(contents) = simplifile.read("data/cat.json")
  contents
  |> json.decode(cat_decoder())
  |> should.equal(
    Ok(Cat(0, "Whiskers", 7, CatBiometrics(0.2, 4.5), White, True, None)),
  )
}

// parse_list
//
// Test of cats_decoder.
fn parse_list() {
  let assert Ok(contents) = simplifile.read("data/cats.json")
  contents
  |> json.decode(cats_decoder())
  |> should.equal(
    Ok(
      Cats([
        Cat(0, "Whiskers", 7, CatBiometrics(0.2, 4.5), White, True, None),
        Cat(
          1,
          "Archimedes",
          12,
          CatBiometrics(0.3, 4.0),
          Black,
          False,
          Some([0]),
        ),
      ]),
    ),
  )
}

// error_example
//
// Test of error_example.
fn parse_error() {
  let contents = "{\"name\": \"Whiskers\", \"paws\": 4}"
  let parser =
    dynamic.decode2(BadCat, field("name", string), field("legs", int))
  contents
  |> json.decode(parser)
  |> should.equal(
    Error(UnexpectedFormat([DecodeError("field", "nothing", ["legs"])])),
  )
}

pub fn main() {
  parse_single()
  parse_list()
  parse_error()
}
