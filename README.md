# Switch Data Parser

## About

Designed to parse various data collected from switches and output a hash. Supported data types:

* switch running config
* switch bridge address tables
* switch snmp data

## Example

```
require 'switch_data_parser'
require 'pp'

# write the output of 'show running-config' to a file and then run:
pp SwitchDataParser::Regexp::Config.parse(File.read("running_config.txt"))

# write the output of 'show bridge address-table' to a file and then run:
pp SwitchDataParser::Regexp::BridgeAddressTable.parse(File.read("bridge_address_table.txt"))
```

## Notes

* Tested on Dell switch configs
* You could use switch_exec to help you fetch the output of commands from a switch: https://github.com/roobert/switch_exec
