# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).

## 2.0.0 - 2017-09-11
### Changed
- Changed the gem name from knife-bmcs to knife-oci, and changed all occurances of BMCS to OCI.

### Fixed
- List commands will now make multiple service calls to ensure that all results are retrieved, up to the given limit.

### Added
- '--purge' param for 'knife oci server delete' to optionally remove the node from the Chef Server.
- Additional info in 'knife oci server show'

## 1.2.0 - 2017-09-11
### Deprecated
- The knife-bmcs gem has been deprecated. Users should switch to knife-oci, which provides a similar set of commands under 'knife oci'. Details can be found [here](docs/rename.md).

## 1.1.0 - 2017-08-16
### Added
- List compartments command, 'knife bmcs compartment list'
- List VCNs command, 'knife bmcs vcn list'
- List subnets command, 'knife bmcs subnet list --vcn-id <VCN ID>'
- Server show command, 'knife bmcs server show --instance-id <Instance ID>'
- Server delete command, 'knife bmcs server delete --instance-id <Instance ID>'
- Region parameter for all BMCS commands, '--region'
- Wait time parameters for 'knife bmcs server create'

## 1.0.0 - 2017-06-09
### Added
- Initial Release
- Support for 'knife bmcs server create' and several list commands.
