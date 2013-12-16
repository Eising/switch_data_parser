# Switch Config Parser

## About

Tested on Dell switch configs

## Example

```
#!/usr/bin/env ruby

require 'switch_config_parser'
require 'awesome_print'

parser = SwitchConfigParser.new(IO.readlines("switch.config"))

parser.parse_config

ap parser.get_interfaces
```
