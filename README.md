# Switch Data Parser

## About

Designed to parse various data collected from switches and output a hash. Supported data types:

* switch config files
* switch bridge tables
* switch snmp data

## Example

```
require 'switch_data_parser'
require 'pp'

pp SwitchDataParser::Regexp::Config.parse(File.read("switch.config"))
pp SwitchDataParser::Regexp::BridgeTable.parse(File.read("bridge_table.config"))
```

## Notes

* Tested on Dell switch configs
