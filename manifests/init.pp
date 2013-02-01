# Install and configure gitolite server
#
# [gl_wildrepos]
# Default: 0
# When set to 0, gitolite will not allow users to create repos with on the fly.
# New repos will have to be defined in the gitolite-admin repo's conf file.
#
# [repo_umask]
# Default: 0077
# This is the umask that gitolite will use when writing to the repos. For
# integration with gitweb, this should be 0022.
#
# [repo_base]
# Default: /var/lib/gitolite
# Filesystem location for gitolite to store the files for the git repositories.
#
# [gl_gitconfig_keys]
# Default: 'gitweb.url receive.denyNonFastforwards receive.denyDeletes'
# Keys allowed by gitolite on repos.  These can have some security implications
# so please only add keys that you intend to use and understand what they do.
# These keys are supplied with "config <key> = foo" in the gitolite-admin conf.
#
# [user]
# Default: gitolite
# The user which gitolite will use for management of the files/processes.  Most
# packages install the user "gitolite", so we default to that.
#
# [port]
# Default: 22
# The port in which gitolite will use for communications.  Everything is done
# over ssh by default.
#
# [gl_servers]
# Default: []
# An array of all the servers in the gitolite cluster.
#
# [gl_version]
# Default: '3'

# Manual steps:
# To "cluster" the gitolite servers, the server public key needs to be copied
# (found at /etc/ssh/ssh_host_key.pub) to all the participating gitolite
# servers. After the keys are copied over, you then need to run the following
# for each of the server public keys:
#
# gl-tool add-mirroring-peer <server>.pub
#
class gitolite (
    $gl_wildrepos      = 0,
    $repo_base         = '/var/lib/gitolite',
    $repo_umask        = 0077,
    $gl_gitconfig_keys = 'gitweb.url receive.denyNonFastforwards receive.denyDeletes',
    $user              = 'gitolite',
    $group             = 'gitolite',
    $port              = 22,
    $gl_user_home      = '/var/lib/gitolite',
    $gl_servers        = [],
    $gl_version        = 3
){

    case $gl_version {
        default: {
            $gl_package = 'gitolite'
        }
        2: {
            $gl_package = 'gitolite'
        }
        3: {
            $gl_package = 'gitolite3'
        }
    }

    package { $gl_package:
        ensure => present
    }

    file { $gl_user_home:
        ensure  => directory,
        path    => $gl_user_home,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => Package[$gl_package]
    }

    file { "${gl_user_home}/projects.list":
        ensure  => present,
        owner   => 'gitolite',
        group   => 'gitolite',
        mode    => '0605',
        require => File[$gl_user_home]
    }

    file { "${gl_user_home}/.gitolite.rc":
        ensure  => present,
        content => template('gitolite/gitolite.rc.erb'),
        owner   => 'gitolite',
        group   => 'gitolite',
        require => File[$gl_user_home]
    }

    file { "${gl_user_home}/.ssh/config":
        ensure  => present,
        content => template('gitolite/ssh_config.erb'),
        owner   => 'gitolite',
        group   => 'gitolite',
        mode    => '0744',
        require => File[$gl_user_home]
    }

    file { "${gl_user_home}/.gitolite":
        ensure  => directory,
        owner   => 'gitolite',
        group   => 'gitolite',
        require => File[$gl_user_home]
    }

    file { "${gl_user_home}/.gitolite/hooks":
        ensure  => directory,
        owner   => 'gitolite',
        group   => 'gitolite',
        require => File["${gl_user_home}/.gitolite"]
    }

    file { "${gl_user_home}/.gitolite/hooks/common":
        ensure  => directory,
        owner   => 'gitolite',
        group   => 'gitolite',
        require => File["${gl_user_home}/.gitolite/hooks"]
    }

    if $gl_servers != [] {

        file { "${gl_user_home}/.gitolite/hooks/common/post-receive":
            ensure  => present,
            content => template('gitolite/post-receive.erb'),
            owner   => 'gitolite',
            group   => 'gitolite',
            mode    => '0755',
            require => File["${gl_user_home}/.gitolite/hooks/common"]
        }

    }

}
