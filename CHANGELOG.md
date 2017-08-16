# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).

## 1.1.0 - 2017-08-16
### Added
- List compartments command, 'knife bmcs compartment list'
- List VCNs command, 'knife bmcs vcn list'
- List subnets command, 'knife bmcs subnet list --vcn-id <VCN ID>'
- Server show command, 'knife bmcs server show --instance-id <Instance ID>'
- Server delete command, 'knife bmcs server delete --instance-id <Instance ID>'
- Region param for all BMCS commands, '--region'
- Wait time parameters for 'knife bmcs server create'

## 1.0.0 - 2017-06-09
### Added
- Initial Release
- Support for 'knife bmcs server create' and several list commands.
