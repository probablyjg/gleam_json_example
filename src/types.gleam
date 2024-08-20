// The types used to parse json data (and a function to parse them)
//
// Types:
// - Cat
// - Cats
// - CatBiometrics
// - Colour
// - BadCat
//
// Functions:
// - parse_colour

import gleam/option.{type Option}

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

pub type BadCat {
  BadCat(name: String, paws: Int)
}

pub fn colour(string: String) -> Colour {
  case string {
    "Black" -> Black
    "White" -> White
    _ -> panic
  }
}
