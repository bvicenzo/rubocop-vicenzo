# Changelog

## [0.7.0](https://github.com/bvicenzo/rubocop-vicenzo/compare/v0.6.0...v0.7.0) (2026-08-31)


### Features

* add RSpec cops against subjects hidden in lets ([#30](https://github.com/bvicenzo/rubocop-vicenzo/issues/30)) ([9daf259](https://github.com/bvicenzo/rubocop-vicenzo/commit/9daf25972252fdfdb92a51bba9cfe70e63446d17))
* add Vicenzo/RSpec/SubjectIsMethodResult cop ([#28](https://github.com/bvicenzo/rubocop-vicenzo/issues/28)) ([b69245a](https://github.com/bvicenzo/rubocop-vicenzo/commit/b69245af973f3341bbe62bca628333c5acb909d7))

## [0.6.0](https://github.com/bvicenzo/rubocop-vicenzo/compare/v0.5.0...v0.6.0) (2026-08-19)


### Features

* add RSpec cops against mutated and derived premises ([#26](https://github.com/bvicenzo/rubocop-vicenzo/issues/26)) ([b138dd0](https://github.com/bvicenzo/rubocop-vicenzo/commit/b138dd00a76e1bcd62e95c1f2c51dca5b4232319))

## [0.5.0] - 2026-06-29

- Add RuboCop::Cop::Vicenzo::Style::JsonParseSymbolizeNames #23;

## [0.4.0] - 2026-03-28

- Add RuboCop::Cop::Vicenzo::RSpec::ConditionalInSpec #19;
- Add RuboCop::Cop::Vicenzo::RSpec::DynamicExampleGeneration #19;
- Add RuboCop::Cop::Vicenzo::RSpec::IterationInsideExample #19;

## [0.3.0] - 2025-12-17

- Add RuboCop::Cop::Vicenzo::Layout::MultilineMethodCallLineBreaks #12;
- Add RuboCop::Cop::Vicenzo::Style::MultilineMethodCallParentheses #13;
- Add `AllowedMethods` configuration to `Vicenzo/Style/MultilineMethodCallParentheses` to allow excluding specific methods (e.g., RSpec DSLs like `to` and `change`) from the rule #15;

## [0.2.0] - 2025-11-27

- Remove RuboCop::Cop::Vicenzo::RSpec::MixedExampleGroups in favor of InconsistentSiblingStructure #10;

- Add RoboCop::Cop::Vicenzo::RSpec::LeakyDefinition #9;
- Add RoboCop::Cop::Vicenzo::RSpec::InconsistentSiblingStructure #10;

- Fix NestedContextImproperStart to deal with all nested contexts #10;
- Fix NestedLetRedefinition to not point sibling lets as nested #10;
- Fix NestedSubjectRedefinition to not point sibling lets as nested #10;


## [0.1.1] - 2025-08-12

- Add Rightly enable all cops #7;
- Fix RuboCop::Cop::Vicenzo::Rails::EnumInclusionOfValidation working with array format and no options #7;

## [0.1.0] - 2025-04-02

- Initial release;
- Add RoboCop::Cop::Vicenzo::RSpec::NestedLetRedefinition #1;
- Add RoboCop::Cop::Vicenzo::RSpec::NestedSubjectRedefinition #2;
- Add RuboCop::Cop::Vicenzo::Rails::EnumInclusionOfValidation #3;
- Add RuboCop::Cop::Vicenzo::RSpec::NestedContextImproperStart #4;
- Add RuboCop::Cop::Vicenzo::RSpec::MixedExampleGroups #6;

- Change RuboCop::Cop::Vicenzo::RSpec::NestedContextImproperStart inherits from Rspec::Base #5;
