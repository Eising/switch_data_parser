# Switch Config Parser


## Usage

```
require 'switch_config_parser'
require 'pp'

pp SwitchConfigParser::Regexp::Config.parse(File.read("switch.config"))
pp SwitchConfigParser::Regexp::BridgeTable.parse(File.read("bridge_table.config"))
```


## Notes

Tested on Dell switch configs.
