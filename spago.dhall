{ name = "kvm-welcome-email"
, dependencies =
  [ "aff"
  , "affjax"
  , "argonaut"
  , "arrays"
  , "bifunctors"
  , "console"
  , "const"
  , "datetime"
  , "debug"
  , "effect"
  , "either"
  , "exceptions"
  , "express"
  , "foldable-traversable"
  , "foreign"
  , "foreign-object"
  , "formatters"
  , "halogen"
  , "halogen-formless"
  , "http-methods"
  , "integers"
  , "math"
  , "maybe"
  , "media-types"
  , "newtype"
  , "node-buffer"
  , "node-fs"
  , "node-process"
  , "nodemailer"
  , "now"
  , "partial"
  , "prelude"
  , "profunctor-lenses"
  , "psci-support"
  , "react-basic"
  , "react-basic-dom"
  , "react-basic-hooks"
  , "record"
  , "refs"
  , "remotedata"
  , "simple-json"
  , "spec"
  , "strings"
  , "transformers"
  , "tuples"
  , "typelevel-prelude"
  , "web-dom"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
