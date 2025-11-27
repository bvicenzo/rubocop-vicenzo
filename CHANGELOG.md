## [Unreleased]

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
