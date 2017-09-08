## Notes on the OCI Rename

The name Bare Metal Cloud Services (BMCS) has changed to Oracle Cloud Infrastructure (OCI), and this plugin will update all occurrences of the old name accordingly. Existing versions of knife-bmcs will not be affected, but no new versions of knife-bmcs will be released, so users are encouraged to move to the new knife-oci plugin to take advantage of new features and bug fixes going forward. The new plugin will be available starting 9/11/2017, and using the new plugin will require the following changes for existing users of knife-bmcs:

* All commands will be under 'knife oci' instead of 'knife bmcs'.
* The parameters '--bmcs-config-file' and '--bmcs-profile' will change to '--oci-config-file' and '--oci-profile'.
* If 'bmcs_config_file' or 'bmcs_profile' is used in your knife config file, then these should be changed to 'oci_config_file' and 'oci_profile'. However, for backwards compatibility, if the 'oci_' parameters are not found then the BMCS versions will be used.
* The default location for the the config file will move from '~/.oraclebmc/config' to '~/.oci/config'. For backwards compatibility, if '~/.oci/config' is not found then '~/.oraclebmc/config' will be used.

When the new plugin is available, it can be installed from RubyGems with:

    chef gem install knife-oci

Or:

    gem install knife-oci

